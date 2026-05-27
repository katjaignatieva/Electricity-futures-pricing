function [data] = datasetLoad(filename, formats, dlm)
% FILENAME  the name of the file to read
% FORMATS  a cell of size Nx2 with, on each row, a mapping from a potential
%          header to the format of the column, see
%          http://www.mathworks.com/help/matlab/ref/sprintf.html#inputarg_formatSpec
% DLM  the 'Delimiter' used by the dataset
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
  if exist('dlm')~=1;  dlm = ',';  end;

  % Load headers (first row)
  fid = fopen(filename, 'r'); headers = fgetl(fid); fclose(fid);

  % Convert the headers to formats 
  % http://www.mathworks.com/help/matlab/ref/sprintf.html#inputarg_formatSpec
  entries = regexp(headers, dlm, 'split');
  if exist('formats')==1 && ~isempty(formats)
    if isstr(formats)
      fmt = formats;
    else
      ix = cellfun(@(str) strmatch(str, {formats{1:end,1}}, 'exact'), entries);    
      fmt = strcat({ formats{ix,2} }, {' '});
      fmt = [ fmt{:} ];   
      fmt = fmt(1:end-1);  
    end
  else
    fmt = repmat('%s',1,length(entries));
  end
  
  data  = dataset('File',filename, 'Format',fmt, 'Delimiter',dlm); 
  
