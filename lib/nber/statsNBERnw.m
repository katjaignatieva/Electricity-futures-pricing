function [stats,nber] = statsNBERnw(calendar, series, nber)

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

  nonan = ~isnan(series);  
  series = series(nonan);  
  if exist('nber') == 1
    nber = nber(nonan);
  else
    calendar = calendar(nonan);
    nber = inContractionNBER(calendar);  
  end
  
  n_obs = length(nber);
  n_exp = sum(~nber);
  n_rec = sum(nber);
  assert( n_exp+n_rec == n_obs )
  
  
  iota = ones(size(calendar));

  exp = nwest(series(~nber), iota(~nber));
  rec = nwest(series(nber), iota(nber));
  dif = nwest(series, [iota nber-nanmean(nber)]);
  
  stats = [ exp.beta,  dif.beta(1),  rec.beta,  dif.beta(2); ...
            exp.tstat, dif.tstat(1), rec.tstat, dif.tstat(2) ];
  
  stats = dataset({stats,'Exp','Avg','Rec','Rec_Exp'}, 'ObsNames',{'Avg','tStat'});
  
