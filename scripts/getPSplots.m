function [filenameContainer,labelPSmin,labelPSmax, limits] = getPSplots(PSContainer,samplesPer1Hz,PSref,path,id)
% Saves power spectras in .fig format at disk and returns cell
% array of filenames (Nx1) of all created figures, lowest PS value in set with 
% respect to referential value, highest PS value in set with respect to 
% referential value and absolute limits (1x4) to be set to all graphs during
% copying to final picture.
% Filenames of produced spectrograms will follow pattern:
% 'graphPS*id*1','graphPS*id*2',...   
% PSContainer   - cell array (Nx1) of power spectra
% samplesPer1Hz - number of samples representing frequecny band 1 Hz wide
% PSref         - referential value of power in dB
% path          - string path of directory where to save figures
% id            - string identificator to distinguish different sets of
%               power spectras in common directory

    %number of graphs to be saved
    size = length(PSContainer);
    filenameContainer = cell(size,1);
    
    if(path(end)=='\')
        path = path(1:end-1);
    end
    
    PSmin = Inf;
    PSmax = -Inf;
    
    delta = int16(3.5*samplesPer1Hz); %last sample of delta frequncies
    theta = int16(7.5*samplesPer1Hz); %last sample of theta frequncies
    alpha = int16(13*samplesPer1Hz); %last sample of alpha frequncies
    beta = int16(30*samplesPer1Hz); %last sample of beta frequncies

    %finding extreme values (for axis limits computation)
    for graphIndex=1:size
        ps = PSContainer{graphIndex};

        minps = min(ps(1:beta));
        maxps = max(ps(1:beta));

        if(PSmax<maxps)
            PSmax=maxps;
        end
        if(PSmin>minps)
            PSmin=minps;
        end          
    end
    
    %plotting and saving graphs
    for graphIndex=1:size
        close all
        close all hidden
        ps = PSContainer{graphIndex};


        y4=[zeros(alpha-1,1); (ps(alpha:beta))-PSmin];
        y3=[zeros(theta-1,1); (ps(theta:alpha))-PSmin; zeros(beta-alpha,1)];
        y2=[zeros(delta-1,1); (ps(delta:theta))-PSmin; zeros(beta-theta,1)];
        y1=[(ps(1:delta))-PSmin; zeros(beta-delta,1)];


        a=[];
        a(1)=area(y1);
        hold on
        a(2)=area(y2);
        a(3)=area(y3);
        a(4)=area(y4);

        set(a(1),'FaceColor','yellow');
        set(a(2),'FaceColor','blue');
        set(a(3),'FaceColor','green');
        set(a(4),'FaceColor','red');

        filename = [path '\graphPS' id int2str(graphIndex)];
        savefig(filename);
        filenameContainer{graphIndex} = filename;
    end
    
    %computing axis limits
    xLeftLimit = 0;
    xRightLimit = beta;
    yBottomLimit = 0;
    yUpperLimit = PSmax-PSmin;
    limits = [xLeftLimit, xRightLimit, yBottomLimit, yUpperLimit];
    
    %normalization
    labelPSmin=yBottomLimit+PSmin-PSref;
    labelPSmax=yUpperLimit+PSmin-PSref;
end