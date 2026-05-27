function [serial] = yyyymmdd2serial(yyyymmdd)
% YYYYMMDD2SERIAL(YYYYMMDD) converts integer dates to the Matlab format.
%   @param   YYYYMMDD should be a sequence of integer dates.
%   @returns SERIAL will list the corresponding dates, in the Matlab serial format.
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

  yyyymmdd = double(yyyymmdd); % To avoid problems with int32...
  
  dd     = mod(yyyymmdd, 100);
  yyyymm = (yyyymmdd - dd)./100;
  
  mm     = mod(yyyymm, 100);
  yyyy   = (yyyymm - mm)./100;

  serial = datenum(yyyy,mm,dd);
