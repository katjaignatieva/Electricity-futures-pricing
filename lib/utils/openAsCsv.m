function [fname] = openAsCsv(mat, cmd)
% Open an XLS file containing the entries of MAT.
%
% This command works well under Mac OS since it simply uses the Mac's 'open'
% command. Under Windows, it's behavior must be modified using the CMD argument.  
%  
% Copyright (C) 2013,2015 by Christian Dorion
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
  if nargin==1
    cmd = 'open';
  end
  fname = [tempname '.csv'];
  if isreal(mat)
    csvwrite(fname, mat); 
  elseif iscell(mat)
    mat = cellfun(@(el) char(el), mat, 'UniformOutput',false);
    mat = arrayfun(@(r) [sprintf('%s, ',mat{r,1:end-1}) mat{r,end}], (1:size(mat,1))', 'UniformOutput',false);
    mat = sprintf('%s\n',mat{:});
    fid = fopen(fname, 'w');
    fprintf(fid, mat);
    fclose(fid);
  elseif strcmp(class(mat),'dataset')
    export(mat, 'File',fname, 'Delim',',');
  elseif strcmp(class(mat),'table')
    % Weirdly enough, row names are not quoted even with QuoteStrings true...
    row_names = mat.Properties.RowNames;
    row_names = cellfun(@(s) sprintf('"%s"',s), row_names, 'UniformOutput',false);
    mat.Properties.RowNames = row_names;
    writetable(mat, fname, 'Delimiter',',', 'WriteRowNames',true, 'QuoteStrings',true);
  end
  system([cmd ' ' fname]);
  
  if nargout==0; clear fname; end;
  
