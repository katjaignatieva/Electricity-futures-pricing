function [z] = nanzscore(x)
% Return zscores for X, using nanmean and nanstd rather than their non-nan counterparts
% 
% Modified from Matlab's builtin zscore function
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
  
  % [] is a special case for std and mean, just handle it out here.
  if isequal(x,[]), z = []; return; end

  % Compute X's mean and sd, and standardize it
  mu = nanmean(x);
  sigma = nanstd(x);
  sigma0 = sigma;
  sigma0(sigma0==0) = 1;
  z = bsxfun(@minus, x, mu);
  z = bsxfun(@rdivide, z, sigma0);
