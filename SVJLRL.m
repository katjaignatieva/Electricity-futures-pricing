classdef SVJLRL < OptimProblem
  properties   
    name                  = 'SVJLRL';
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
    function self = SVJLRL(varargin)
      self = self@OptimProblem();
      for no = 1:2:length(varargin)
        setfield(self, varargin{no}, varargin{no+1});
      end      

      self.name = 'SVJLRL';

      self.addParameter('kappax',      0, [    0,   20]);

      self.addParameter('kappamu',     0, [    0,   10]);
      self.addParameter('mubar',       0, [-0.05, 0.05]);
      self.addParameter('sigmamu',     0, [    0,   10]);

      self.addParameter('kappav',      0, [    0,   10]);
      self.addParameter('vbar',        0, [    5,   15]);
      self.addParameter('sigmav',      0, [    5,   15]);
      self.addParameter('rho',         0, [    0,    1]);
      
      self.addParameter('lambdan',     0, [    0,  100]);
      self.addParameter('lambdap',     0, [    0,  100]);

      self.addParameter('nup'  ,       0, [    0,    2]);
      self.addParameter('nun',         0, [    0,    2]);
      self.addParameter('nuv',         0, [    0,    2]);
      
      self.addParameter('kappaxQ',     0, [    0,  100]);
      self.addParameter('kappamuQ',    0, [    0,  100]);
      self.addParameter('kappavQ',     0, [    0,  100]);
      
      self.addParameter('lambdanQ',    0, [    0,   20]);
      self.addParameter('lambdapQ',    0, [    0,   20]);

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
    end % SVJLRL

    function initial = getInitial(self)
      initial = {
        'kappax',     18.102536349729494, ...
        'kappamu',     0.288184924478415, ...
        'mubar',       0.018604870418679, ...
        'sigmamu',     0.365266645516217, ...
        'kappav',      5.736940791164032, ...
        'vbar',        8.870326234853797, ...
        'sigmav',      9.871076818935485, ...
        'rho',         0.667366058085574, ...
        'lambdan',    16.368400348834829, ...
        'lambdap',    10.820010053136730, ...
        'nup',         1.345861073601297, ...
        'nun',         0.659090450503096, ...
        'nuv',         0.564215731919059, ...
        'kappaxQ',    72.365941341789153, ...
        'kappamuQ',    0.287151873774954, ...
        'kappavQ',     4.422340958877969, ...
        'lambdanQ',   29.109599494581950, ...
        'lambdapQ',    3.500485553680956, ...
        'nupQ',        0.542883465770911, ...
        'nunQ',        0.458434717333219, ...
        'nuvQ',        0.452521725105624, ...
        'delta',       0.147556750427232, ...
        };
    end % initial

    function pv = getPV(self)
      pv                = getPV@OptimProblem(self);

      % Get RND parameters
      pv.chix           = pv.kappax - pv.kappaxQ;
      pv.chimu          = (pv.kappamu - pv.kappamuQ)./pv.sigmamu;
      pv.chiv           = (pv.kappav - pv.kappavQ)./pv.sigmav;
      pv.mubarQ         = pv.kappamu*pv.mubar/pv.kappamuQ;
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

    function [x, mu, v, Np, Nn, Zp, Zn, Zv] = simulatePathsP(self, n_days, n_paths, x0, mu0, v0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      mu                = NaN(n_days,  n_paths);
      v                 = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      mu(1,:)           = mu0;
      v(1,:)            = v0;
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wmu               = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdap.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nup);
      Zv                = gamrnd(Np,pv.nuv);

      Nn                = poissrnd(pv.lambdan.*self.h,n_days,n_paths);
      Zn                = -gamrnd(Nn,pv.nun);
      
      for dt = 1:n_days
        Vm1             = boxed(v(dt,:) + pv.kappav.*(pv.vbar - v(dt,:)).*self.h + pv.sigmav.*sqrt(v(dt,:).*self.h).*Wv(dt,:), self.V_MIN, self.V_MAX);
        v(dt+1,:)       = boxed(Vm1 + Zv(dt,:), self.V_MIN, self.V_MAX);
        mu(dt+1,:)      = mu(dt,:) + pv.kappamu.*(pv.mubar - mu(dt,:)).*self.h + pv.sigmamu.*sqrt(self.h).*Wmu(dt,:);
        x(dt+1,:)       = x(dt,:) + pv.kappax.*(mu(dt,:) - x(dt,:)).*self.h + sqrt(v(dt,:).*self.h).*Wx(dt,:) + Zp(dt,:) + Zn(dt,:);
      end
    end % simulatePathsP
    
    function [x, v, Np, Nn, Zp, Zn, Zv] = simulatePathsQ(self, n_days, n_paths, x0, mu0, v0)
      % This function generates matrices of size n_days x n_paths that contain
      % simulated values of returns, diffusive component, jump component,
      % fundamental variance, conditional variance and jump intensity
      % respectively.
      
      % Shorthand
      pv                = self.getPV();
  
      % Initialization
      x                 = NaN(n_days,  n_paths);
      mu                = NaN(n_days+1,n_paths);
      v                 = NaN(n_days+1,n_paths);
      
      x(1,:)            = x0;
      mu(1,:)           = mu0;
      v(1,:)            = v0;
      
      % Random components
      Wv                = normrnd(0,1,n_days,n_paths);
      Wperp             = normrnd(0,1,n_days,n_paths);
      Wmu               = normrnd(0,1,n_days,n_paths);
      Wx                = pv.rho.*Wv + sqrt(1-pv.rho^2).*Wperp;

      Np                = poissrnd(pv.lambdapQ.*self.h,n_days,n_paths);
      Zp                = gamrnd(Np,pv.nupQ);
      Zv                = gamrnd(Np,pv.nuvQ);
       
      Nn                = poissrnd(pv.lambdanQ.*self.h,n_days,n_paths);
      Zn                = -gamrnd(Nn,pv.nunQ);
      
      for dt = 1:n_days
        Vm1             = boxed(v(dt,:) + pv.kappavQ.*(pv.vbarQ - v(dt,:)).*self.h + pv.sigmav.*sqrt(v(dt,:).*self.h).*Wv(dt,:), self.V_MIN, self.V_MAX);
        v(dt+1,:)       = boxed(Vm1 + Zv(dt,:), self.V_MIN, self.V_MAX);
        mu(dt+1,:)      = mu(dt,:) + pv.kappamuQ.*(pv.mubarQ - mu(dt,:)).*self.h + pv.sigmamu.*sqrt(self.h).*Wmu(dt,:);
        x(dt+1,:)       = x(dt,:) + pv.kappaxQ.*(mu(dt,:) - x(dt,:)).*self.h + sqrt(v(dt,:).*self.h).*Wx(dt,:) + Zp(dt,:) + Zn(dt,:);
      end
    end % simulatePathsQ

    function yp = getODEs(self,t,y,u,pv)
      Btmp    =   + exp(-pv.kappaxQ.*t).*u;
      Ctmp    =   + (pv.kappaxQ./(pv.kappamuQ - pv.kappaxQ)).*u.*(exp(-pv.kappaxQ.*t) - exp(-pv.kappamuQ.*t)); % This works as long as xiQ \neq etaQ

      yp(1,1) =   + pv.kappamuQ.*pv.mubarQ.*Ctmp ...
                  + pv.kappavQ.*pv.vbarQ.*y(2) ...
                  + pv.sigmamu.^2.*Ctmp.^2./2 ...
                  + pv.lambdapQ.*(self.getCGFpJumpsQ(Btmp,y(2),pv) - 1) ...
                  + pv.lambdanQ.*(self.getCGFnJumpsQ(Btmp,pv) - 1);
      yp(2,1) =   + 0.5.*Btmp.^2 - (pv.kappavQ - pv.sigmav.*pv.rho.*Btmp).*y(2) + 0.5.*pv.sigmav.^2.*y(2).^2;
    end % getOptionODEs

    function [A,B,C,D] = getmgfQgen(self, u, n_days, pv)
    % This function computes the matrices of coefficients A, B, C, D and E
      h = self.h;

      At = zeros(length(u),n_days);
      Bt = zeros(length(u),n_days);
      Ct = zeros(length(u),n_days);
      Dt = zeros(length(u),n_days);

      for dv = 1:length(u)
        [t,y]    = ode45(@(t,y) self.getODEs(t,y,u(dv),pv), [0,n_days*h], [0;0]);
        At(dv,:) = interp1(t,y(:,1),h:h:(n_days*h));
        Bt(dv,:) = exp(-pv.kappaxQ.*(h:h:(n_days*h))).*u(dv);
        Ct(dv,:) = (pv.kappaxQ./(pv.kappamuQ - pv.kappaxQ)).*u(dv).*(exp(-pv.kappaxQ.*(h:h:(n_days*h))) - exp(-pv.kappamuQ.*(h:h:(n_days*h)))); 
        Dt(dv,:) = interp1(t,y(:,2),h:h:(n_days*h));
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

    function DailyFuturesPrices = getDailyFuturesPrices(self,futuresData,mus,vs)
      pv = self.getPV;

      N         = height(futuresData); 
      if N == 0
        DailyFuturesPrices = zeros(0,0);
        return;
      end

      curdate   = find(self.calendar == futuresData.Date(1));
      x0s       = self.series(curdate);

      mu0s      = mus(:)';
      v0s       = vs(:)';

      for di = 1:N
        Ts      = futuresData.DTM(di);
        uTs     = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx     = (1 + max(0,Ts - self.asianterms)):Ts;
        DailyFuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*mu0s(:) + self.pricingcoeffs.Df(idx).*v0s(:)),2))./self.asianterms;
      end
    end % getDailyFuturesPrices

    function FuturesPrices = getFuturesPrices(self,futuresData,mus,vs)
      pv = self.getPV;

      N         = height(futuresData); 
      if N == 0
        FuturesPrices = zeros(0,0);
        return;
      end

      for di = 1:N
        curdate     = find(self.calendar == futuresData.Date(di));
        x0s         = self.series(curdate);
        mu0s        = mus(curdate);
        v0s         = vs(curdate);

        Ts          = futuresData.DTM(di);
        uTs         = self.deterministic.uT((curdate + 1 + max(0,Ts - self.asianterms)):(curdate+Ts))';
        idx         = (1 + max(0,Ts - self.asianterms)):Ts;
        FuturesPrices(:,di) = (futuresData.CurrentSumSpot(di) + sum(exp(uTs + self.pricingcoeffs.Af(idx) + self.pricingcoeffs.Bf(idx).*x0s + self.pricingcoeffs.Cf(idx).*mu0s(:) + self.pricingcoeffs.Df(idx).*v0s(:))))./self.asianterms;
      end
    end % getFuturesPrices

  end % methods

end % classdef SVJLRL < OptimProblem
