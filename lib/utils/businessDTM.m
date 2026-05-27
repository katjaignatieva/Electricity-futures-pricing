function bDTM = businessDTM(dates,expdates); 
% bDTM = businessDTM(dates,expdates); 
% Return business days to maturity
% 
% We here assume that observations are at the end of each
% DATES(n), hence the DATES are *NOT* counted in bDTM.
%
% DATES and EXPDATES must be serial dates
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

  bDTM = NaN(size(dates));
  for dno = 1:length(dates)
    today = dates(dno);
    bDTM(dno) = length( setdiff(busdays(today, expdates(dno)),today) );
  end
