function fig = figTermStructure()

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

%% SVJDI
load('results/model_PQ_SVJDI_filtered')
load('results/model_PQ_SVJDI')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ),log(pv.nulambdaQ)];

[mmSVJDI,priceSVJDI] = errorFutures(pp0,model,FuturesPrices,[],vf,lambdaf);

%% SVJLRL
load('results/model_PQ_SVJLRL_filtered')
load('results/model_PQ_SVJLRL')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappamuQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ)];

[mmSVJLRL,priceSVJLRL] = errorFutures(pp0,model,FuturesPrices,muf,vf,[]);

%% SVJDILRL
load('results/model_PQ_SVJDILRL_filtered')
load('results/model_PQ_SVJDILRL')

pv = model.getPV();
pp0 = [log(pv.kappaxQ),log(pv.kappamuQ),log(pv.kappavQ),log(pv.nupQ),log(pv.nunQ),log(pv.nuvQ),log(pv.nulambdaQ)];

[mmSVJDILRL,priceSVJDILRL] = errorFutures(pp0,model,FuturesPrices,muf,vf,lambdaf);

%%
fig = figure('units','pixels','outerposition',[0 0 1000 700]);
colors = colormap();
set(gcf,'color','w');

subplot(2,2,1)
ix = FuturesPrices.Date == datenum(2007,9,14);
h1 = plot([0,FuturesPrices.DTM(ix)],[-100,FuturesPrices.Price(ix)],'kx','Color',colors(1,:),'markersize',5);
hold on
h2 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJ(ix)],'LineWidth',2,'Color',colors(100,:));
h3 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDI(ix)],'LineWidth',2,'Color',colors(150,:));
h4 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJLRL(ix)],'LineWidth',2,'Color',colors(200,:));
h5 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDILRL(ix)],'LineWidth',2,'Color',colors(250,:));
plot(FuturesPrices.DTM(ix),FuturesPrices.Price(ix),'kx','Color',colors(1,:),'markersize',5)
plot([365,365],[0,1000],'k--');
xlim([0,1400]);
ylim([25,150]);
title('September 14, 2007')
xlabel('Days to maturity')
legend([h1,h2,h3,h4,h5],{'Market price','SVJ','SVJ-DI','SVJ-LRL','SVJ-DI-LRL'},'location','northwest','NumColumns',2)
set(gca,'FontSize',10)

subplot(2,2,2)
ix = FuturesPrices.Date == datenum(2013,1,25);
h1 = plot([0,FuturesPrices.DTM(ix)],[-100,FuturesPrices.Price(ix)],'kx','Color',colors(1,:),'markersize',5);
hold on
h2 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJ(ix)],'LineWidth',2,'Color',colors(100,:));
h3 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDI(ix)],'LineWidth',2,'Color',colors(150,:));
h4 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJLRL(ix)],'LineWidth',2,'Color',colors(200,:));
h5 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDILRL(ix)],'LineWidth',2,'Color',colors(250,:));
plot(FuturesPrices.DTM(ix),FuturesPrices.Price(ix),'kx','Color',colors(1,:),'markersize',5)
plot([365,365],[0,1000],'k--');
xlim([0,1400]);
ylim([25,150]);
title('January 25, 2013')
xlabel('Days to maturity')
legend([h1,h2,h3,h4,h5],{'Market price','SVJ','SVJ-DI','SVJ-LRL','SVJ-DI-LRL'},'location','northwest','NumColumns',2)
set(gca,'FontSize',10)

subplot(2,2,3)
ix = FuturesPrices.Date == datenum(2020,3,18);
h1 = plot([0,FuturesPrices.DTM(ix)],[-100,FuturesPrices.Price(ix)],'kx','Color',colors(1,:),'markersize',5);
hold on
h2 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJ(ix)],'LineWidth',2,'Color',colors(100,:));
h3 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDI(ix)],'LineWidth',2,'Color',colors(150,:));
h4 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJLRL(ix)],'LineWidth',2,'Color',colors(200,:));
h5 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDILRL(ix)],'LineWidth',2,'Color',colors(250,:));
plot(FuturesPrices.DTM(ix),FuturesPrices.Price(ix),'kx','Color',colors(1,:),'markersize',5)
plot([365,365],[0,1000],'k--');
xlim([0,1400]);
ylim([25,250]);
title('March 18, 2020')
xlabel('Days to maturity')
legend([h1,h2,h3,h4,h5],{'Market price','SVJ','SVJ-DI','SVJ-LRL','SVJ-DI-LRL'},'location','northwest','NumColumns',2)
set(gca,'FontSize',10)

subplot(2,2,4)
ix = FuturesPrices.Date == datenum(2022,8,11);
h1 = plot([0,FuturesPrices.DTM(ix)],[-100,FuturesPrices.Price(ix)],'kx','Color',colors(1,:),'markersize',5);
hold on
h2 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJ(ix)],'LineWidth',2,'Color',colors(100,:));
h3 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDI(ix)],'LineWidth',2,'Color',colors(150,:));
h4 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJLRL(ix)],'LineWidth',2,'Color',colors(200,:));
h5 = plot([0,FuturesPrices.DTM(ix)],[-100,priceSVJDILRL(ix)],'LineWidth',2,'Color',colors(250,:));
plot(FuturesPrices.DTM(ix),FuturesPrices.Price(ix),'kx','Color',colors(1,:),'markersize',5)
plot([365,365],[0,1000],'k--');
xlim([0,1400]);
ylim([50,450]);
title('August 11, 2022')
xlabel('Days to maturity')

legend([h1,h2,h3,h4,h5],{'Market price','SVJ','SVJ-DI','SVJ-LRL','SVJ-DI-LRL'},'location','northwest','NumColumns',2)
set(gca,'FontSize',10)


end