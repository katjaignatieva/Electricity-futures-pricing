function [varargout] = datasetZeroHold(varargin)
% Performs zero-hold missing imputation on the series provided.
%
% DATASETZEROHOLD(VARARGIN) receives a single cell array of or a list of
% DATASET instances on which it performs zero-hold missing
% imputation. That is, for each column of each dataset, missing
% observations are replaced by the last non-missing observation, if
% any. For each dataset, the leading rows consisting of missing values
% for *all* columns will be removed.
%    
% Copyright (C) 2010-2013 by Christian Dorion
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
  
  [varargin,options] = parseZHOptions(varargin);
  aslist = (length(varargin)==1 && ~isa(varargin{1}, 'dataset'));
  if aslist % calendar + 1 list of series
    series = varargin{1};
  else
    series = varargin;
  end

  for sno = 1:length(series)
    data = series{sno};
    
    % Updating one column at a time
    varnames = setdiff(get(data, 'VarNames'), 'Date');
    for col = 1:length(varnames)
      column = getfield(data, varnames{col});
      [column, first(col)] = zeroHoldCore(column);
      data = setfield(data, varnames{col}, column);
    end

    % Truncation of the leading rows consisting of missing values for *all*
    % columns.
    first = min(first);
    if first > 1 && options.truncate
      data = data(first:end, :);
    end
    series{sno} = data;
  end
    
  % Handle outputs
  if nargout == 1 && ~(length(varargin) == 1 && isa(varargin{1}, 'dataset'))
    varargout{1} = series;
  else
    varargout = series;
  end
    

%%#####  Helper Functions  ####################################################

function [args,options] = parseZHOptions(args)
  ex = [];
  options = struct('truncate',true);
  for no = 1:length(args)
    if isstr(args{no}) && startswith(args{no}, '--')
      ex = [ex no no+1];
      options.(args{no}(3:end)) = args{no+1};      
    end
  end
  args(ex) = [];
  
  
function [data, first] = zeroHoldCore(data)
% Zero-hold missing observations in DATA
  % Locate missing values
  missing = isnan(data);
  if sum(missing) == 0
    % No missing
    first = 1;  
    return;
  end
  
  % Convert booleans into indices
  rng = 1:length(data);
  first = find(missing == 0, 1, 'first');
  indices = rng(missing);
  if indices(1) == 1
     % Leave NaNs until first valid observation
    indices = indices(2:end);
  end
  
  % And perform zero hold on missing info. The for-loop is unfortunately
  % necessary here... The vectorial approach would not be robust to
  % streaks of missing observations.
  for ind = indices
    data(ind) = data(ind-1);
  end

