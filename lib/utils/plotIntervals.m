function [h,fh] = plotIntervals(xvalues, lower, middle, upper, color, alpha)
% [H,FH] = PLOTINTERVALS(XVALUES, LOWER, MIDDLE, UPPER, COLOR, ALPHA)
%
% Plots a solid line MIDDLE against XVALUES and fills the area between LOWER
% and UPPER. COLOR (defaults to 'k') can be any valid color specification,
% but can also be a cell containing two colors: the first for the line, the
% second for the fill. The ALPHA value (defaults to 0.75) is forwarded to
% Matlab's FILL function.
%
% Copyright (C) 2008-2013 by Christian Dorion
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
  xvalues = xvalues(:);
  lower   = lower(:);
  middle  = middle(:);
  upper   = upper(:);
  if exist('color')~=1;  color = 'k';   end;
  if exist('alpha')~=1;  alpha = 0.75;  end;
  
  if iscell(color)
    ch = color{1};  cfh = color{2};
  else
    ch = color;  cfh = color;
  end
  
  foreground = get(gca,'Children');
  
  h = [];
  hold on;  
  if middle
    h = plot(xvalues, middle);
    set(h, 'Color', ch)
  end
  
  vflip = @(vec) vec(end:-1:1);
  fh = fill([xvalues; vflip(xvalues)], [upper; vflip(lower)], ...
            cfh, 'FaceAlpha', alpha, 'EdgeColor', 'none'); 
  
  set(gca,'Children',[foreground; h; fh]);
