function [] = update_mex(fname)
  [dirname, base, ext] = fileparts(fname);
  mexfile = dir([base '.' mexext]);
  cppfile = dir(fname);

  assert(~isempty(cppfile));
  % mex file does not exist
  if isempty(mexfile)
    mex(fname);
    
  % cpp file was updated
  elseif cppfile.datenum > mexfile.datenum
    mex(fname);
    
  else
    disp([mexfile.name ' is up to date.'])
  end
