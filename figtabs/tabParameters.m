function [pv,stderr] = tabParameters()

load('results/model_PQ_SVJ')
pv.SVJ = model.getPV;

load('results/model_PQ_SVJDI')
pv.SVJDI = model.getPV;

load('results/model_PQ_SVJLRL')
pv.SVJLRL = model.getPV;

load('results/model_PQ_SVJDILRL')
pv.SVJDILRL = model.getPV;

load('results/model_PQ_SVJ_stderr')
stderr.SVJ = stderrSVJ;

load('results/model_PQ_SVJDI_stderr')
stderr.SVJDI = stderrSVJDI;

load('results/model_PQ_SVJLRL_stderr')
stderr.SVJLRL = stderrSVJLRL;

load('results/model_PQ_SVJDILRL_stderr')
stderr.SVJDILRL = stderrSVJDILRL;

end
