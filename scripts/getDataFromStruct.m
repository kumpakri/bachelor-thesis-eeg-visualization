function [fs,labels,dataContainer] = getDataFromStruct(struct)
% Returns sample frequency (fs), cell array Nx1 with string labels of
% electrodes (labels) and cell array Nx1 with data (dataContainer).
% struct - struct from EDF file (obtained from EDF_read_write.m function)

global mapObj

    len = length(struct.ch);
    
    indexes = [];
    labelsTemp = cell(len,1);
    dataContainerTemp = cell(len,1);
    
    labelIndex = 1;
    for i=1:len
        % mapObj is defined in electrodes.m 
        if(mapObj.isKey(upper(struct.ch(i).label)))
            indexes(end+1) = i;
            labelsTemp{labelIndex} = upper(struct.ch(i).label);
            dataContainerTemp{labelIndex} = struct.ch(i).data;
            labelIndex = labelIndex+1;
        end
    end
    fs = struct.ch(indexes(1)).fs;
    labels = labelsTemp(1:length(indexes));
    dataContainer = dataContainerTemp(1:length(indexes));
end