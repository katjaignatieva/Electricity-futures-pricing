function [default,overrides] = setfields(default, overrides, extend)  
% Update a structure DEFAULT using OVERRIDES 
% 
% OVERRIDES can be a structure, or a cell array containing 'name',value pairs
% EXTEND    is false by default. When true, if a field appears in OVERRIDES but
%           not in DEFAULT, it is added to DEFAULT. When false, an unexpected field
%           raises an error. EXTEND can also be set to 'neglect'; no error is
%           issued, but no field is added to DEFAULT.
%
% Copyright (C) 2012-2014 by Christian Dorion
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
  if ~isstruct(overrides)
    overrides = parseOverrides(overrides);
  end
  neglect = false;
  if exist('extend')~=1; extend = false; end
  if isstr(extend) && strcmp(extend,'neglect')
    extend = false;
    neglect = true;
  end
  
  fnames = fieldnames(overrides);
  for fno = 1:length(fnames)
    field = fnames{fno};
    value = getfield(overrides, field);
    if extend || isfield(default, field)
      default = setfield(default, field, value);
    elseif ~neglect 
      error(['Unexpected field name: ', field]);
    end
  end  
  

function [overrides] = parseOverrides(pairs)
  overrides = struct();
  
  no = 1;
  nvalues = length(pairs);
  while no <= nvalues
    optname = pairs{no};
    if ischar(optname) && no < nvalues
      overrides = setfield(overrides, optname, pairs{no+1});
      no = no+1;
    else
      fprintf('pairs: '); disp(pairs);
      fprintf('pairs{%d}: ', no); disp(pairs{no});
      error('Unexpected ''name'',value pair format at %d', no);
    end
    no = no+1;
  end 

  
