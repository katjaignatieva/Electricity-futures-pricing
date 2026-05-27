classdef SVJDI < OptimProblem
  properties   
    name                  = 'SVJDI';
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
    function self = SVJDI(varargin)
      self = self@OptimProblem();
      for no = 1:2:length(varargin)
        setfield(self, varargin{no}, varargin{no+1});
      end      

      self.name = 'SVJDI';

      self.addParameter('kappax',      0, [    0,   20]);

      self.addParameter('mubar',       0, [-0.05, 0.05]);

      self.addParameter('kappav',      0, [    0,   10]);
      self.addParameter('vbar',        0, [    5,   15]);
      self.addParameter('sigmav',      0, [    5,   15]);
      self.addParameter('rho',         0, [    0,    1]);
      
      self.addParameter('kappalambda', 0, [    0,    5]);
      self.addParameter('lambdanbar',  0, [ 0.01,   20]);
      self.addParameter('lambdap',     0, [    0,   20]);

      self.addParameter('nup'  ,       0, [    0,    2]);
      self.addParameter('nun',         0, [    0,    2]);
      self.addParameter('nuv',         0, [    0,    2]);
      self.addParameter('nulambda',    0, [    0,    2]);
      
      self.addParameter('kappaxQ',     0, [    0,  100]);
      self.addParameter('kappavQ',     0, [    0,   20]);

      self.addParameter('lambdanbarQ', 0, [ 0.01,  100]);
      self.addParameter('lambdapQ',    0, [    0,  100]);

      self.addParameter('nupQ',        0, [    0,    2]);
      self.addParameter('nunQ',        0, [    0,    2]);
      self.addParameter('nuvQ',        0, [    0,    2]);
      self.addParameter('nulambdaQ',   0, [    0,    2]);

      self.addParameter('delta',      0, [    0,     1]);
      
      initial = self.getInitial(); 
      self.setParameterValues(initial{:});
  
      if ~isempty(self.deterministic)
        self.deterministic.uT = getDeterministicSpot(self.deterministic.coeffs,[self.calendar;self.calendar(end)+(1:(self.maxfuturesmaturity+self.asianterms))']);
      end
      
      if self.use_futures
        self.updateFuturesPricingCoefficients();
      end
    end % SVJDI

    function initial = getInitial(self)
      initial = {
        'kappax',     16.760748167182783, ...
        'mubar',       0.012182710352534, ...
        'kappav',      4.931262726567625, ...
        'vbar',       10.054703266006026, ...
        'sigmav',      9.816101010957155, ...
        'rho',         0.496415269173737, ...
        'kappalambda', 0.872198313857633, ...
        'lambdanbar', 10.084433611510674, ...
        'lambdap',     9.977288423263955, ...
        'nup',         0.966026570372127, ...
        'nun',         0.605254798862850, ...
        'nuv',         0.394823084942472, ...
        'nulambda',    0.438154492348057, ...
        'kappaxQ',    51.027411855609870, ...
        'kappavQ',     0.308959678495797, ...
        'lambdanbarQ',92.754355302267925, ...
        'lambdapQ',    6.921285201696600, ...
        'nupQ',        0.483306651650038, ...
        'nunQ',        0.320024227116294, ...
        'nuvQ',        0.316800080120716, ...
        'nulambdaQ',   0.298071770602987, ...
        'delta',       0.264369306489212, ...
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
      pv.hn             = pv.lambdanbarQ./pv.lambdanbar;
    end % getPV

    function loglike = logLikelihood(self, pvalues, filter)
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
      
      FI = NumJacobian(@(x) -loglike(x,filter), self.getPValues, 0.0005);
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

    function x = getCGFpJumps(self,u1,u3,u4,pv)
      x = (1./(1-u1.*pv.nup)).*(1./(1-u3.*pv.nuv)).*(1./(1-u4.*pv.nulambda));
    end % getCGFpJumps

    function x = getCGFnJumps(self,u2,pv)
      x = (1./(1+u2.*pv.nun));
    end % getCGFnJumps
    
    function x = getCGFpJumpsQ(self,u1,u3,u4,pv)
      x = (1./(1-u1.*pv.nupQ)).*(1./(1-u3.*pv.nuvQ)).*(1./(1-u4.*pv.nulambdaQ));
    end % getCGFpJumps

    function x = getCGFnJumpsQ(self,u2,pv)
      x = (1./(1+u2.*pv.nunQ));
    end % getCGFnJumps

    function [x, v, lambdan, Np, Nn, Zp, Zn, Zv, Zlambda] = simulatePathsP(self, n_days, n_paths, x0, v0, lambdan0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      v                 = NaN(n_days+1,n_paths);
      lambdan           = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      v(1,:)            = v0;
      lambdan(1,:)      = lambdan0;
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdap.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nup);
      Zv                = gamrnd(Np,pv.nuv);
      Zlambda           = gamrnd(Np,pv.nulambda);
        
      for dt = 1:n_days
        lambdan(dt+1,:) = lambdan(dt) + pv.kappalambda.*(pv.lambdanbar - lambdan(dt,:)).*self.h + Zlambda(dt,:);
      end

      Nn                = poissrnd(lambdan(1:end-1,:));
      Zn                = -gamrnd(Nn,pv.nun);
      
      for dt = 1:n_days
        Vm1             = boxed(v(dt,:) + pv.kappav.*(pv.vbar - v(dt,:)).*self.h + pv.sigmav.*sqrt(v(dt,:).*self.h).*Wv(dt,:), self.V_MIN, self.V_MAX);
        v(dt+1,:)       = boxed(Vm1 + Zv(dt,:), self.V_MIN, self.V_MAX);
        x(dt+1,:)       = x(dt,:) + pv.kappax.*(pv.mubar - x(dt,:)).*self.h + sqrt(v(dt,:).*self.h).*Wx(dt,:) + Zp(dt,:) + Zn(dt,:);
      end
    end % simulatePathsP
    

    function [x, v, lambdan, Np, Nn, Zp, Zn, Zv, Zlambda] = simulatePathsQ(self, n_days, n_paths, x0, v0, lambdan0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      v                 = NaN(n_days+1,n_paths);
      lambdan           = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      v(1,:)            = v0;
      lambdan(1,:)      = lambdan0.*self.getCGFnJumps(pv.Gamman,pv);
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdapQ.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nupQ);
      Zv                = gamrnd(Np,pv.nuvQ);
      Zlambda           = gamrnd(Np,pv.nulambdaQ);
        
      for dt = 1:n_days
        lambdan(dt+1,:) = lambdan(dt) + pv.kappalambda.*(pv.lambdanbarQ - lambdan(dt,:)).*self.h + Zlambda(dt,:);
      end

      Nn                = poissrnd(lambdan(1:end-1,:));
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
                  + pv.kappalambda.*pv.lambdanbarQ.*y(3) ...
                  + pv.lambdapQ.*(self.getCGFpJumpsQ(Btmp,y(2),y(3),pv) - 1);
      yp(2,1) =   + 0.5.*Btmp.^2 - (pv.kappavQ - pv.sigmav.*pv.rho.*Btmp).*y(2) + 0.5.*pv.sigmav.^2.*y(2).^2;
      yp(3,1) =   - pv.kappalambda.*y(3) + (self.getCGFnJumpsQ(Btmp,pv) - 1);
    end % getOptionODEs

    function [A,B,C,D] = getmgfQgen(self, u, n_days, pv)
    % This function computes the matrices of coefficients A, B, C, D and E
      h = self.h;

      At = zeros(length(u),n_days);
      Bt = zeros(length(u),n_days);
      Ct = zeros(length(u),n_days);
      Dt = zeros(length(u),n_days);

      for dv = 1:length(u)
        [t,y]    = ode45(@(t,y) self.getODEs(t,y,u(dv),pv), [0,n_days*h], [0;0;0]);
        At(dv,:) = interp1(t,y(:,1),h:h:(n_days*h));
        Bt(dv,:) = exp(-pv.kappaxQ.*(h:h:(n_days*h))).*u(dv);
        Ct(dv,:) = interp1(t,y(:,2),h:h:(n_days*h));
        Dt(dv,:) = interp1(t,y(:,3),h:h:(n_days*h));
      end

      A = complex(At);
      B = complex(Bt);
      C = complex(Ct);
      D = complex(Dt);
    end % end getmgfQgen

    function [A,B,C,D] = updateFuturesPricingCoefficients(self)
      pv = self.getPV;
      [A,B,C,D] = self.getmgfQgen(1, self.maxfuturesmaturity, pv);

      self.pricingcoeffs.Af = A;
      self.pricingcoeffs.Bf = B;
      self.pricingcoeffs.Cf = C;
      self.pricingcoeffs.Df = D;
    end % updateFuturesPricingCoefficients

    function DailyFuturesPrices = getDailyFuturesPrices(self,futuresData,vs,lambdas)
      pv = self.getPV;

      N         = height(futuresData); 
      if N == 0
        DailyFuturesPrices = zeros(0,0);
        return;
      end

      curdate   = find(self.calendar == futuresData.Date(1));
      x0s       = self.series(curdate);

      v0s       = vs(:)';
      lambda0s  = lambdas(:)'.*pv.hn;

      for di = 1:N
        Ts      = futuresData.DTM(di);
        uTs     = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx     = (1 + max(0,Ts - self.asianterms)):Ts;
        DailyFuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*v0s(:)  + self.pricingcoeffs.Df(idx).*lambda0s(:)),2))./self.asianterms;
      end
    end % getDailyFuturesPrices

    function FuturesPrices = getFuturesPrices(self,futuresData,vs,lambdas)
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
        lambda0s    = lambdas(curdate).*pv.hn;

        Ts          = futuresData.DTM(di);
        uTs         = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx         = (1 + max(0,Ts - self.asianterms)):Ts;
        FuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*v0s(:)  + self.pricingcoeffs.Df(idx).*lambda0s(:))))./self.asianterms;
      end
    end % getFuturesPrices


  end % methods

end % classdef SVJDI < OptimProblem
