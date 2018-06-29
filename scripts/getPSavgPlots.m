function [filenameContainer,labelPSmin,labelPSmax, limits] = getPSavgPlots(PSContainer,samplesPer1Hz,PSref,path,id)
% Saves average power graphs in .fig format at disk and returns cell
% array (Nx1) of filenames of all created figures, lowest average PS value 
% in set with respect to referential value, highest average PS value in 
% set with respect to referential value and absolute limits (1x4) to be 
% set to all graphs during copying to final picture.
% Filenames of produced spectrograms will follow pattern:
% 'graphPSavg*id*1','graphPSavg*id*2',...   
% PSContainer   - cell array (Nx1) of power spectral density
% samplesPer1Hz - number of samples representing frequecny band 1 Hz wide
% PSref         - referential value of power in dB
% path          - string path of directory where to save figures
% id            - string identificator to distinguish different sets of
%               average powers in common directory
    close all
    size = length(PSContainer);
    filenameContainer = cell(size,1);
    
    if(path(end)=='\')
        path = path(1:end-1);
    end
    
    PSavgMax = -Inf;
    PSavgMin = Inf;
    
    delta = int16(3.5*samplesPer1Hz); %last sample of delta frequncies
    theta = int16(7.5*samplesPer1Hz); %last sample of theta frequncies
    alpha = int16(13*samplesPer1Hz); %last sample of alpha frequncies
    beta = int16(30*samplesPer1Hz); %last sample of beta frequncies
    
    for figureIndex=1:size
        ps = PSContainer{figureIndex};
        
        meanBeta = mean(ps(alpha:beta));
        meanAlpha = mean(ps(theta:alpha));
        meanTheta = mean(ps(delta:theta));
        meanDelta = mean(ps(1:delta));

        if(PSavgMax<meanBeta)
            PSavgMax=meanBeta;
        end
        if(PSavgMax<meanAlpha)
            PSavgMax=meanAlpha;
        end
        if(PSavgMax<meanTheta)
            PSavgMax=meanTheta;
        end
        if(PSavgMax<meanDelta)
            PSavgMax=meanDelta;
        end

        if(PSavgMin>meanBeta)
            PSavgMin=meanBeta;
        end
        if(PSavgMin>meanAlpha)
            PSavgMin=meanAlpha;
        end
        if(PSavgMin>meanTheta)
            PSavgMin=meanTheta;
        end
        if(PSavgMin>meanDelta)
            PSavgMin=meanDelta;
        end

    end
    
    for figureIndex=1:size
        ps = PSContainer{figureIndex};
        
        meanBeta = mean(ps(alpha:beta));
        meanAlpha = mean(ps(theta:alpha));
        meanTheta = mean(ps(delta:theta));
        meanDelta = mean(ps(1:delta));

        y4=[zeros(alpha-1,1); meanBeta*ones(beta-(alpha-1),1)-PSavgMin+1];
        y3=[zeros(theta-1,1); meanAlpha*ones(alpha-(theta-1),1)-PSavgMin+1; zeros(beta-alpha,1)];
        y2=[zeros(delta-1,1); meanTheta*ones(theta-(delta-1),1)-PSavgMin+1; zeros(beta-theta,1)];
        y1=[meanDelta*ones(delta,1)-PSavgMin+1; zeros(beta-delta,1)];


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

        filename = [path '\graphPSavg' id int2str(figureIndex)];
        savefig(filename);
        filenameContainer{figureIndex} = filename;

        close all
    end
    
    xLeftLimit = 0;
    xRightLimit = beta;
    yBottomLimit = 0;
    yUpperLimit = PSavgMax+2-PSavgMin;
    limits = [xLeftLimit, xRightLimit, yBottomLimit, yUpperLimit];
    
    % PSref = 10*log(Vref)
    labelPSmin=yBottomLimit+PSavgMin-1-PSref;
    labelPSmax=yUpperLimit+PSavgMin-1-PSref;
end