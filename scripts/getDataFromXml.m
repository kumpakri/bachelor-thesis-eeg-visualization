function [fs,labels,dataContainer,expertMarks] = getDataFromXml(path)
% Returns sampling frequncy (fs), cell array Nx1 with string labels of
% electrodes (labels), cell array Nx1 with data (dataContainer) and array
% Nx3 od expert marks and classes.
% path - path to directory with data-info.xml anddata-expert.txt files

struct = parseXML([path 'data-info.xml']);

len = length(struct(2).Children);
for i=1:len
    if(strcmp(struct(2).Children(i).Name,'number_of_channels')) 
        labelsTemp = cell(struct(2).Children(i).Children.Data(1),1);      
        channelFilenames = cell(struct(2).Children(i).Children.Data(1),1);
        labelsIndex = 1; 
    end
    if(strcmp(struct(2).Children(i).Name,'sample_frequency')) 
        fs = str2num(struct(2).Children(i).Children.Data);
    end
    
    if((strfind(struct(2).Children(i).Name,'channel_'))) 
        
        channelFilename = strrep(struct(2).Children(i).Name, '_', '-');
        if exist([path channelFilename '.mat'], 'file')
        
            labelsTemp{labelsIndex} = struct(2).Children(i).Children.Data;
            channelFilenames{labelsIndex} = channelFilename;
            labelsIndex = labelsIndex+1;
        end
    end
end

dataContainer = cell(labelsIndex-1,1);
labels = labelsTemp(1:labelsIndex-1);

for i=1:(labelsIndex-1)
    load([path channelFilenames{i} '.mat'])
    dataContainer{i} = data;   
end

[startSegment, endSegment, segmentClass] = textread([path 'data-expert.txt'],'%u %u %u');
expertMarks = [startSegment endSegment segmentClass];