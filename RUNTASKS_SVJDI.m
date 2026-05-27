clear all; clc;
startup;
OPTIM = false;

%% Extract data

% Load spot price data
load('data/DailySpotPrices.mat');

% Load futures data (futures data are proprietary and cannot be shared; we
% only include one day of data to show how it looks like)
load('data/FuturesPrices.mat');

%% Run estimation for deterministic component
Date = datenum(DailySpotPrices.Date);
logSpot = log(DailySpotPrices.Price);

t = (Date - datenum(year(Date(1)),1,1))./365;
dayofw = weekday(DailySpotPrices.Date);
monthofy = month(DailySpotPrices.Date);

% Construct the design matrix
X = NaN(length(t),10);
X(:,1) = 1;
X(:,2) = t;
X(:,3) = sin(2*pi.*t);
X(:,4) = cos(2*pi.*t);
for di = 2:7
  X(:,3+di) = dayofw == di;
end
for di = 2:12
  X(:,9+di) = monthofy == di;
end

Y = logSpot;

% Regress X on Y
[coeffs,interv,x,~,statistics] = regress(Y,X);
stderrors = diff(interv')'./(2*norminv(0.975));

deterministicSpot.coeffs = coeffs;
deterministicSpot.stderrors = stderrors;
deterministicSpot.R2 = statistics(1);
deterministicSpot.residuals = x;

clear coeffs interv statistics

%% Estimation 
for dt = 1:length(Date)
  DailyFuturesPrices{dt} = table();
end

% Create an instance of the SVJDILRL model
model = SVJDI('calendar',Date, ...
               'series',x, ...
               'deterministic',deterministicSpot, ...
               'use_futures',true, ...
               'scale_pvalues', true, ...
               'futures',DailyFuturesPrices);

FuturesPrices.Date = datenum(FuturesPrices.Date);
FuturesPrices.MaturityDate = datenum(FuturesPrices.MaturityDate);
DailySpotPrices.Date = datenum(DailySpotPrices.Date);

FuturesPrices = FuturesPrices(FuturesPrices.DTM < 366,:);

% Convert into daily tables for particle filter
for dt = 1:length(Date)
  DailyFuturesPrices{dt} = FuturesPrices(FuturesPrices.Date == Date(dt),:);
  for di = 1:height(DailyFuturesPrices{dt})
    if DailyFuturesPrices{dt}.DTM(di) < model.asianterms
      PastDates = (DailyFuturesPrices{dt}.Date(di)-model.asianterms+DailyFuturesPrices{dt}.DTM(di)+1):DailyFuturesPrices{dt}.Date(di);
      DailyFuturesPrices{dt}.CurrentSumSpot(di) = sum(interp1(DailySpotPrices.Date,DailySpotPrices.Price,PastDates,'nearest','extrap'));
    else
      DailyFuturesPrices{dt}.CurrentSumSpot(di) = 0;
    end
  end
end

model.use_futures = true;
model.futures = DailyFuturesPrices;
model.updateFuturesPricingCoefficients();

% Create an instance of the particle filter object
pf = ParticleFilter_SVJDI(model,25000);

if OPTIM
  res = model.fminsearch(model.penalty,pf);
  save('results/model_PQ_SVJDI','model');

  [logLikelihood, vf, lambdaf, Npf, Nnf, Jpf, Jnf, Jvf, Jlambdaf] = pf.logLikelihood();
  save('results/model_PQ_SVJDI_filtered','logLikelihood', 'vf', 'lambdaf', 'Npf', 'Nnf', 'Jpf', 'Jnf', 'Jvf', 'Jlambdaf');
end



