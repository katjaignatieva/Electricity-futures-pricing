classdef SVJ < OptimProblem
  properties   
    name                  = 'SVJ';
    calendar              = [];           % Calendar associated with the above series
    series                = [];
    futures               = [];
    warmup_t              = 0;    

    use_futures           = false;

    %%#####  INTERNAL  ############################################################
    mle                   = struct();     % A placeholder for MLE results
  
    % During the optimization, some parameter sets yield extreme variance
    % processes. For smooth optimization, set boundaries around the value of V(t).
    V_MIN                 = 0.005.^2;     % 0.5% vol
    V_MAX                 = 500.000.^2;   % 50000% vol
    V_FLAG                = false;        % Set true if the boundaries are reached for a set of parameters    
    h                     = 1/365;

    penalty               = 100;

    maxfuturesmaturity    = 1553;         % Maximum maturity in the dataset
    asianterms            = 91;           % Proxy for one quarter

    pricingcoeffs         = [];
    deterministic         = [];
  end % properties

  methods
    function self = SVJ(varargin)
      self = self@OptimProblem();
      for no = 1:2:length(varargin)
        setfield(self, varargin{no}, varargin{no+1});
      end      

      self.name = 'SVJ';

      self.addParameter('kappax',      0, [    0,   20]);

      self.addParameter('mubar',       0, [-0.05, 0.05]);

      self.addParameter('kappav',      0, [    0,   10]);
      self.addParameter('vbar',        0, [    5,   15]);
      self.addParameter('sigmav',      0, [    5,   15]);
      self.addParameter('rho',         0, [    0,    1]);
      
      self.addParameter('lambdap',     0, [    0,  100]);
      self.addParameter('lambdan',     0, [    0,  100]);

      self.addParameter('nup'  ,       0, [    0,    2]);
      self.addParameter('nun',         0, [    0,    2]);
      self.addParameter('nuv',         0, [    0,    2]);
      
      self.addParameter('kappaxQ',     0, [    0,  100]);
      self.addParameter('kappavQ',     0, [    0,  100]);

      self.addParameter('lambdanQ',    0, [    0,  100]);
      self.addParameter('lambdapQ',    0, [    0,  100]);

      self.addParameter('nupQ',        0, [    0,    2]);
      self.addParameter('nunQ',        0, [    0,    2]);
      self.addParameter('nuvQ',        0, [    0,    2]);

      self.addParameter('delta',       0, [    0,    1]);
      
      initial = self.getInitial(); 
      self.setParameterValues(initial{:});
  
      if ~isempty(self.deterministic)
        self.deterministic.uT = getDeterministicSpot(self.deterministic.coeffs,[self.calendar;self.calendar(end)+(1:(self.maxfuturesmaturity+self.asianterms))']);
      end

      if self.use_futures
        self.updateFuturesPricingCoefficients();
      end
    end % SVJ

    function initial = getInitial(self)
      initial = {
        'kappax',     18.611746986319275, ...
        'mubar',       0.009969920509053, ...
        'kappav',      5.070792017264787, ...
        'vbar',        8.952574996889936, ...
        'sigmav',     10.745621510573571, ...
        'rho',         0.523002906160761, ...
        'lambdan',    10.288956414385735, ...
        'lambdap',    10.344269148793613, ...
        'nup',         0.803248986994442, ...
        'nun',         0.902935505367317, ...
        'nuv',         1.118256136575484, ...
        'kappaxQ',    45.216806103047674, ...
        'kappavQ',     0.470760934318975, ...
        'lambdanQ',   12.178661084084315, ...
        'lambdapQ',    1.927466378156532, ...
        'nupQ',        0.712176718723576, ...
        'nunQ',        0.784735880571541, ...
        'nuvQ',        0.236275770419535, ...
        'delta',       0.282047757134220, ...
        };
    end % initial

    function pv = getPV(self)
      pv                = getPV@OptimProblem(self);

      % Get RND parameters
      pv.chix           = pv.kappax - pv.kappaxQ;
      pv.chiv           = (pv.kappav - pv.kappavQ)./pv.sigmav;
      pv.mubarQ         = pv.kappax*pv.mubar/pv.kappaxQ;
      pv.vbarQ          = pv.kappav*pv.vbar/pv.kappavQ;

      pv.hp             = pv.lambdapQ./pv.lambdap;
      pv.hn             = pv.lambdanQ./pv.lambdan;
    end % getPV

    function loglike = logLikelihood(self, pvalues, filter)
      self.setPValues(pvalues);

      % Update pricing coefficients based on new parameters
      if self.use_futures
        self.updateFuturesPricingCoefficients();
      end
      
      % Run the filter to get estimate of likelihood
      [loglike] = filter.logLikelihood();

      if self.warmup_t == 0
        loglike = sum( loglike );
      else
        loglike = sum( loglike(self.warmup_t+1:end) );
      end
    end % logLikelihood   

    function loglike = logLikelihoodFull(self, pvalues, filter)
      self.setPValues(pvalues);

      % Update pricing coefficients based on new parameters
      if self.use_options
        self.updateOptionPricingCoefficients();
        self.updateFuturesPricingCoefficients();
      end
      if self.use_futures
        self.updateFuturesPricingCoefficients();
      end
      
      % Run the filter to get estimate of likelihood
      [loglike] = filter.logLikelihood();

      if ~self.warmup_t == 0
        loglike = loglike(self.warmup_t+1:end);
      end
    end % logLikelihoodFull

    function stderr = getStdError(self,filter)
      % This function computes the standard errors using the gradient
      % method coupled with returns and option data.
      T = length(self.series) - self.warmup_t;
      pv = self.getPV();

      function LL = loglike(pvalues,filter)
        LL = self.logLikelihoodFull(pvalues,filter);
      end
      
      FI = NumJacobian(@(x) -loglike(x,filter), self.getPValues, 0.00005);
      FI = nancov(FI);
      
      if ~isnan(nanmean(mean(FI)))
        stderr_tmp = real(sqrt(diag(pinv(FI))')./sqrt( T ));
      else
        stderr_tmp = NaN(size(diag(FI)))';
      end
      params = self.params;
      pnames = fieldnames(params);
      n_values = length(stderr_tmp);
      free = 0;
      for pn = 1:length(pnames)
        field = pnames{pn};
        if ~params.(field).fixed
          free = free+1;
          stderr.(field) = stderr_tmp(free);
          self.params.(field).value = pv.(field);
        end
      end
      assert(n_values == free, sprintf( ...
        'Length of pvalues (%d) is not equal to the number of free parameters (%d)', n_values, free));
      self.mle.stderr = stderr;
    end % getStdErr

    function [nll,info] = objective(self, x, varargin) 
      [likelihood] = self.logLikelihood(x, varargin{:});
      likelihood(isinf(likelihood)) = 0;
      nll = -sum(likelihood);
      info.loglikelihood = -nll;
    end % objective
    
    function [warmup_t] = setWarmupDate(self, date)
      % Set warmup_t to a date in the calendar; the likelihood of innovations
      % before or at this date will be ignored
      warmup_t = find(self.calendar <= date, 1, 'last');
      self.warmup_t = warmup_t;
    end % setWarmupDate

    function x = getCGFpJumps(self,u1,u3,pv)
      x = (1./(1-u1.*pv.nup)).*(1./(1-u3.*pv.nuv));
    end % getCGFpJumps

    function x = getCGFnJumps(self,u2,pv)
      x = (1./(1+u2.*pv.nun));
    end % getCGFnJumps
    
    function x = getCGFpJumpsQ(self,u1,u3,pv)
      x = (1./(1-u1.*pv.nupQ)).*(1./(1-u3.*pv.nuvQ));
    end % getCGFpJumps

    function x = getCGFnJumpsQ(self,u2,pv)
      x = (1./(1+u2.*pv.nunQ));
    end % getCGFnJumps

    function [x, v, Np, Nn, Zp, Zn, Zv] = simulatePathsP(self, n_days, n_paths, x0, v0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      v                 = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      v(1,:)            = v0;
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdap.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nup);
      Zv                = gamrnd(Np,pv.nuv);

      Nn                = poissrnd(pv.lambdan.*self.h,n_days,n_paths);
      Zn                = -gamrnd(Nn,pv.nun);
      
      for dt = 1:n_days
        Vm1             = boxed(v(dt,:) + pv.kappav.*(pv.vbar - v(dt,:)).*self.h + pv.sigmav.*sqrt(v(dt,:).*self.h).*Wv(dt,:), self.V_MIN, self.V_MAX);
        v(dt+1,:)       = boxed(Vm1 + Zv(dt,:), self.V_MIN, self.V_MAX);
        x(dt+1,:)       = x(dt,:) + pv.kappax.*(pv.mubar - x(dt,:)).*self.h + sqrt(v(dt,:).*self.h).*Wx(dt,:) + Zp(dt,:) + Zn(dt,:);
      end
    end % simulatePathsP

    function [x, v, Np, Nn, Zp, Zn, Zv] = simulatePathsQ(self, n_days, n_paths, x0, v0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      v                 = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      v(1,:)            = v0;
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdapQ.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nupQ);
      Zv                = gamrnd(Np,pv.nuvQ);

      Nn                = poissrnd(pv.lambdanQ.*self.h,n_days,n_paths);
      Zn                = -gamrnd(Nn,pv.nunQ);
      
      for dt = 1:n_days
        Vm1             = boxed(v(dt,:) + pv.kappavQ.*(pv.vbarQ - v(dt,:)).*self.h + pv.sigmav.*sqrt(v(dt,:).*self.h).*Wv(dt,:), self.V_MIN, self.V_MAX);
        v(dt+1,:)       = boxed(Vm1 + Zv(dt,:), self.V_MIN, self.V_MAX);
        x(dt+1,:)       = x(dt,:) + pv.kappaxQ.*(pv.mubarQ - x(dt,:)).*self.h + sqrt(v(dt,:).*self.h).*Wx(dt,:) + Zp(dt,:) + Zn(dt,:);
      end
    end % simulatePathsQ

    function yp = getODEs(self,t,y,u,pv)
      Btmp    =   + exp(-pv.kappaxQ.*t).*u;

      yp(1,1) =   + pv.kappaxQ.*pv.mubarQ.*Btmp ... 
                  + pv.kappavQ.*pv.vbarQ.*y(2) ...
                  + pv.lambdapQ.*(self.getCGFpJumpsQ(Btmp,y(2),pv) - 1) ...
                  + pv.lambdanQ.*(self.getCGFnJumpsQ(Btmp,pv) - 1);
      yp(2,1) =   + 0.5.*Btmp.^2 - (pv.kappavQ - pv.sigmav.*pv.rho.*Btmp).*y(2) + 0.5.*pv.sigmav.^2.*y(2).^2;
    end % getOptionODEs

    function [A,B,C] = getmgfQgen(self, u, n_days, pv)
    % This function computes the matrices of coefficients A, B, C, D and E
      h = self.h;

      At = zeros(length(u),n_days);
      Bt = zeros(length(u),n_days);
      Ct = zeros(length(u),n_days);

      for dv = 1:length(u)
        [t,y]    = ode45(@(t,y) self.getODEs(t,y,u(dv),pv), [0,n_days*h], [0;0]);
        At(dv,:) = interp1(t,y(:,1),h:h:(n_days*h));
        Bt(dv,:) = exp(-pv.kappaxQ.*(h:h:(n_days*h))).*u(dv);
        Ct(dv,:) = interp1(t,y(:,2),h:h:(n_days*h));
      end

      A = complex(At);
      B = complex(Bt);
      C = complex(Ct);
    end % end getmgfQgen

    function [A,B,C] = updateFuturesPricingCoefficients(self)
      pv = self.getPV;
      [A,B,C] = self.getmgfQgen(1, self.maxfuturesmaturity, pv);

      self.pricingcoeffs.Af = A;
      self.pricingcoeffs.Bf = B;
      self.pricingcoeffs.Cf = C;
    end % updateFuturesPricingCoefficients

    function DailyFuturesPrices = getDailyFuturesPrices(self,futuresData,vs)
      pv = self.getPV;

      N         = height(futuresData); 
      if N == 0
        DailyFuturesPrices = zeros(0,0);
        return;
      end

      curdate   = find(self.calendar == futuresData.Date(1));
      x0s       = self.series(curdate);

      v0s       = vs(:)';

      for di = 1:N
        Ts      = futuresData.DTM(di);
        uTs     = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx     = (1 + max(0,Ts - self.asianterms)):Ts;
        DailyFuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*v0s(:) ),2))./self.asianterms;
      end
    end % getDailyFuturesPrices

    function FuturesPrices = getFuturesPrices(self,futuresData,vs)
      pv = self.getPV;

      N         = height(futuresData); 
      if N == 0
        FuturesPrices = zeros(0,0);
        return;
      end

      for di = 1:N
        curdate     = find(self.calendar == futuresData.Date(di));
        x0s         = self.series(curdate);
        v0s         = vs(curdate);

        Ts          = futuresData.DTM(di);
        uTs         = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx         = (1 + max(0,Ts - self.asianterms)):Ts;
        FuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*v0s(:))))./self.asianterms;
      end
    end % getFuturesPrices

  end % methods

end % classdef SVJ < OptimProblem
