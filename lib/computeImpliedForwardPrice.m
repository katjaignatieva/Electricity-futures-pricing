function [forward, exdiv, impdiv, errors] = computeImpliedForwardPrice(options)
% Extract the option-implied forward price
%
% Author: Christian Dorion
  forward = NaN(size(options.Date));
  exdiv   = NaN(size(options.Date));
  impdiv  = NaN(size(options.Date));

  % First date by date
  Nobs = length(options.Date);
  obsx = (1:Nobs)'; 
  col1 = ones(Nobs,1);

  dates = unique(options.Date);
  M = length(dates);
  fwdytm = cell(M); 
  fwdval = cell(M); 
%   gcp();
  for dn = 1:M
    dx = options.Date==dates(dn);
    
    % Then maturity per maturity
    ytm = unique(options.YTM(dx));
    
    N = length(ytm);
    fwdytm{dn} = NaN(N,1);
    fwdval{dn} = NaN(N,1);
    for mn = 1:N
      % Select the cross section of puts and calls with the same exp date
      mx = dx & options.YTM==ytm(mn);
      put = options(mx & ~options.isCall, :);
      call = options(mx & options.isCall, :);
                 
      % Choose the ATM pair
      ATM = [];
      DEL = Inf;
      for kn = 1:length(put.Strike)
        ix = find(call.Strike==put.Strike(kn));
        if length(ix)==1
          spread = abs(call.OptionPrice(ix) - put.OptionPrice(kn));
          if spread < DEL
            DEL = spread;
            ATM.put = put(kn,:);
            ATM.call = call(ix,:);
          end
        end        
        
        if length(ix) > 1 % Database error!
          warning('#####  Database error!  #####')
          call(ix,:)
        end
      end % for kn
        
      if isempty(ATM)
        continue; % Leave the forward price to NaN
      end
                      
      % Compute the implied forward price
      % Put-call parity:     S - D - K e^{-rT} = c - p
      %                  <=> F = K + e^{+rT} (c - p)
      fwdytm{dn}(mn) = ytm(mn);
      fwdval{dn}(mn) = ATM.put.Strike + exp(ATM.put.RiskFree*ATM.put.YTM) * (ATM.call.OptionPrice - ATM.put.OptionPrice);
    end % for mn     
  end % for dn
  
  % Aggregate results from workers
  for dn = 1:M
    N = length(fwdval{dn});
    for mn = 1:N
      forward( options.Date==dates(dn) & options.YTM==fwdytm{dn}(mn) ) = fwdval{dn}(mn);
    end  
  end
  
  % The forward price is e^{rT}(S - D) or e^{rT} * e^{-qT}S
  exdiv = exp(-options.RiskFree.*options.YTM) .* forward;
  impdiv = log(options.StockPrice ./ exdiv) ./ options.YTM; % q in the above
