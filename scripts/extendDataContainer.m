function [margedDataContainer] = extendDataContainer(dataContainer,dataContainerTemp)
% Returns cell array Nx1 where each cell contains data Mx(K+L). Data are
% taken from dataContainer (MxK) and extended by data from
% dataContainerTemp (MxL).
% dataContainer     - cell array Nx1 where each cell contains data MxK
% dataContainerTemp - cell array Nx1 where each cell contains data MxL

origLen = length(dataContainer);

margedDataContainer = cell(origLen,1);

for i=1:origLen
    margedDataContainer{i} = [dataContainer{i},dataContainerTemp{i}];
end