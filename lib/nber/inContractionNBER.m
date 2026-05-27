function [is_in] = inContractionNBER(dates)

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

  is_in = zeros(size(dates));
  dates = serialdates(dates);
  nber = dataset('File','nber.csv', 'Delimiter',',');
  filter = yyyymmdd2serial(nber.Peak) >= dates(1) & yyyymmdd2serial(nber.Peak) <= dates(end);
  nber = nber(filter,:);
  if size(nber,1) == 0
    return;
  end
  
  peak_dates = yyyymmdd2serial(nber.Peak);
  trough_dates = yyyymmdd2serial(nber.Trough);
  for no = 1:length(peak_dates)
    is_in = is_in | (dates >= peak_dates(no) & dates <= trough_dates(no));
  end
  
  
