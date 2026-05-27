function [summary] = summaryStats(mat, rmnan)
% Return summary statistics on a vector or on the columns of a matrix or dataset
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
  if isa(mat, 'dataset')
    colnames = get(mat,'VarNames');
    mat = double(mat);
  else
    % Assuming a matrix or a column vector below...
    if size(mat,1) == 1
      mat = mat';
    end    
    colnames = arraysprintf('col_%d', 1:size(mat,2));
  end
  
  % Actually computing the miscellaneous stats
  stats = { 'min', 'q1', 'mean', 'median', 'q3' 'max',...
            'std', 'var', 'skewness', 'kurtosis', 'meanabs', 'quadmean', 'negative', 'zerocount', 'positive'};

  snames = { 'Min', '25th Prct', 'Mean', 'Median', '75th Prct', 'Max',...
             'Std', 'Var', 'Skewness', 'Kurtosis', 'Mean |x|', 'sqrt(Mean x^2)', ...
             'Neg. Count', 'Zero Count', 'Pos. Count', 'NaN Count', 'N'};
  
  summary = NaN(length(snames), length(colnames));
  for col = 1:size(mat,2)
    nx = isnan(mat(:,col));
    vec = mat(~nx,col);
    
    for sno = 1:length(stats)
      func = str2func(stats{sno});
      if isempty(vec); func = @(vec) NaN; end; % All values in the column are NaN; make all stats NaN
      summary(sno,col) = func(vec);
    end
    summary(end-1,col) = sum(nx);
    summary(end,col) = length(nx);
  end
  summary = dataset({summary, colnames{:}}, 'ObsNames',snames);
end


function [n] = q1(mat)
  n = prctile(mat,25);
end

function [n] = q3(mat)
  n = prctile(mat,75);
end

function [n] = meanabs(mat)
  n = mean(abs(mat));
end

function [n] = nancount(mat)
  n = sum(isnan(mat));
end

function [n] = negative(mat)
  n = sum(mat < 0);
end

function [n] = positive(mat)
  n = sum(mat > 0);
end

function [n] = quadmean(mat)
  n = sqrt(mean(mat.^2));
end

function [n] = zerocount(mat)
  n = sum(mat == 0);
end

