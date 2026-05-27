function [stats,nberC] = statsNBER(calendar, vec, nberC)

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

  nonan = ~isnan(vec);  
  vec = vec(nonan);  
  if exist('nberC') == 1
    nberC = nberC(nonan);
  else
    calendar = calendar(nonan);
    nberC = inContractionNBER(calendar);  
  end
  
  n_obs = length(nberC);
  n_exp = sum(~nberC);
  n_rec = sum(nberC);
  assert( n_exp+n_rec == n_obs )
  
  stats = [ mean(vec(~nberC))  mean(vec)  mean(vec(nberC)); ...
    std(vec(~nberC))/sqrt(n_exp)  std(vec)/sqrt(n_obs)  std(vec(nberC))/sqrt(n_rec); ];
