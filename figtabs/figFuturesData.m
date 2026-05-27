function fig = figFuturesData()

load('data/DailySpotPrices');
load('data/FuturesPrices');

fig = figure('units','pixels','outerposition',[0 0 1000 800]);
colors = colormap();
set(gcf,'color','w');
ix = FuturesPrices.DTM < 92;

subplot(2,2,1)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('DTM \leq 91')
legend('Market price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM < 183 & FuturesPrices.DTM >= 92;

subplot(2,2,2)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('91 < DTM \leq 182')
legend('Market price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM < 274 & FuturesPrices.DTM >= 183;

subplot(2,2,3)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
datetick();
ylim([20,400])
% xlim([Date(1),Date(end)])
title('182 < DTM \leq 273')
legend('Market price','location','northwest')
set(gca,'FontSize',10)

ix = FuturesPrices.DTM <= 365 & FuturesPrices.DTM >= 274;

subplot(2,2,4)
plot(FuturesPrices.Date(ix),FuturesPrices.Price(ix),'kx','LineWidth',2,'color',colors(1,:),'MarkerSize',3)
datetick();
hold on
datetick();
% xlim([Date(1),Date(end)])
title('273 < DTM \leq 365 ')
ylim([20,400])
legend('Market price','location','northwest')
set(gca,'FontSize',10)


end
