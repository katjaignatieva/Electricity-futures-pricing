addpath('lib');
addpath('lib/nber');
addpath('lib/utils');
addpath('figtabs');
addpath('data');

cwd = cd('lib');
addpath('../lib/utils');
try
  update_mex('blsimpv_cpp.cpp');
  update_mex('getOptionPrice1Int_cpp.cpp');
  update_mex('blsprice_cpp.cpp');
  update_mex('AmOptCRR.cpp');
  update_mex('getrandustar_cpp.cpp');
catch err
  display(err)
end
rmpath('../lib/utils');
cd(cwd)
