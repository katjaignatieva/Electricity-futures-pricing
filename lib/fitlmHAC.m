function [regr, results, resultswse] = fitlmHAC(XY, specs, row_names, reg_name, nwest)
  if ~exist('nwest','var'); nwest = false; end;

  if isa(specs,'char')
    if ~exist('reg_name','var') || isempty(reg_name); reg_name = 'Regression'; end;
    [regr, results, resultswse] = regress(XY, specs, row_names, reg_name, nwest);
    
  elseif isa(specs,'struct')
    regr = struct();
    results = table();
    resultswse = table();
    specnames = fieldnames(specs);
    for sn = 1:length(specnames)
      sname = specnames{sn};
      [regr.(sname), res, resw] = regress(XY,specs.(sname),row_names,sname,nwest);
      results = [results res];
      resultswse = [resultswse resw];
    end
  end
    
  
function [regr, results, resultswse] = regress(XY, spec, row_names, reg_name, nwest)
  regr = fitlm(XY, spec);

  if nwest
    T = size(XY,1);
    lag = floor(4*(T/100)^(2/9));
    [EstCov,se,coeff] = hac(regr, 'bandwidth',lag+1, 'Display','off');    
%     lag = floor(4*(T/100)^0.25)
%     [EstCov,se,coeff] = hac(regr, 'bandwidth',lag, 'Display','off');    
  else
    % HAC Std errors & t-stats
    [EstCov,se,coeff] = hac(regr, 'Display','full','weights','QS');    
  end
  tstats = coeff./se;
    
  se_row_names = {};
  for rn = 1:length(row_names)
    se_row_names{end+1} = row_names{rn};
    se_row_names{end+1} = [row_names{rn} '-t'];
  end
  
  cx = 1:2:length(se_row_names);
  tx = 2:2:length(se_row_names);  
  sub = ismember(row_names, regr.Coefficients.Properties.RowNames);  
  if strncmp(regr.Coefficients.Properties.RowNames(end),'ROV',3)
    sub = sub + strcmp(row_names,'ROV');
  end
  if any(strcmp(regr.Coefficients.Properties.RowNames,'BV1'))
    sub(ismember(row_names,'RV1')) = 1;
  end
  if any(strcmp(regr.Coefficients.Properties.RowNames,'BV5'))
    sub(ismember(row_names,'RV5')) = 1;
  end
  if any(strcmp(regr.Coefficients.Properties.RowNames,'BV22'))
    sub(ismember(row_names,'RV22')) = 1;
  end
  sub = sub == 1;
  
  results = NaN(length(se_row_names), 1);
  resultswse = NaN(length(se_row_names), 1);
  results( cx(sub) ) = coeff;
  results( tx(sub) ) = tstats;

  se_row_names{end+1} = 'Adj. R2';
  results(end+1)   = regr.Rsquared.Adjusted;
  results = array2table(results,'RowNames',se_row_names,'VariableNames',{reg_name});
  
  resultswse( cx(sub) ) = coeff;
  resultswse( tx(sub) ) = se;
  
  resultswse(end+1)   = regr.Rsquared.Adjusted;
  resultswse = array2table(resultswse,'RowNames',se_row_names,'VariableNames',{reg_name});
  
  
  
