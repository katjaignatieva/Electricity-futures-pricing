function [uT] = getDeterministicSpot(coeffs,dates)

t = (dates - datenum(2006,1,1))./365;
dayofw = weekday(dates);
monthofy = month(dates);

X = NaN(length(t),20);
X(:,1) = 1;
X(:,2) = t;
X(:,3) = sin(2*pi.*t);
X(:,4) = cos(2*pi.*t);
for di = 2:7
  X(:,3+di) = dayofw == di;
end
for di = 2:12
  X(:,9+di) = monthofy == di;
end

uT = X*coeffs;

end