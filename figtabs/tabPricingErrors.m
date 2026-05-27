function [tabISF,tabISDM,tabOOSF,tabOOSDM] = tabPricingErrors()

load('data/DailySpotPrices');
load('data/FuturesPrices');
load('results/model_PQ_SVJ')
load('data/DailyRV')

Date = datenum(DailySpotPrices.Date);
logSpot = log(DailySpotPrices.Price);
FuturesPrices.Date = datenum(FuturesPrices.Date);
FuturesPrices.MaturityDate = datenum(FuturesPrices.MaturityDate);
DailySpotPrices.Date = datenum(DailySpotPrices.Date);

for di = 1:height(FuturesPrices)
  if FuturesPrices.DTM(di) < model.asianterms
    PastDates = (FuturesPrices.Date(di)-model.asianterms+FuturesPrices.DTM(di)+1):FuturesPrices.Date(di);
    FuturesPrices.CurrentSumSpot(di) = sum(interp1(DailySpotPrices.Date,DailySpotPrices.Price,PastDates,'nearest','extrap'));
  else
    FuturesPrices.CurrentSumSpot(di) = 0;
  end
end

%% SVJ
load('results/model_PQ_SVJ_filtered')
load('results/model_PQ_SVJ')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ)];

[mmSVJ,priceSVJ] = errorFutures(pp0,model,FuturesPrices,[],vf,[]);

tabISF(1,1) = model.params.delta.value;

%% SVJDI
load('results/model_PQ_SVJDI_filtered')
load('results/model_PQ_SVJDI')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ),log(pv.nulambdaQ)];

[mmSVJDI,priceSVJDI] = errorFutures(pp0,model,FuturesPrices,[],vf,lambdaf);

tabISF(1,2) = model.params.delta.value;

%% SVJLRL
load('results/model_PQ_SVJLRL_filtered')
load('results/model_PQ_SVJLRL')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappamuQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ)];

[mmSVJLRL,priceSVJLRL] = errorFutures(pp0,model,FuturesPrices,muf,vf,[]);

tabISF(1,3) = model.params.delta.value;

%% SVJDILRL
load('results/model_PQ_SVJDILRL_filtered')
load('results/model_PQ_SVJDILRL')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappamuQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ),log(pv.nulambdaQ)];

[mmSVJDILRL,priceSVJDILRL] = errorFutures(pp0,model,FuturesPrices,muf,vf,lambdaf);

tabISF(1,4) = model.params.delta.value;

%%
rrSVJ       = (log(FuturesPrices.Price) - log(priceSVJ)).^2;
rrSVJDI     = (log(FuturesPrices.Price) - log(priceSVJDI)).^2;
rrSVJLRL    = (log(FuturesPrices.Price) - log(priceSVJLRL)).^2;
rrSVJDILRL  = (log(FuturesPrices.Price) - log(priceSVJDILRL)).^2;

%% In-sample fit
tabISF = NaN(20,4);

ix        = FuturesPrices.DTM < 366;

