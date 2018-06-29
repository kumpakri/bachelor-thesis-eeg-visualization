function [PSContainer,maxPS,samplesPer1Hz] = getPSContainer(dataContainer,labels,fs,smoothSpan,smoothMethod)
% Returns cell array (Nx1) of averaged PSD in logaritmic scale, maximal 
% value in PSContainer and number of samples representing frequency band 
% of width 1 Hz.
% dataContainer - cell array (Mx1) with data
% labels        - cell array (Lx1) with names of electrodes
% fs            - sampling frequency
% smoothSpan    - span of the moving average (must be odd)
% smoothMethod  - smoothing method

    containerIndex = 1;
    size = length(labels);
    % num of samples to average
    N = length(dataContainer{1}(:,1));
    % length of signal in samples
    L = length(dataContainer{1}(1,:));
    maxPS= -Inf;
    samplesPer1Hz = L/fs;
    
    %finding number of graph that will be plotted
    numCh = 0;
    for dataIndex=1:size
        if( isnan(labels{dataIndex})~=1 )
            numCh = numCh +1;
        end
    end
    
    PSContainer = cell(numCh,1);
    
    for dataIndex=1:size
        if( isnan(labels{dataIndex})~=1 )
            signal = dataContainer{dataIndex};

            if(N>1)
                %averaging
                xdft=fft(sum(signal)/N);
            else
                xdft=fft(double(signal));
            end
            
            % PSD computation
            xdft = xdft(1:L/2+1);
            psdx = (1/(fs*L))*abs(xdft).^2;
            psdx(2:end-1) = 2*psdx(2:end-1);

            powerSpectrum = 10*log10(psdx);
            smoothPS=smooth(powerSpectrum,smoothSpan,smoothMethod);
            
            
            PSContainer{containerIndex} = smoothPS;
            
            absmax = max(smoothPS);
            if (maxPS<absmax)
                maxPS=absmax;
            end
            
            containerIndex = containerIndex+1;

        end
    end
end