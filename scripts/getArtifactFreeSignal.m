function [newChannels] = getArtifactFreeSignal(channels,expert_marks)
% Creates new struct newChannels with artefact free signal from struct 
% channels. Does not affect original struct.
% channels      - struct from EDF file (obtained from EDF_read_write.m function)
% expert_marks  - struct with expert marks

    i = 1;
    len = length(channels.ch);
    while(i<=len) 
        data = channels.ch(i).data;
        fs = channels.ch(i).fs;
        newData = [];

        j = 1;
        lenMarks = length(expert_marks.list);
        marksStart = expert_marks.list(1,:);
        marksEnd = expert_marks.list(2,:);
        while(j<=lenMarks)
            newData = [newData data(fs*marksStart(j):fs*marksEnd(j))];
            j = j+1;
        end
        channels.ch(i).data = newData;
        i = i+1;
    end
     newChannels = channels;
end