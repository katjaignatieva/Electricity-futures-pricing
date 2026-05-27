function fig = figPricingErrors()

load('data/DailySpotPrices');
load('data/FuturesPrices');
load('results/model_PQ_SVJDILRL')
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

%% SVJDILRL
load('results/model_PQ_SVJDILRL_filtered')
load('results/model_PQ_SVJDILRL')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappamuQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ),log(pv.nulambdaQ)];

[~,price] = errorFutures(pp0,model,FuturesPrices,muf,vf,lambdaf);

fig = figure('units','pixels','outerposition',[0 0 1000 800]);
colors = colormap();
set(gcf,'color','w');
ix = FuturesPrices.DTM < 92;

subplot(2,2,1)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
plot(FuturesPrices.Date(ix),price(ix),'r-','LineWidth',2,'color',colors(100,:))
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('DTM \leq 91')
legend('Market price','Model price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM < 183 & FuturesPrices.DTM >= 92;

subplot(2,2,2)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
plot(FuturesPrices.Date(ix),price(ix),'r-','LineWidth',2,'color',colors(100,:))
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('91 < DTM \leq 182')
legend('Market price','Model price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM < 274 & FuturesPrices.DTM >= 183;

subplot(2,2,3)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
plot(FuturesPrices.Date(ix),price(ix),'r-','LineWidth',2,'color',colors(100,:))
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('182 < DTM \leq 273')
legend('Market price','Model price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM <= 365 & FuturesPrices.DTM >= 274;

subplot(2,2,4)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
plot(FuturesPrices.Date(ix),price(ix),'r-','LineWidth',2,'color',colors(100,:))
datetick();
% xlim([Date(1),Date(end)])
title('273 < DTM \leq 365 ')
ylim([20,400])
legend('Market price','Model price','location','northwest')
set(gca,'FontSize',10)

end
