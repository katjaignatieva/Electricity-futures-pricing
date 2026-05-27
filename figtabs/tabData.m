function tab = tabData()

load('data/DailySpotPrices.mat');

tab(1,1) = mean(DailySpotPrices.Price);
tab(2,1) = std(DailySpotPrices.Price);
tab(3,1) = min(DailySpotPrices.Price);
tab(4:8,1) = quantile(DailySpotPrices.Price,[0.05,0.25,0.5,0.75,0.95]);
tab(9,1) = max(DailySpotPrices.Price);

tab(:,2) = log(tab(:,1));
tab(2,2) = std(log(DailySpotPrices.Price));

end