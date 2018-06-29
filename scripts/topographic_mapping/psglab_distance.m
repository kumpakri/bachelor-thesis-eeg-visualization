function d = psglab_distance(X, Y)
%PSGLAB_DISTANCE - distance between two vectors
%
% function d = psglab_distance(X, Y)
%
% X, Y: input vectors
% d: distance between X and Y
%
% See also PSGLAB_RUN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSGLab ver. 2.1: Polysomnographic Data Processing Matlab Toolbox (c) 2009-2013  %
% http://bio.felk.cvut.cz/psglab/                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[N1 M1] = size(X);
[N2 M2] = size(Y);

d = zeros(N1, N2);
for i = 1 : N1
	d(i, :) = sqrt(sum((Y - repmat(X(i, :), N2, 1)).^2, 2));
end;