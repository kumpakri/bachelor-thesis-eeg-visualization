function [coherenceMatrix] = getCoherenceMatrix(dataContainer,WINDOW,NOVERLAP)
% Returns cell array (Nx1) where each cell include cell array (Nx1) with
% coherences between channels.
% example: [coherenceMatrix] = getCoherenceMatrix(dataContainer,indexes,hanning(512),0)
%dataContainer  - Cell array (Nx1) with data
%WINDOW         - Windowing function and number of samples to use for each section
%NOVERLAP       - Number of samples by which the sections overlap
    
%% computing coherence
    len = length(dataContainer);
    N = length(dataContainer{1}(:,1));
    coherenceMatrix = cell(len,1);
    
    parfor i=1:len
        innerMatrix = cell(len,1);
        for j=(i+1):len
            temp=[0];
            for l=1:N
                temp = temp + mscohere(double(dataContainer{i}(l,:)),double(dataContainer{j}(l,:)),WINDOW,NOVERLAP);
            end
            innerMatrix{j} = temp/N;
        end
        coherenceMatrix{i} = innerMatrix;
    end
end