classdef ParticleFilter_SVJ < handle
  properties
    particles     = [];            % Structure containing the various particles needed
    nb_particles  = 25000;         % 25000 particles by default
    nb_partitions = 1;
    max_length    = 1000;          % Maximum length (so that size of particle cache is decent)
    resampling    = 'MalikPitt';   % Resampling method; could be 'MalikPitt' or 'Stratified'
    time          = [];            % At each time the logLikelihood is called,  we calculate the time it takes to run it
    model         = [];            % Instance of the MRSVDI model
  end % properties
  
  methods
    function self = ParticleFilter_SVJ(model, nb_particles)
      if nargin > 1
        self.nb_particles = nb_particles;
      end
      self.model          = model;
      self.getParticles();
    end % ParticleFilter_SVJ
    
    function [] = getParticles(self)
      T = length(self.model.series);
      switch self.model.name
        case 'SVJ'
          self.particles.Wv         = normrnd(0,1,self.nb_particles,min(self.max_length,T));
          self.particles.Np         = unifrnd(0,1,self.nb_particles,min(self.max_length,T));
          self.particles.Nn         = unifrnd(0,1,self.nb_particles,min(self.max_length,T));
          self.particles.Zp         = unifrnd(0,1,self.nb_particles,min(self.max_length,T));
          self.particles.Zn         = unifrnd(0,1,self.nb_particles,min(self.max_length,T));
          self.particles.Zv         = unifrnd(0,1,self.nb_particles,min(self.max_length,T));

          self.particles.u_resampl  = unifrnd(0,1,T,1);
        otherwise
          error('Model not implemented in the ParticleFilter class')
      end
    end % getParticles
    
    function [logLikelihood, vf, Npf, Nnf, Jpf, Jnf, Jvf] = logLikelihood(self)
      tic();
      % This function applies the SIR methodology to obtain the
      % likelihood function and the various filtered values.
      assert(~isempty(self.particles),'Particles have not been simulated yet.');
      
      T   = length(self.model.series);

      % Copy of parameters
      pv  = self.model.getPV();
      
      % Initialization
      logLikelihood = NaN(T,1);
      vf            = NaN(T,1);
      Npf           = NaN(T,1);
      Nnf           = NaN(T,1);
      Jpf           = NaN(T,1);
      Jnf           = NaN(T,1);
      Jvf           = NaN(T,1);

      v             = pv.vbar.*ones(self.nb_particles,1);

      for dt = 1:T
        [weights, v, Np, Nn, Jp, Jn, Jv] = self.updateState(pv, dt, v);
        normalizedweights = weights./sum(weights);
        
        % If the current parameter set returns weights of zero for every
        % particle, then its log-likelihood contribution is -Inf. We also
        % terminate the program.
        if sum(~isnan(normalizedweights)) == 0
          logLikelihood(:) = -Inf;
          return;
        end
        
        % Compute filtered values based on normalized weights
        logLikelihood(dt) = log( mean(weights) );
        vf(dt)        = v'*normalizedweights;
        Npf(dt)       = Np'*normalizedweights;
        Nnf(dt)       = Nn'*normalizedweights;
        Jpf(dt)       = Jp'*normalizedweights;
        Jnf(dt)       = Jn'*normalizedweights;
        Jvf(dt)       = Jv'*normalizedweights;

        % Resampling; two methods are implemented:
        %   - MalikPitt : Malik & Pitt (2011)
        %   - Stratified: Stratified resampling
        switch self.resampling
          case 'MalikPitt'
            [v] = self.MalikPitt(dt, weights, v);
          case 'Stratified'
            [v] = self.Stratified(dt, weights, v);
          otherwise
            error('Specified resampling method not implemented.');
        end % switch self.resampling
        
      end % end dt = 1:T
      time_tmp = toc();
      self.time = [self.time, time_tmp];
    end % logLikelihood

    function [vnew] = Stratified(self, dt, weights, v)
      I = randsample_stratified_cpp(weights, self.particles.u_resampl(dt,1));
      vnew = v(I);
    end % Stratified

    function [vnew] = MalikPitt(self, dt, weights, v)
      Vnew = NaN(self.nb_particles,1);
      V = [v];
      
      norm_weights = weights./sum(weights);
      Vw = sortrows([V, norm_weights], 1);
      V = Vw(:,1:(end-1));
      norm_weights = Vw(:,end);
      
      norm_weights_cumsum = [0;cumsum(norm_weights)];
      PartitionSize = self.nb_particles/self.nb_partitions;
      for dp = 1:self.nb_partitions
        ix = find( norm_weights_cumsum(2:end) > (dp-1)/self.nb_partitions & norm_weights_cumsum(1:end-1) < dp/self.nb_partitions );
        
        if isscalar(ix)
          Vnew(((dp-1)*PartitionSize+1):(dp*PartitionSize),:) = repmat(V(ix,:),PartitionSize,1);
        else
          norm_weights_tmp = norm_weights(ix).*self.nb_partitions;
          norm_weights_tmp(1) = self.nb_partitions*norm_weights_cumsum(ix(1)+1) - (dp - 1);
          norm_weights_tmp(end) = dp - self.nb_partitions*norm_weights_cumsum(ix(end-1)+1);
          
          [r,ustar] = getrandustar_cpp(norm_weights_tmp,PartitionSize,self.particles.u_resampl(dt,1));
          Vnew(((dp-1)*PartitionSize+1):(dp*PartitionSize),1) = V(ix(r),1) + ustar.*(V(ix(min(length(ix),r+1)),1) - V(ix(r),1));
        end
      end
      vnew = Vnew(:,1);
    end % MalikPitt

    function [weights, v, Np, Nn, Jp, Jn, Jv] = updateState(self, pv, dt, v_old)
      h           = self.model.h;

      % Step 1: we compute Np, Nn, Zxp, Zxn, Zv, Zlambda
      cur_step    = mod(dt-1,self.max_length) + 1;

      Np          = self.particles.Np(:,cur_step) < pv.lambdap.*h;
      Nn          = self.particles.Nn(:,cur_step) < pv.lambdan*h;
      Zp          = zeros(self.nb_particles,1);
      Zp(Np)      = expinv(self.particles.Zp(Np,cur_step),pv.nup);
      Zn          = zeros(self.nb_particles,1);
      Zn(Nn)      = -expinv(self.particles.Zp(Nn,cur_step),pv.nun);
      Zv          = zeros(self.nb_particles,1);
      Zv(Np)      = expinv(self.particles.Zv(Np,cur_step),pv.nuv);
      
      Jp          = Zp.*Np;
      Jn          = Zn.*Nn; 
      Jv          = Zv.*Np; 

      % Step 2: we use Euler-Maruyama to get new mu, v and lambda
      averv       = v_old + pv.kappav.*(pv.vbar - v_old).*h;
      varv        = pv.sigmav^2.*v_old.*h;
      vm          = max( self.model.V_MIN, averv + sqrt(varv).*self.particles.Wv(:,cur_step) );
      v           = vm + Jv;

      % Step 3: Compute the expected value and variance of x based on
      % particles
      xtm1        = self.model.series(max(dt-1,1));

      averx       = xtm1 + pv.kappax.*(pv.mubar - xtm1)*h + ...
                    pv.rho./pv.sigmav.*(vm - v_old - pv.kappav.*pv.vbar.*h + pv.kappav.*v_old.*h) + Jp + Jn;
      varx        = (1-pv.rho^2).*v_old.*h;
          
      % Step 4: Compute the weights based on spots
      weights     = (-0.5*log(2*pi*varx) -0.5*(averx-self.model.series(dt)).^2./varx);

      % Step 5: Correct weights based on futures
      if self.model.use_futures && height(self.model.futures{dt}) > 0
        futuresPrices = self.model.getDailyFuturesPrices(self.model.futures{dt},v)';
        errFutures = log(futuresPrices) - log(self.model.futures{dt}.Price);
        % We use a weighted likelihood argument to make sure the P
        % information is not dilluted too much...
        weights = weights + mean(-0.5*log(2*pi*pv.delta^2) -0.5*(errFutures).^2./pv.delta^2)';
      end

      weights(isnan(weights)) = -Inf;
      weights = exp(weights);

    end % updateState
    
  end % methods

end % classdef ParticleFilter_SVJ