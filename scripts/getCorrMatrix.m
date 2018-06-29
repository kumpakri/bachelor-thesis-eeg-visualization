function [corrMatrix] = getCorrMatrix(dataContainer)
% Computes correlation between channels. Returns cell array (Lx1) where
% each row cosists of cell array (Lx1) with correlations. L is number of
% channels.
% example: [corrMatrix] = getCoherenceMatrix(dataContainer,indexes,hanning(512),0)
% dataContainer - cell array (Lx1) with data
    
    %number of channels
    len = length(dataContainer);
    %number of segments
    N = length(dataContainer{1}(:,1));
    corrMatrix = cell(len,1);
    
    parfor i=1:len
        innerMatrix = cell(len,1);
        for j=(i+1):len
            temp=[0];
            for l=1:N
                corr = corrcoef(double(dataContainer{i}(l,:)),double(dataContainer{j}(l,:)));
                temp = temp + corr(1,2);
            end
            innerMatrix{j} = temp/N;
        end
        corrMatrix{i} = innerMatrix;
    end
end