function [DM,gammad,k]=dmtest(delta, k);
% Diebold-Mariano test comparing predictive accuracy
% 
% DELTA the sequence of loss differences 
% K     the maximum lag order (uses simple rectangular window)
%
% Copyright (C) 2008 by Christian Dorion (based on a file provided by Peter Christoffersen and Kris Jacobs)
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

  % If k is not provided, we will later use PARCORR 
  if nargin==1; k = -100; end;

  % If delta is a matrix, run tests on the columns
  if ~isvector(delta)
    DM = arrayfun(@(cn) dmtest(delta(:,cn), k), 1:size(delta,2));    
    return
  end

  % Slightly hacking management of limit cases
  if all(delta)==0
    DM = 0.0;
    return;
  end      

  assert(isvector(delta))
  n=length(delta);
  
  if k < 0
    k_max = min(abs(k), n-1);
    % Find the first partial autocorrelation that is within confidence bounds
    [P,L,B] = parcorr(delta,k_max);
    ix = find(abs(P) < B(1), 1, 'first');
    k = L(ix) - 1; % Keep the last "significant" partial autocorrelation
  end
  
  if 2*k+1 > n
    k = floor( (n-1)/2 );
    warning('The number of observations (%d) restricts k to %d.', n, k);
  end
  
  dbar = mean(delta);

  j=1;
  gammad = zeros(2*k+1, 1);
  for i = -k:1:k
    gammad(j,1) = mean((delta(1+abs(i):n)-dbar).*(delta(1:n-abs(i))-dbar));
    j=j+1;
  end
  
  DM = dbar / sqrt(sum(gammad)/n);
  if ~isreal(DM); DM = NaN; end
