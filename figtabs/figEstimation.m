function [fig1,fig2,fig3] = figEstimation()

  load('data/DailySpotPrices');
  Date = datenum(DailySpotPrices.Date);
  load('results/model_PQ_SVJDILRL_filtered')
  load('results/model_PQ_SVJDILRL')

  fig1 = figure('units','pixels','outerposition',[0 0 1000 1000]);

  colors = colormap();

  set(gcf,'color','w');
  subplot(3,1,1)
  plot(Date,muf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Long-run level')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  
  subplot(3,1,2)
  plot(Date,sqrt(vf),'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Volatility')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  
  subplot(3,1,3)
  plot(Date,lambdaf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Negative jump intensity')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([15,30])
  
  fig2 = figure('units','pixels','outerposition',[0 0 1000 1000]);
  set(gcf,'color','w');

  subplot(4,1,1)
  plot(Date,Jpf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Positive spot price jumps')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)

  subplot(4,1,2)
  plot(Date,Jnf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Negative spot price jumps')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)

  subplot(4,1,3)
  plot(Date,Jvf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Variance jumps')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([0,0.6])
  
  subplot(4,1,4)
  plot(Date,Jlambdaf,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Negative jump intensity jumps')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([0,0.6])

  pv = model.getPV;
  xx = model.series(2:end) - model.series(1:end-1) - pv.kappax.*(muf(1:end-1) - model.series(1:end-1))/365;
  
  % Plot of the Gaussian and jump components of the (stochastic component of the) spot price
  fig3 = figure('units','pixels','outerposition',[0 0 1000 700]);

  set(gcf,'color','w');
  subplot(3,1,1)
  plot(Date(2:end),xx,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Total innovation of the stochastic component')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([-4.5,4.5])
  
  subplot(3,1,2)
  plot(Date(2:end),xx-Jnf(2:end)-Jpf(2:end),'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Diffusive term')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([-1,1])
  
  subplot(3,1,3)
  plot(Date(2:end),Jnf(2:end)+Jpf(2:end),'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Jump term')
  xlabel('Date')
  xlim([Date(1),Date(end)])
  set(gca,'FontSize',10)
  ylim([-4.5,4.5])
end