function [dates] = serialdates(dates)
% This function ensure that DATES are in Matlab's serial format;
% distinguishing between serial and yyyymmdd dates.
%
% If DATES are already in serial format, they are returned as is;
% otherwise the YYYYMMDD2SERIAL function is called and its result
% returned. This function is subject to a year 3k bug ;) 
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
  dx = ~isnan(dates);
  if all( dates(dx) > datenum(3000,1,1) )
    dates = yyyymmdd2serial(dates);
  end
  
