function [margedDataContainer] = joinDataContainers(dataContainer,dataContainerTemp)
% Returns cell array Nx1 where each cell contains data (K+L)xM. Data are
% taken from dataContainer (KxM) and extended by data from
% dataContainerTemp (LxM).
% dataContainer     - cell array Nx1 where each cell contains data KxM
% dataContainerTemp - cell array Nx1 where each cell contains data LxM


origLen = length(dataContainer);
addLen = length(dataContainerTemp);

if(origLen~=addLen)
    error('Length of the two dataContainers is not the same.')
end

margedDataContainer = cell(origLen,1);

for i=1:origLen
    margedDataContainer{i} = [dataContainer{i};dataContainerTemp{i}];
end