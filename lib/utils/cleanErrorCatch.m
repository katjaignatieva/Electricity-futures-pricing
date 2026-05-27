function [] = cleanErrorCatch(err, header)
% Implements standard report for fatal errors in parallel scripts.
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
  
  try
    display([header, ' reported below:'])
    if isfield(err, 'stack')
      names = {err.stack.name};
      lines = {err.stack.line};
      
      indent = '';
      slen = length(names);
      for s = slen:-1:1
        display([indent, ' In function ', names{s}, ...
                 ', line ', sprintf('%d', lines{s})])
        indent = [indent, '+'];
      end
    end      

    if length(err.identifier)
      display([err.identifier, ' --- ', err.message])
    else
      display(err.message)
    end      
  catch 
    uncaught = lasterror
  end
end
