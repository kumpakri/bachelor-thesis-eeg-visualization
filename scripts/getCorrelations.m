function [dataCorr] = getCorrelations(corrMat,labels)
% Returns cell matrix (NxN) of correlation coeficients in needed order to match
% with the right electrode (channel).
% corrMat 	- nxn cell matrix of correlations between channels.
% labels    - nx1 cell vector of names of the channels.

    %number of channels
    n = length(labels);
    dataCorr = cell(length(labels),length(labels));

    % correlations
    for ch1 = 1:(n-1)
        if( isnan(labels{ch1})~=1 )

            for ch2 = (ch1+1):n
                if( isnan(labels{ch2})~=1 )
                    dataCorr{ch1,ch2} = corrMat{ch1}{ch2};

                end
            end
        end
    end
end

