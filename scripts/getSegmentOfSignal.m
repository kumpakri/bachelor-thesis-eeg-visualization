function [newChannels] = getSegmentOfSignal(channels,startPosition,segmentTime)
% Returns struct containing data from defined interval.
% channels - struct from EDF file (obtained from EDF_read_write.m function)
% startPosition - starting time in seconds
% segmentTime   - length of the segment in seconds
    dataLen=length(channels.ch(1).data);
    fs = channels.ch(1).fs; 
    segmentLen = fs*segmentTime;
    segmentStart = fs*startPosition;
    if( (segmentStart+segmentLen) > dataLen)
        error('Data length exceeded.')
    end
    
    len = length(channels.ch);
    for channelIndex = 1:len
        data = channels.ch(channelIndex).data;
        label = channels.ch(channelIndex).transducer;
        if(~isempty(strfind(label,'EEG')))

            newData = data(segmentStart:(segmentStart+segmentLen));
            channels.ch(channelIndex).data = newData;
        end
    end
     newChannels = channels;
end