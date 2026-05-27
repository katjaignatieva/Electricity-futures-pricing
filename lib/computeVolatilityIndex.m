function [ds,Range] = computeVolatilityIndex(options, DTM)
% This function computes the implied volatility (VIX and SVIX style) for a specific date. OPTIONS is
% the dataset containing the relevant information to do the computation:
% DTM (days to maturity), Implied volatility, Strike Price, Option
% price, forward price, and call or put.
%
% Input arguments: 'options' is the dataset of the options, while DTM
% is the number of days for the implied volatility calculation.
%
% The computation follows as much as possible the calculation of the VIX,
% but uses days instead of minutes.

% Authors: Olivier Chassé St-Laurent (2013, 2016)
%          Christian Dorion (2014, 2015)

% Eliminate the dates on which an option-implied forward price couldn't be computed
options = options(~isnan(options.ImpliedForwardPrice), :);

% http://www.cboe.com/strategies/vix/indexintro/part2.aspx
% "The calculation of the VIX index uses two series of SPX option contracts - the
% front month and the second month - as long as the front month has at least
% one week until expiration."
options = options(options.DTM >= 7, :);

% Get the unique dates
Date = unique(options.Date);

% Preallocate a vector for the expected volatility
ImpliedVol = NaN(length(Date),1);
ImpliedSVol = NaN(length(Date),1);
Range = [NaN, NaN; NaN, NaN];

% Stock the two maturities used at each point in time.
maturities = NaN(length(Date),2);

MIN_NOBS = 3; % 3 calls, 3 puts

% Proceed to compute the expected (implied) volatility at each time step
for i = 1:length(Date) % Use for rather than parfor when debugging
  %% for i = 1:length(Date);
  try
    % Get the options for that date, the maturities available and the
    % previous and next maturities
    dx = options.Date == Date(i);
    DTM1 = max(options.DTM(dx & options.DTM <= DTM));
    if isequal(DTM1, DTM) % Exact maturity match
      DTM2 = [];
    else
      DTM2 = min(options.DTM(dx & options.DTM > DTM));
    end
    empty = [isempty(DTM1), isempty(DTM2)];
    if all(empty);  continue;  end; % Not enough options
    
    dtms = NaN(1,2);
    dtms(~empty) = [DTM1 DTM2];
    
    Tvar = [0, 0];
    Tsvar = [0, 0];
    for dn = 1:2
      if empty(dn); continue; end; % Skip the empty dataset
      ix = dx & options.DTM == dtms(dn);
      Nc = sum(options.isCall(ix));
      Np = sum(~options.isCall(ix));
      if Nc < MIN_NOBS || Np < MIN_NOBS % If not enough, treat as empty
        dtms(dn) = NaN;
      else
        [opt, F, K, ~, ran] = buildtempds(options(ix, :));
        Range(dn,:) = ran;
        
        % T * \sigma^2
        Tvar(dn)  = 2 * sum(exp(opt.RiskFree .* opt.YTM) .* opt.OptionPrice .* opt.dK ./ opt.Strike.^2) ...
          -  (F./K - 1).^2;
        Tsvar(dn) = 2 * sum(exp(opt.RiskFree .* opt.YTM) .* opt.OptionPrice .* opt.dK ./ F.^2);
      end
    end
    
    var0 = NaN; % Will remain if n_mat == 0
    svar0 = NaN; % Will remain if n_mat == 0
    n_mat = sum(~isnan(dtms));
    if n_mat == 1
      vx = Tvar ~= 0; % One of the two entries is zero
      var0 = Tvar(vx) * 365 / dtms(vx);   % Scale using the appropriate
      svar0 = Tsvar(vx) * 365 / dtms(vx); %  DTMx, not the expected DTM
    elseif n_mat == 2
      DD = DTM2 - DTM1;
      var0 = (Tvar(1)*(DTM2-DTM)/DD + Tvar(2)*(DTM-DTM1)/DD) * (365/DTM);
      svar0 = (Tsvar(1)*(DTM2-DTM)/DD + Tsvar(2)*(DTM-DTM1)/DD) * (365/DTM);
    end
    ImpliedVol(i) = 100 * sqrt(var0);
    ImpliedSVol(i) = 100 * sqrt(svar0);
    maturities(i,:) = dtms;
    
    Range = nanmean(Range);
    
  catch
    Date(i)
  end
end

% Build the dataset; eliminate those dates on which we get an imaginary
% part (usually means the sample of option prices was insufficient; two
% dates for DTM = 30, as of 2013/03/02)
ds = dataset(Date, ImpliedVol, ImpliedSVol);
ds.ImpliedVol(imag(ds.ImpliedVol) ~= 0) = NaN;
ds.ImpliedSVol(imag(ds.ImpliedSVol) ~= 0) = NaN;
ds.DTM1 = maturities(:,1);
ds.DTM2 = maturities(:,2);
end


%% This function is used to build the temporary datasets to compute the implied volatility
function [ds, F, K, T, Range] = buildtempds(options)
% Find K, the first strike price the forward price
F = unique(options.ImpliedForwardPrice); assert( numel(F) == 1 );
T = unique(options.YTM);                 assert( numel(T) == 1 );
K = max(options.Strike(options.Strike < F));

% Build two temporary datasets to store the calls and puts
callds = options(options.isCall == 1, :);
putds = options(~options.isCall, :);

% Sort the datasets, then compute dK for each options; deal separately with
% the first and last
callds = sortrows(callds, 'Strike');
putds = sortrows(putds, 'Strike');

% Find the options with 0 bids; also eliminate all the other following (call) or
% preceding (put) two 0 bids
ixcall = callds.OptionBid == 0;
ixput = putds.OptionBid == 0;

if sum(ixcall) <= 2 % Need only eliminate the 0 bids
  callds = callds(~ixcall, :);
else
  % Find the second 0 bid, and eliminate the subsequent options
  ind = find(ixcall, 2, 'first');
  ixcall(ind(2):end) = true;
  callds = callds(~ixcall, :);
end

% Repeat the process for the put options
if sum(ixput) <= 2
  putds = putds(~ixput, :);
else
  ind = find(ixput, 2, 'last');
  ixput(1:ind(1)) = true;
  putds = putds(~ixput, :);
end

function [dK] = getdK(strike)
  if length(strike) < 3
    dK = NaN * strike;
  else
    dK = [ strike(2) - strike(1);
      (strike(3:end) - strike(1:end-2)) ./ 2;
      strike(end) - strike(end-1) ];
  end
end
callds.dK = getdK(callds.Strike);
putds.dK = getdK(putds.Strike);

% Build a dataset consisting of the remaining OTM options, as well as the
% average of the two ATM options; check whether there are both ATM options
indcall = find(callds.Strike == K);
indput = find(putds.Strike == K);

if numel(indcall) > 1
  indcall = indcall(~strncmp(callds.Root(indcall),'JX',2));
end
if numel(indput) > 1
  indput = indput(~strncmp(putds.Root(indput),'JX',2));
end

if ~isempty(indcall)
  ds = callds(indcall, :);
  ds.OptionPrice(1) = mean([callds.OptionPrice(indcall), putds.OptionPrice(indput)]);
else
  ds = putds(indput, :);
end

ds = vertcat(ds, callds(callds.Strike > K, :), putds(putds.Strike < K, :));

ATMBSIV = mean(ds.ImpliedVolOM(ds.Strike == K));

M = log(ds.Strike./ds.StockPrice)./(ATMBSIV.*sqrt(ds.YTM));

Range = [min(M), max(M)];

end


