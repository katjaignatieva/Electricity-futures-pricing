function tab = tabFuturesData()

load('data/FuturesPrices');

ix = FuturesPrices.DTM <= 91;

tab(1,1) = length(FuturesPrices.Price(ix));
tab(2,1) = mean(FuturesPrices.Price(ix));
tab(3,1) = std(FuturesPrices.Price(ix));
tab(4,1) = skewness(FuturesPrices.Price(ix));
tab(5,1) = kurtosis(FuturesPrices.Price(ix));
tab(6,1) = min(FuturesPrices.Price(ix));
tab(7:11,1) = quantile(FuturesPrices.Price(ix),[0.05,0.25,0.5,0.75,0.95]);
tab(12,1) = max(FuturesPrices.Price(ix));


ix = FuturesPrices.DTM <= 182 & FuturesPrices.DTM > 91;

tab(1,2) = length(FuturesPrices.Price(ix));
tab(2,2) = mean(FuturesPrices.Price(ix));
tab(3,2) = std(FuturesPrices.Price(ix));
tab(4,2) = skewness(FuturesPrices.Price(ix));
tab(5,2) = kurtosis(FuturesPrices.Price(ix));
tab(6,2) = min(FuturesPrices.Price(ix));
tab(7:11,2) = quantile(FuturesPrices.Price(ix),[0.05,0.25,0.5,0.75,0.95]);
tab(12,2) = max(FuturesPrices.Price(ix));


ix = FuturesPrices.DTM <= 273 & FuturesPrices.DTM > 182;

tab(1,3) = length(FuturesPrices.Price(ix));
tab(2,3) = mean(FuturesPrices.Price(ix));
tab(3,3) = std(FuturesPrices.Price(ix));
tab(4,3) = skewness(FuturesPrices.Price(ix));
tab(5,3) = kurtosis(FuturesPrices.Price(ix));
tab(6,3) = min(FuturesPrices.Price(ix));
tab(7:11,3) = quantile(FuturesPrices.Price(ix),[0.05,0.25,0.5,0.75,0.95]);
tab(12,3) = max(FuturesPrices.Price(ix));


ix = FuturesPrices.DTM <= 365 & FuturesPrices.DTM > 273;

tab(1,4) = length(FuturesPrices.Price(ix));
tab(2,4) = mean(FuturesPrices.Price(ix));
tab(3,4) = std(FuturesPrices.Price(ix));
tab(4,4) = skewness(FuturesPrices.Price(ix));
tab(5,4) = kurtosis(FuturesPrices.Price(ix));
tab(6,4) = min(FuturesPrices.Price(ix));
tab(7:11,4) = quantile(FuturesPrices.Price(ix),[0.05,0.25,0.5,0.75,0.95]);
tab(12,4) = max(FuturesPrices.Price(ix));

end