function [filenameContainer,ca] = getSpectrogram(dataContainer,labels,fs,WINDOW,NOVERLAP,path,id)
% Saves spectrograms in .fig format at disk and returns cell
% array (Mx1) of filenames of all created figures and color axis (1x2). 
% Filenames of produced spectrograms will follow pattern:
% 'graphSpec*id*1','graphSpec*id*2',...
% dataContainer - cell array (Px1) with data (NxK)
% labels        - cell array (Lx1) with labels of used electrodes
% fs            - sampling frequency
% WINDOW        - Windowing function and number of samples to use for each section
% NOVERLAP      - number of samples that each segment overlaps
% path          - string path of directory where to save figures
% id            - string identificator to distinguish different sets of
%               spectrograms in common directory
    close all
    close all hidden
    size = length(labels);
    N = length(dataContainer{1}(:,1));
    figureIndex=1;
    ca = [Inf -Inf];
    
    if(path(end)=='\')
        path = path(1:end-1);
    end
    
    numCh = 0;
    for dataIndex=1:size
        if( isnan(labels{dataIndex})~=1 )
            numCh = numCh +1;
        end
    end
    
    filenameContainer=cell(numCh,1);

    for dataIndex=1:size
        if( isnan(labels{dataIndex})~=1 )
            signal = dataContainer{dataIndex};

            if (N > 1)
                x=sum(signal)/N;
            else
                x=double(signal);
            end
            
            spectrogram(x,WINDOW,NOVERLAP,0:0.25:36,fs,'yaxis');
            caCurr = caxis;
            if(caCurr(1) < ca(1))
                ca(1) = caCurr(1);
            end
            if(caCurr(2) > ca(2))
                ca(2) = caCurr(2);
            end
            
            ylabel ''
            xlabel ''
            filename = [path '\graphSpec' id int2str(figureIndex)];
            savefig(filename);
            filenameContainer{figureIndex} = filename;
            figureIndex = figureIndex+1;

        end
    end
end