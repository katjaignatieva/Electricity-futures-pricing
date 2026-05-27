function tab = tabRND()

load('results/model_PQ_SVJ')
pvSVJ = model.getPV;

load('results/model_PQ_SVJDI')
pvSVJDI = model.getPV;

load('results/model_PQ_SVJLRL')
pvSVJLRL = model.getPV;

load('results/model_PQ_SVJDILRL')
pvSVJDILRL = model.getPV;

tab = NaN(9,4);

tab(1,1) = pvSVJ.chix;
tab(3,1) = pvSVJ.chiv;
tab(4,1) = pvSVJ.hp;
tab(5,1) = pvSVJ.hn;
tab(6,1) = pvSVJ.nupQ - pvSVJ.nup;
tab(7,1) = pvSVJ.nunQ - pvSVJ.nun;
tab(8,1) = pvSVJ.nuvQ - pvSVJ.nuv;

tab(1,2) = pvSVJDI.chix;
tab(3,2) = pvSVJDI.chiv;
tab(4,2) = pvSVJDI.hp;
tab(5,2) = pvSVJDI.hn;
tab(6,2) = pvSVJDI.nupQ - pvSVJDI.nup;
tab(7,2) = pvSVJDI.nunQ - pvSVJDI.nun;
tab(8,2) = pvSVJDI.nuvQ - pvSVJDI.nuv;
tab(9,2) = pvSVJDI.nulambdaQ - pvSVJDI.nulambda;

tab(1,3) = pvSVJLRL.chix;
tab(2,3) = pvSVJLRL.chimu;
tab(3,3) = pvSVJLRL.chiv;
tab(4,3) = pvSVJLRL.hp;
tab(5,3) = pvSVJLRL.hn;
tab(6,3) = pvSVJLRL.nupQ - pvSVJLRL.nup;
tab(7,3) = pvSVJLRL.nunQ - pvSVJLRL.nun;
tab(8,3) = pvSVJLRL.nuvQ - pvSVJLRL.nuv;

tab(1,4) = pvSVJDILRL.chix;
tab(2,4) = pvSVJDILRL.chimu;
tab(3,4) = pvSVJDILRL.chiv;
tab(4,4) = pvSVJDILRL.hp;
tab(5,4) = pvSVJDILRL.hn;
tab(6,4) = pvSVJDILRL.nupQ - pvSVJDILRL.nup;
tab(7,4) = pvSVJDILRL.nunQ - pvSVJDILRL.nun;
tab(8,4) = pvSVJDILRL.nuvQ - pvSVJDILRL.nuv;
tab(9,4) = pvSVJDILRL.nulambdaQ - pvSVJDILRL.nulambda;

end
