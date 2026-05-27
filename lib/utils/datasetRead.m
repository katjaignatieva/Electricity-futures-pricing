function [dset] = datasetRead(filename, dlm)
% Read a dataset for FILENAME with delimiters DLM (default=','). For some
% datasets, this function is faster and more robust than the actual dataset
% class' constructor.
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

  fid = fopen(filename, 'r');
  if fid <= 0
      error('Cannot open filename "%s" for reading', filename);
  end
  read_obsnames = false;

  fline = fgetl(fid);  
  if startswith(fline,'id')  
    read_obsnames = true;
    fline = fline(4:end);
  end
  obsnames = {};
  headers = regexp(fline, dlm, 'split');
  data = NaN(0,length(headers));

  row = 0;
  fline = fgetl(fid);
  while fline ~= -1
    row = row + 1;
    fline = regexp(fline, dlm, 'split');
    if read_obsnames
      obsnames{row,1} = fline{1};
      fline = { fline{2:end} };
    end
    data(row,:) = cellfun(@Str2Num, fline);
    
    % Read next line    
    fline = fgetl(fid);    
  end

  dset = dataset({data,headers{:}});
  if read_obsnames
    dset = set(dset,'ObsNames',obsnames);
  end
  fclose(fid);
  
  
function [num] = Str2Num(str)
  if strcmp(str,'NA') || isempty(deblank(str))
    num = NaN;
  else
    num = str2num(str);
  end
