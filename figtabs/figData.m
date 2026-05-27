function fig = figData()

  load('data/DailySpotPrices.mat');
  dates = datenum(DailySpotPrices.Date);
  logSpot = log(DailySpotPrices.Price);

  % Plot of the log spot price
  fig = figure('units','pixels','outerposition',[0 0 1000 500]);

  colors = colormap();

  set(gcf,'color','w');
  subplot(2,1,1)
  plot(dates,exp(logSpot),'k-','linewidth',2,'color',colors(1,:))

  hold on
  ybars = [0,1550];
  text(datenum(2006,1,1)+50,ybars(2)-diff(ybars).*0.06,'A')
  xlims = [datenum(2007,1,1),datenum(2009,1,1)];
  p1 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p1.EdgeColor = p1.FaceColor;
  p1.FaceAlpha = 0.5;
  text(xlims(1)+50,ybars(2)-diff(ybars).*0.06,'B')

  text(datenum(2009,1,1)+50,ybars(2)-diff(ybars).*0.06,'C')

  xlims = [datenum(2012,1,1),datenum(2015,1,1)];
  p2 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p2.EdgeColor = p2.FaceColor;
  p2.FaceAlpha = 0.5;
  
  text(datenum(2012,1,1)+50,ybars(2)-diff(ybars).*0.06,'D')
  text(datenum(2015,1,1)+50,ybars(2)-diff(ybars).*0.06,'E')

  xlims = [datenum(2017,1,1),datenum(2020,1,1)];
  p3 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p3.EdgeColor = p3.FaceColor;
  p3.FaceAlpha = 0.5;

  text(datenum(2017,1,1)+50,ybars(2)-diff(ybars).*0.06,'F')

  text(datenum(2020,1,1)+50,ybars(2)-diff(ybars).*0.06,'G')

  xlims = [datenum(2022,1,1),datenum(2023,4,1)];
  p4 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p4.EdgeColor = p4.FaceColor;
  p4.FaceAlpha = 0.5;

  text(datenum(2022,1,1)+50,ybars(2)-diff(ybars).*0.06,'H')

  plot(dates,exp(logSpot),'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Spot price')
  xlabel('Date')
  xlim([dates(1),dates(end)])
  ylim(ybars)
  set(gca,'FontSize',10)


  subplot(2,1,2)
  plot(dates,logSpot,'k-','linewidth',2,'color',colors(1,:))
  ybars = [2,8];

  hold on
  text(datenum(2006,1,1)+50,ybars(2)-diff(ybars).*0.06,'A')
  xlims = [datenum(2007,1,1),datenum(2009,1,1)];
  p1 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p1.EdgeColor = p1.FaceColor;
  p1.FaceAlpha = 0.5;
  text(xlims(1)+50,ybars(2)-diff(ybars).*0.06,'B')

  text(datenum(2009,1,1)+50,ybars(2)-diff(ybars).*0.06,'C')

  xlims = [datenum(2012,1,1),datenum(2015,1,1)];
  p2 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p2.EdgeColor = p2.FaceColor;
  p2.FaceAlpha = 0.5;
  
  text(datenum(2012,1,1)+50,ybars(2)-diff(ybars).*0.06,'D')
  text(datenum(2015,1,1)+50,ybars(2)-diff(ybars).*0.06,'E')

  xlims = [datenum(2017,1,1),datenum(2020,1,1)];
  p3 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p3.EdgeColor = p3.FaceColor;
  p3.FaceAlpha = 0.5;

  text(datenum(2017,1,1)+50,ybars(2)-diff(ybars).*0.06,'F')

  text(datenum(2020,1,1)+50,ybars(2)-diff(ybars).*0.06,'G')

  xlims = [datenum(2022,1,1),datenum(2023,4,1)];
  p4 = patch([min(xlims) max(xlims) max(xlims) min(xlims)], [ybars(1) ybars(1), ybars(2) ybars(2)], [0.6 0.6 0.6]);
  p4.EdgeColor = p4.FaceColor;
  p4.FaceAlpha = 0.5;

  text(datenum(2022,1,1)+50,ybars(2)-diff(ybars).*0.06,'H')

  plot(dates,logSpot,'k-','linewidth',2,'color',colors(1,:))
  datetick();
  title('Logarithm of the spot price')
  xlabel('Date')
  xlim([dates(1),dates(end)])
  ylim(ybars)
  set(gca,'FontSize',10)

end