function [] = struct2vars(variables)
% struct2vars(variables) loops over the fields in VARIABLES and assign each
% of them to actual variables in the caller's environment.
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
  fnames = fieldnames(variables);
  for fno = 1:length(fnames)
    field = fnames{fno};
    value = getfield(variables, field);
    assignin('caller', field, value);
  end  
  
