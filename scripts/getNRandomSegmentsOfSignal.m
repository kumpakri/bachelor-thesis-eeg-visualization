function [newChannels] = getNRandomSegmentsOfSignal(channels,N,segmentTimeLen)
% Returns struct with data NxL consisted of defined number of segments (for 
% further averaging). All segments are of defined length. Segments are 
% randomly picked up along the data.
% channels          - original struct with data
% N                 - number of segments
% segmentTimeLen    - length of segments in seconds

    dataLen=length(channels.ch(1).data);
    fs = channels.ch(1).fs; 
    segmentLen = fs*segmentTimeLen; 
    if(N*segmentLen > dataLen)
        error('Data is not big enough for %i %i seconds long segemnts.',N,segmentTimeLen)
    end

    excessSamples = dataLen-N*segmentLen;
    spacesProportions = rand(1,N+1);
    spaces = floor((excessSamples/sum(spacesProportions)).*spacesProportions);
    
    len = length(channels.ch);
    for channelIndex = 1:len
        data = channels.ch(channelIndex).data;
        label = channels.ch(channelIndex).transducer;
        if(~isempty(strfind(label,'EEG')))
        
            newData = [];

            loc = 0;
            for segmentIndex = 1:N
                loc = loc+spaces(segmentIndex);
                newData(segmentIndex,:) = data(loc:(loc+segmentLen));
                loc = loc+segmentLen;
            end
            channels.ch(channelIndex).data = newData;
        end
    end
     newChannels = channels;
end