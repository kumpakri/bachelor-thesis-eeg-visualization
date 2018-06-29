function [labels] = getChannels(disp,dataLabels)
% Returns cell array of intersection of channels in dataLabels and channels
% included in system disp.
% disp          - string identificator of wich subset of channels to use.
%               set '10-20' for 19 electrodes system
%               set '8channels' for infant EEG
%               set 'all' for display of all available channels
% dataLabels    - cell array (Nx1) with labels of channels available in data

global labels19channels labels8channels all

if( strcmp(disp,'10-20') )
    systemLabels = labels19channels;
else if( strcmp(disp,'test') )
        systemLabels = labelsTest;
    else if( strcmp(disp,'8channels') )
            systemLabels = labels8channels;
        else if( strcmp(disp,'all') )
                systemLabels = all;
                
                %HERE add new subsets of electrodes
            else %if( strcmp(disp,'newSubsetString') )
                    %systemLabels = newSubsetGlobalVariableName;
                %else
            error('Name of electrodes location system "%s" is not defind. Use "10-20" or "8channels".',disp)
                %end
            end
        end
    end
end

len = length(dataLabels);
labels = cell(len,1);
for i = 1:len
    if(find(strncmp(upper(dataLabels{i}),systemLabels,4)) > 0)
        labels{i} = upper(dataLabels{i});
    else
        labels{i} = NaN;
    end
end

