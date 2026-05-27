function name = getComputerName()
% GETCOMPUTERNAME returns the name of the computer (hostname)
% name = getComputerName()
%
% WARN: output string is converted to lower case
%
%
% See also SYSTEM, GETENV, ISPC, ISUNIX
%
%
% Modified from the version published 19 Sep 2007 (Updated 21 Sep 2007) at:
% http://www.mathworks.com/matlabcentral/fileexchange/16450-get-computer-namehostname
% m j m a r i n j (AT) y a h o o (DOT) e s
% (c) MJMJ/2007
%

[ret, name] = system('hostname');   

if ret ~= 0,
   if ispc
      name = getenv('COMPUTERNAME');
   else      
      name = getenv('HOSTNAME');      
   end
end

% Remove the possible newline character at the end of the string
name = lower(name(name ~= 10));

