function [ix,wdays] = sampleWeekday(dates, wd, wlen)
% Each week, select the date in DATES for which the weekday is closest to WD and return
% the indices of the selected dates in DATES.
% 
% If an exact match was wanted, this code would do it:
%   ix = find(weekday(dates)==wday);
% 
% This function returns the weekly closest match. A week is considered valid
% if it has at least WLEN days in DATES.
%   
% Copyright (C) 2014 by Christian Dorion
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
  mdates = serialdates( unique(dates) );
  assert(length(mdates) == length(dates), 'DATES must contain unique dates')
  assert(isequal(mdates, serialdates(dates)), 'DATES must be sorted')
  dates = mdates; clear mdates
  
  % Note that the first and last week will have to be treated with care
  wdays = weekday(dates);
  weekend = wdays(2:end) < wdays(1:end-1);
  weekend(end+1) = ~weekend(end); % Don't put to consecutive end of weeks

  % Indices of the last day of each week
  endx = (1:length(dates))';
  endx = endx(weekend);
  wstart = 1;

  Nw = length(endx);
  ix = NaN(Nw,1);
  for wn = 1:Nw
    wds = wdays(wstart:endx(wn));
    if length(wds) >= wlen % Ensure min week length
      [~,mx] = min(abs(wd - wds));
      ix(wn) = wstart+mx-1; 
    end
    wstart = endx(wn)+1; % Proceed to next week
  end
  ix(isnan(ix)) = [];  
  
