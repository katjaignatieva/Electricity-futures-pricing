function [varargout] = datasetCalendar(calendar, varargin)
% Returns the varargin series modified to have the same (imposed) calendar.
%
% DATASETCALENDAR(...), given N series with distinct calendars, returns N
% series sampled at the provided CALENDAR. For each series, the calendar is
% assummed to be given by the first column named 'Date'. If the sampling
% contains dates that are not in a series calendar, NaN's are imputed.
%
% CALENDAR can be an array of dates, but can also be one of two strings:
% 'union' and 'intersection'. The appropriate calendar is then inferred
% from the inputs' calendars and used afterwards.
%  
% Elements of VARARGIN should be instances of the DATASET class and
% should have a 'Date' column for their first column.
%
% NOTE THAT NOW THAT MATLAB HAS ADDED A JOIN FUNCTION FOR DATASETS, THIS
% FUNCTION COULD (MAYBE) BE DEPRECATED OR RECODED MORE EFFICIENTLY USING THE
% SAID JOIN FUNCTION
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

  % Handle inputs
  aslist = (nargin == 2 && ~isa(varargin{1}, 'dataset'));
  if aslist % calendar + 1 list of series
    series = varargin{1};
  else
    series = varargin;
  end
  
  if ischar(calendar)
    if strcmp(calendar, 'union')
      calendar = uniteCalendar(series);
    elseif startswith(calendar, 'intersect')
      calendar = intersectCalendar(series);
    else
      error(['Unknown calendar string value: ', calendar]);
    end

  % Column calendar from row argument
  elseif size(calendar,1) == 1 
    calendar = calendar';
  end
  
  % Actually enforcing the calendar
  clen = length(calendar);
  for sno = 1:length(series)    
    S = series{sno};
    [m, subsample] = ismember(calendar, S.Date);
    subsample = subsample(subsample~=0);
    
    values = NaN(clen,size(S,2));
    values(:,1) = calendar;
    values(m,2:end) = double(S(subsample,2:end));
        
    varnames = get(S, 'VarNames');
    series{sno} = dataset({values, varnames{:}});
  end
  
  % Handle outputs
  if nargout == 1 && ~(nargin == 2 && isa(varargin{1}, 'dataset'))
    varargout{1} = series;
  else
    varargout = series;
  end
  
  
function calendar = uniteCalendar(series)
  calendar = series{1}.Date;
  for sno = 2:length(series)
    calendar = union(calendar, series{sno}.Date);
  end

  
function calendar = intersectCalendar(series)
  calendar = series{1}.Date;
  for sno = 2:length(series)
    calendar = intersect(calendar, series{sno}.Date);
  end
  
