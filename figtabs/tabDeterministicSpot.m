function tab = tabDeterministicSpot()

load('results/model_deterministicSpot')

tab = NaN(12,4);

tab(1:2,1) = deterministicSpot.coeffs(1:2);
tab(4:5,1) = deterministicSpot.coeffs(3:4);
tab(7:12,1) = deterministicSpot.coeffs(5:10);
tab(1:2,2) = deterministicSpot.stderrors(1:2);
tab(4:5,2) = deterministicSpot.stderrors(3:4);
tab(7:12,2) = deterministicSpot.stderrors(5:10);

tab(1:11,3) = deterministicSpot.coeffs(11:end);
tab(1:11,4) = deterministicSpot.stderrors(11:end);

end
