function [lag] = lagts(ts, delta)  
% LAGTS lags the *column* timeseries TS of DELTA timesteps.
%
% DELTA defaults to +1.  
% Note that DELTA can be negative ==> lead. E.g:
%  
%              Lagged series
%     __________________________________
%     Index      DELTA = +1   DELTA = -1 
%       1           NaN         TS(2)
%       2          TS(1)        TS(3)
%       3          TS(2)        TS(4)
%       4          TS(3)        TS(5)
%       5          TS(4)         NaN
%
% NOTE -- Consider FILTER([0,1], 1, ts, NaN) for LAGTS(ts,1)
%
% Copyright (C) 2013 by Christian Dorion
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
  
  if nargin < 2
    delta = 1;
  end
  if length(delta) > 1
    func = @(D) lagts(ts,D);
    lag = cell2mat( arrayfun(func, delta, 'UniformOutput',false) );
    return;
  end
  
  [m,n] = size(ts);
  fix = NaN*ones(abs(delta),n);  
  if delta > 0
    lag = [ fix; ts(1:end-delta,:) ];
  elseif delta < 0
    delta = -delta;
    lag = [ ts(delta+1:end,:); fix ];
  else
    lag = ts;
  end       

