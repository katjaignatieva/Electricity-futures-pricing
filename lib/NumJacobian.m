function [J] = NumJacobian( NameFunction, x, prec )
% Compute the symmetric numerical first order derivatives of a
% multivariate function.
%
% Inputs: NameFunction: name of a function returning a N x 1 vector;
%         x: point (d x 1) at which the derivatives will be computed;
%         prec: percentage of +\- around x (in fraction).
%
% Output: J (derivatives) (N x d)
%

d = length( x );

for ii = 1:d
    
    x2 = x;
    x1 = x;
    x1( ii ) = x1( ii ) ;
    x2( ii ) = x1( ii ) * (1 + prec) ;
    
    J( :, ii ) = ( NameFunction( x1 ) - NameFunction( x2 ) ) / ( x1( ii ) - x2( ii ) );
    
end

end