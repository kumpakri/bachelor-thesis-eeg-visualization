function [newDataContainer] = getNewContainer(dataContainer,startSample,endSample)
% Returns Cell array Nx1 where each cell contains data
% Mx(endSample-startSample).
% dataContainer - cell array Nx1
% startSample   - integer nuber of first sample in newDataContainer
% endSample     - integer nuber of last sample in newDataContainer

    len = length(dataContainer);
    newDataContainer = cell(len,1);
    if(length(startSample)~=length(endSample))
        error('')
    end
    N = length(startSample);
    for i =1:len
        if (N==1)
            newDataContainer{i} = dataContainer{i}(startSample:endSample);
        else
            temp = [];
            for j=1:N
                temp = [temp; dataContainer{i}(startSample(j):endSample(j))];
            end
            newDataContainer{i} = temp;
        end
    end
end