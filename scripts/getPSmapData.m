function [data] = getPSmapData(PSContainer,freq,samplesPer1Hz,PSref)
% Returns array (1xN) of average powers for every channel in defined 
% frequency band.
% PSContainer   - cell array (Nx1) of power spectra for each channel
% freq          - array (1x2) of frequency band [bottomFrequency,upperFrequency]
% samplesPer1Hz - number of samples representing frequecny band 1 Hz wide
% PSref         - referential value of power in dB

    %number of channels
    size = length(PSContainer);
    data = [];
    
    PSmin = Inf;
    PSmax = -Inf;
    
    for channelIndex=1:size
            
        bandBottom = int16(freq(1)*samplesPer1Hz); %first sample of band
        if(bandBottom == 0)
            bandBottom = 1;
        end
        bandUpper = int16(freq(2)*samplesPer1Hz);  %last sample of band

        %normalization
        ps = PSContainer{channelIndex}-PSref;        
        meanPs = mean(ps(floor(bandBottom):floor(bandUpper)));

        data(channelIndex) = meanPs;
    end
    
    addpath topographic_mapping
    
end