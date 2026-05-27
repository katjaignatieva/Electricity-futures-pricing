function [handles] = plotBackgroundNBER(dates, ylimits)
% This function add grey-shaded areas corresponding to NBER recessions in the
% background of a figure  

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

  if exist('ylimits') ~= 1
    ylimits = ylim();
  end
  
  hold on;
  dates = serialdates(dates);  
  nber = dataset('File','nber.csv', 'Delimiter',',');
  filter = yyyymmdd2serial(nber.Peak) >= dates(1) & yyyymmdd2serial(nber.Peak) <= dates(end);
  nber = nber(filter,:);
  if size(nber,1) == 0
    handles = -1;
    return;
  end
  
  peak_dates = yyyymmdd2serial(nber.Peak);
  trough_dates = yyyymmdd2serial(nber.Trough);
  trough_dates(end) = min(trough_dates(end), dates(end));  
  contractions = [peak_dates, trough_dates];
  contractions = [contractions, contractions(:,2:-1:1)];

  % Get handles to the graphic items currently plotted on the figure
  foreground = get(gca,'Children');
  
  ylimits = [ylimits(1)  ylimits(1)  ylimits(2)  ylimits(2)];
  handles = fill(contractions, ylimits, [0.8,0.8,0.8], 'EdgeColor', 'none'); 

  % Send the grey rectangles to the background
  set(gca,'Children',[foreground; handles]);
  xlim(dates([1,end]));
  
