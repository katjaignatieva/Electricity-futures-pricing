function [ax,h1,h2] = plotyyNBER(cal, lhs, rhs, lhlabel, rhlabel)
% The builtin plotyy function is really bad when you need axes to be
% tight. This is the best I can do so far...
%
% UNSTABLE: This function might change a lot; keep a local version in each
% projects if stability is needed.

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

  % Computes the ylims based on the rhs series. On the left-hand side, rhs
  % will be plotted (but invisible) with a scaling factor
  YL = [min(rhs), max(rhs)];
  S = 1/YL(2);

  % Plot the background and set the xlimits here, *after* setting x-ticks to date-ticks
  plotBackgroundNBER(cal, YL); 
  datetick('x',11); 
  xlim(cal([1,end]));

  % Call the builtin plotyy
  [ax,h1,h2] = plotyy(cal, [lhs S*rhs], cal, rhs);
  set(h1(2), 'Visible','Off'); % don't display the scaled rhs on the lhs
  set(ax(1),'Box','Off');      % remove y2 ticks from the left side
  set(ax(2),'Box','Off');      % remove y1 ticks from the right side
  set(ax(2), 'XTick',[],...    % make sure the top axis doesn't have ticks
             'XAxisLocation','top','linewidth',1) % cover the top of the box manually

  % Set the xlabel to Date (can be changed out of this function if needed)
  xlabel('Date');             
  
  % Set the limits of the x-axis to the same values for both axes
  xlim(ax(1),cal([1,end]));
  xlim(ax(2),cal([1,end]));

  % Set the limits of the y-axis to the "same" values for both axes
  % (accounting for the scaling on the LHS)
  ylim(ax(1), S*YL);
  ylim(ax(2), YL);

  if nargin > 3
    axes(ax(1))
    ylabel(lhlabel)
  end
  if nargin > 4
    axes(ax(2))
    ylabel(rhlabel)
  end