tabISF(1,1) = sqrt(mean(rrSVJ(ix)));
tabISF(1,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(1,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(1,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 91;
tabISF(3,1) = sqrt(mean(rrSVJ(ix)));
tabISF(3,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(3,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(3,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 91 & FuturesPrices.DTM < 182;
tabISF(4,1) = sqrt(mean(rrSVJ(ix)));
tabISF(4,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(4,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(4,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 182 & FuturesPrices.DTM < 273;
tabISF(5,1) = sqrt(mean(rrSVJ(ix)));
tabISF(5,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(5,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(5,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 273 & FuturesPrices.DTM < 366;
tabISF(6,1) = sqrt(mean(rrSVJ(ix)));
tabISF(6,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(6,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(6,4) = sqrt(mean(rrSVJDILRL(ix)));

qRV       = quantile(sqrt(DailyRV.RV),[0.25,0.50,0.75]);
RVs       = interp1(datenum(DailyRV.Date),sqrt(DailyRV.RV),FuturesPrices.Date);

ix        = FuturesPrices.DTM < 366 & RVs < qRV(1);
tabISF(8,1) = sqrt(mean(rrSVJ(ix)));
tabISF(8,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(8,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(8,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 366 & RVs >= qRV(1) & RVs < qRV(2);
tabISF(9,1) = sqrt(mean(rrSVJ(ix)));
tabISF(9,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(9,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(9,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 366 & RVs >= qRV(2) & RVs < qRV(3);
tabISF(10,1) = sqrt(mean(rrSVJ(ix)));
tabISF(10,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(10,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(10,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 366 & RVs >= qRV(3);
tabISF(11,1) = sqrt(mean(rrSVJ(ix)));
tabISF(11,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(11,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(11,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2006 & year(FuturesPrices.Date) < 2007;
tabISF(13,1) = sqrt(mean(rrSVJ(ix)));
tabISF(13,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(13,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(13,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2007 & year(FuturesPrices.Date) < 2009;
tabISF(14,1) = sqrt(mean(rrSVJ(ix)));
tabISF(14,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(14,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(14,4) = sqrt(mean(rrSVJDILRL(ix)));
 
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2009 & year(FuturesPrices.Date) < 2012;
tabISF(15,1) = sqrt(mean(rrSVJ(ix)));
tabISF(15,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(15,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(15,4) = sqrt(mean(rrSVJDILRL(ix)));
  
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2012 & year(FuturesPrices.Date) < 2015;
tabISF(16,1) = sqrt(mean(rrSVJ(ix)));
tabISF(16,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(16,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(16,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2015 & year(FuturesPrices.Date) < 2017;
tabISF(17,1) = sqrt(mean(rrSVJ(ix)));
tabISF(17,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(17,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(17,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2017 & year(FuturesPrices.Date) < 2020;
tabISF(18,1) = sqrt(mean(rrSVJ(ix)));
tabISF(18,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(18,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(18,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2020 & year(FuturesPrices.Date) < 2022;
tabISF(19,1) = sqrt(mean(rrSVJ(ix)));
tabISF(19,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(19,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(19,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM < 366 & year(FuturesPrices.Date) >= 2022 & year(FuturesPrices.Date) < 2024;
tabISF(12,1) = sqrt(mean(rrSVJ(ix)));
tabISF(12,2) = sqrt(mean(rrSVJDI(ix)));
tabISF(12,3) = sqrt(mean(rrSVJLRL(ix)));
tabISF(12,4) = sqrt(mean(rrSVJDILRL(ix)));

%% In-sample DM
for di = 1:((length(Date)/7)-1)
  for dw = 1:53
    ix = FuturesPrices.Date >= (datenum(2006,1,1) + (di-1)*7) & FuturesPrices.Date < (datenum(2006,1,1) + di*7);
    ix = ix & FuturesPrices.DTM < 366;
    rmseSVJ(di)       = sqrt(mean(rrSVJ(ix)));
    rmseSVJDI(di)     = sqrt(mean(rrSVJDI(ix)));
    rmseSVJLRL(di)    = sqrt(mean(rrSVJLRL(ix)));
    rmseSVJDILRL(di)  = sqrt(mean(rrSVJDILRL(ix)));
  end
end

tabISDM = NaN(6,4);

tabISDM(1,1) = nanmean(rmseSVJ);
tabISDM(1,2) = nanmean(rmseSVJDI);
tabISDM(1,3) = nanmean(rmseSVJLRL);
tabISDM(1,4) = nanmean(rmseSVJDILRL);
tabISDM(2,1) = nanstd(rmseSVJ);
tabISDM(2,2) = nanstd(rmseSVJDI);
tabISDM(2,3) = nanstd(rmseSVJLRL);
tabISDM(2,4) = nanstd(rmseSVJDILRL);

tabISDM(4,2) = dmtest(rmseSVJ - rmseSVJDI, 10);
tabISDM(4,3) = dmtest(rmseSVJ - rmseSVJLRL, 10);
tabISDM(4,4) = dmtest(rmseSVJ - rmseSVJDILRL, 10);

tabISDM(5,3) = dmtest(rmseSVJDI - rmseSVJLRL, 10);
tabISDM(5,4) = dmtest(rmseSVJDI - rmseSVJDILRL, 10);

tabISDM(6,4) = dmtest(rmseSVJLRL - rmseSVJDILRL, 10);

%% Out-of-sample fit
tabOOSF = NaN(20,4);

ix        = FuturesPrices.DTM > 366;

tabOOSF(1,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(1,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(1,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(1,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & FuturesPrices.DTM < 2*365;
tabOOSF(3,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(3,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(3,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(3,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 2*365 & FuturesPrices.DTM < 3*365;
tabOOSF(4,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(4,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(4,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(4,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 3*365 & FuturesPrices.DTM < 4*365;
tabOOSF(5,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(5,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(5,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(5,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 4*365 & FuturesPrices.DTM < 5*365;
tabOOSF(6,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(6,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(6,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(6,4) = sqrt(mean(rrSVJDILRL(ix)));

qRV       = quantile(sqrt(DailyRV.RV),[0.25,0.50,0.75]);
RVs       = interp1(datenum(DailyRV.Date),sqrt(DailyRV.RV),FuturesPrices.Date);

ix        = FuturesPrices.DTM >= 366 & RVs < qRV(1);
tabOOSF(8,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(8,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(8,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(8,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & RVs >= qRV(1) & RVs < qRV(2);
tabOOSF(9,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(9,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(9,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(9,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & RVs >= qRV(2) & RVs < qRV(3);
tabOOSF(10,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(10,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(10,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(10,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & RVs >= qRV(3);
tabOOSF(11,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(11,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(11,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(11,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2006 & year(FuturesPrices.Date) < 2007;
tabOOSF(13,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(13,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(13,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(13,4) = sqrt(mean(rrSVJDILRL(ix)));

ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2007 & year(FuturesPrices.Date) < 2009;
tabOOSF(14,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(14,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(14,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(14,4) = sqrt(mean(rrSVJDILRL(ix)));
 
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2009 & year(FuturesPrices.Date) < 2012;
tabOOSF(15,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(15,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(15,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(15,4) = sqrt(mean(rrSVJDILRL(ix)));
  
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2012 & year(FuturesPrices.Date) < 2015;
tabOOSF(16,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(16,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(16,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(16,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2015 & year(FuturesPrices.Date) < 2017;
tabOOSF(17,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(17,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(17,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(17,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2017 & year(FuturesPrices.Date) < 2020;
tabOOSF(18,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(18,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(18,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(18,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2020 & year(FuturesPrices.Date) < 2022;
tabOOSF(19,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(19,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(19,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(19,4) = sqrt(mean(rrSVJDILRL(ix)));
   
ix        = FuturesPrices.DTM >= 366 & year(FuturesPrices.Date) >= 2022 & year(FuturesPrices.Date) < 2024;
tabOOSF(20,1) = sqrt(mean(rrSVJ(ix)));
tabOOSF(20,2) = sqrt(mean(rrSVJDI(ix)));
tabOOSF(20,3) = sqrt(mean(rrSVJLRL(ix)));
tabOOSF(20,4) = sqrt(mean(rrSVJDILRL(ix)));

%% Out-of-sample DM
for di = 1:((length(Date)/7)-1)
  for dw = 1:53
    ix = FuturesPrices.Date >= (datenum(2006,1,1) + (di-1)*7) & FuturesPrices.Date < (datenum(2006,1,1) + di*7);
    ix = ix & FuturesPrices.DTM >= 366;
    rmseSVJ(di) = sqrt(mean(rrSVJ(ix)));
    rmseSVJDI(di) = sqrt(mean(rrSVJDI(ix)));
    rmseSVJLRL(di) = sqrt(mean(rrSVJLRL(ix)));
    rmseSVJDILRL(di) = sqrt(mean(rrSVJDILRL(ix)));
  end
end

tabOOSDM = NaN(6,4);

tabOOSDM(1,1) = nanmean(rmseSVJ);
tabOOSDM(1,2) = nanmean(rmseSVJDI);
tabOOSDM(1,3) = nanmean(rmseSVJLRL);
tabOOSDM(1,4) = nanmean(rmseSVJDILRL);
tabOOSDM(2,1) = nanstd(rmseSVJ);
tabOOSDM(2,2) = nanstd(rmseSVJDI);
tabOOSDM(2,3) = nanstd(rmseSVJLRL);
tabOOSDM(2,4) = nanstd(rmseSVJDILRL);

tabOOSDM(4,2) = dmtest(rmseSVJ - rmseSVJDI, 10);
tabOOSDM(4,3) = dmtest(rmseSVJ - rmseSVJLRL, 10);
tabOOSDM(4,4) = dmtest(rmseSVJ - rmseSVJDILRL, 10);

tabOOSDM(5,3) = dmtest(rmseSVJDI - rmseSVJLRL, 10);
tabOOSDM(5,4) = dmtest(rmseSVJDI - rmseSVJDILRL, 10);

tabOOSDM(6,4) = dmtest(rmseSVJLRL - rmseSVJDILRL, 10);

end