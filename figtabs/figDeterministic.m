function fig = figDeterministic()

  load('data/DailySpotPrices.mat');
  date = datenum(DailySpotPrices.Date);
  logSpot = log(DailySpotPrices.Price);
  
  t = (date - datenum(year(date(1)),1,1))./365;
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

  % Plot of the log spot price
  fig = figure('units','pixels','outerposition',[0 0 1000 800]);

  colors = colormap();

  set(gcf,'color','w');
  subplot(3,1,1)
  h1 = plot(date,logSpot,'k-','linewidth',2,'color',[colors(100,:)]);
  hold on
  h2 = plot(date,logSpot-deterministicSpot.residuals,'k-','linewidth',2,'color',colors(1,:));
  datetick();
  title('Deterministic component')
  xlabel('Date')
  ylim([1,8])
  xlim([date(1),date(end)])
  set(gca,'FontSize',10)
  legend([h2,h1],'Deterministic component','Logarithm of the spot price','location','southwest','Orientation','horizontal')

  subplot(3,1,2)
  plot(date,deterministicSpot.residuals,'k-','linewidth',2,'color',colors(1,:))
  hold on
  plot(date,smooth(deterministicSpot.residuals,91),'k-','linewidth',3,'color',colors(100,:))
  datetick();
  title('Stochastic component')
  xlabel('Date')
  xlim([date(1),date(end)])
  set(gca,'FontSize',10)
  legend('Stochastic component','Three-month moving average','location','southwest','Orientation','horizontal')
  
  subplot(3,1,3)
  plot(date(2:end),diff(deterministicSpot.residuals),'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('First-order difference of the stochastic component')
  xlabel('Date')
  xlim([date(1),date(end)])
  set(gca,'FontSize',10)

end