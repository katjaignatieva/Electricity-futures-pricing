function textprogressbar(it, message)
% This function creates a text progress bar. It should be called with a 
% STRING argument to initialize and terminate. Otherwise the number correspoding 
% to progress in % should be supplied.
% INPUTS:   IT   If MESSAGE is provided, this is the number of iterations
%                Otherwise, the current iteration
%           MESSAGE The message introducing the textbar
%
% OUTPUTS:  N/A
%  
% Example: Call 

% Author: Paul Proteus (2010), Christian Dorion (2012) 
% See textprogressbar.m.original
  if ischar(it) && strcmp(it, 'RUN DEMO')
    ITMAX = 72;
    textprogressbar(ITMAX, 'DEMO: ');
    for i=1:ITMAX,
      textprogressbar(i);
      pause(0.1);
    end
    return;
  end

  %% Initialization
  persistent strCR itMAX; % Carriage return and number of iterations pesistent variables

  % Vizualization parameters
  strPercentageLength = 10;   %   Length of percentage string (must be >5)
  strDotsMaximum      = 10;   %   The total number of dots in a progress bar

  %% Main 
  if isempty(strCR) && nargin < 2
    % Progress bar must be initialized with a string
    error('The text progress must be initialized with the number of iterations and a message')
  end

  if ~isempty(strCR) && nargin == 2
    % Progress bar must be initialized with a string
    warning('The previous text progress wasn''t terminated');
    strCR = [];
  end
  
  if nargin == 2
    % Progress bar - initialization
    fprintf('%s',message);
    strCR = -1;
    itMAX = it;
    
  elseif isnumeric(it)
    c = 100*it/itMAX;
    
    % Progress bar - normal progress
    c = floor(c);
    percentageOut = [num2str(c) '%%'];
    percentageOut = [percentageOut repmat(' ',1,strPercentageLength-length(percentageOut)-1)];
    nDots = floor(c/100*strDotsMaximum);
    dotOut = ['[' repmat('.',1,nDots) repmat(' ',1,strDotsMaximum-nDots) ']'];
    strOut = [percentageOut dotOut];
    
    % Print it on the screen
    if strCR == -1,
      % Don't do carriage return during first run
      fprintf(strOut);
    else
      % Do it during all the other runs
      fprintf([strCR strOut]);
    end
    
    % Update carriage return
    if it==itMAX
      % Progress bar termination
      strCR = [];  
      fprintf('\n');    
    else
      strCR = repmat('\b',1,length(strOut)-1);
    end
  else
    % Any other unexpected input
    error('Unsupported argument type');
  end


function demo_textprogressbar()
%This a demo for textprogressbar script
  textprogressbar('calculating outputs: ');
  for i=1:100,
    textprogressbar(i);
    pause(0.1);
  end
  textprogressbar('done');


  textprogressbar('saving data:         ');
  for i=1:0.5:80,
    textprogressbar(i);
    pause(0.05);
  end
  textprogressbar('terminated');
