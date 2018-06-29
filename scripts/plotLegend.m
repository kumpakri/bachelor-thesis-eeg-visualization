function [] = plotLegend(fig,label,args)
%Plots legend in figure fig with respect to what kind of vizualization was
%used
% fig   - figure for legend to be plotted in
% label - identifies type of vizualization.
%       for power spectral density and average powers set 'PS' 
%       for coherences set 'coh'           
%       for correlations set 'corr'
%       for spectrograms set 'spec'
%       for topografical mapping set 'map'
% args  - array of additinal information needed to plot the legend correctly.
%       with 'PS' label args contain: [min,max,containerLen]
%       with 'coh' label args contain: [treshold]
%       with 'corr' label args contain: [treshold]
%       with 'spec' label args contain: [fs,dataLen,startingTime,ca]
%       with 'map' label args contain: [min,max]
%       min     - bottom limit of y axis to be plotted on reference graph
%       max     - upper limit of y axis to be plotted on reference graph
%       containerLen - number of graphs in picture
%       treshold     - minimal value to be plotted
%       fs      - sampling frequency
%       dataLen - number of samples
%       startingTime - left limit of x axis in seconds
%       ca      - color axis of colormap
figure(fig);
if(strcmp(label,'PS'))
    % reference plot
    
    %Sizes have to be the same as defined in plotGraphOnChannel.m script
    if(args(3) > 10)
        size = 0.1;
    else
        size = 0.14;
    end
    axes('Position',[0.11-((size-0.1)/1.3),0.15-((size-0.1)/2),size,size],'XTickLabel',[0 15 30],'YTickLabel',[round(args(1)) round((args(2)+args(1))/2) round(args(2))],'FontSize',14);
    xlabel('frequency (Hz)')
    ylabel('power (dB/Hz)')

    %legend
    axes('position',[0.85 0.1 0.12 0.15],'XTickLabel','','YTickLabel','');
    rectangle('position',[0.1 0.8 0.1 0.1],'FaceColor','yellow');
    rectangle('position',[0.1 0.6 0.1 0.1],'FaceColor','blue');
    rectangle('position',[0.1 0.4 0.1 0.1],'FaceColor','green');
    rectangle('position',[0.1 0.2 0.1 0.1],'FaceColor','red');

    text(0.25, 0.85, 'Delta','FontSize',14)
    text(0.25, 0.65, 'Theta','FontSize',14)
    text(0.25, 0.45, 'Alpha','FontSize',14)
    text(0.25, 0.25, 'Beta','FontSize',14)
    axis([0.05 0.7 0.1 1])
    axis off
else if(strcmp(label,'coh'))
    minVal = args(1);
    m = colormap('summer');
    rgb=[];
    for j=1:3
        rows=1;
        for i=1:64
            rgb(rows:rows+2,:,j)=m(i,j)*ones(3,25);
            rows = rows+3;
        end
        rgb(193:204,:,j)=m(64,j)*ones(12,25);
    end
    axes('Position',[0,0.1,0.06,0.5]);
    hold on
    imshow(rgb)
    axis on;
    axis tight
    set(gca, 'XTickLabel',[]);
    set(gca,'YTick',[0 200])
    set(gca, 'YTickLabel',round(10*[1,minVal])/10,'YAxisLocation','right','fontsize',14);
    axis([0 25 0 200])
    else if(strcmp(label,'corr'))
            minVal = args(1);
            m = colormap('summer');
            n = flip(colormap('autumn'),1);
            rgb=[];
            for j=1:3
                rows=1;
                for i=1:64
                    rgb(rows:rows+1,:,j)=m(i,j)*ones(2,25);
                    rows = rows+2;
                end
                for i=1:64
                    rgb(rows:rows+1,:,j)=n(i,j)*ones(2,25);
                    rows = rows+2;
                end
            end
            axes('Position',[0.05,0.33,0.08,0.2]);
            hold on
            imshow(rgb(1:125,:,:))
            axis on;
            axis tight
            set(gca, 'XTickLabel',[]);
            set(gca,'YTick',[0 125],'FontSize',14)
            set(gca, 'YTickLabel',[1 minVal]);
            axis([0 25 0 125])
            
            axes('Position',[0.05,0.1,0.08,0.2]);
            hold on
            imshow(rgb(125:256,:,:))
            axis on;
            axis tight
            set(gca, 'XTickLabel',[]);
            set(gca,'YTick',[0 125])
            set(gca, 'YTickLabel',[-minVal -1],'FontSize',14);
            axis([0 25 0 125])
        else if (strcmp(label,'spec'))
                % reference plot
                
                %Sizes have to be the same as defined in plotGraphOnChannel.m script
                if(args(4) > 10)
                    size = 0.1;
                else
                    size = 0.14;
                end
                axes('Position',[0.11-((size-0.1)/1.3),0.15-((size-0.1)/2),size,size],'XTick',[0 100],'XTickLabel',[round(args(3)*10)/10,round((args(2)/args(1)+args(3))*10)/10],'YTick',[0 50 100],'YTickLabel',[0,18,36],'FontSize',14);
                axis([0 100 0 100])
                xlabel('time (sec)','FontSize',14)
                ylabel('frequency (Hz)','FontSize',14)
                
                % colorbar
                m = colormap('jet');
                rgb=[];
                for j=1:3
                    rows=1;
                    for i=1:64
                        rgb(rows:rows+2,:,j)=m(65-i,j)*ones(3,20);
                        rows = rows+3;
                    end
                    rgb(193:204,:,j)=m(1,j)*ones(12,20);
                end
                ca = [];
                ca(1) = args(5);
                ca(2) = args(6);
                axes('Position',[0.95,0.06,0.06,0.5],'FontSize',13);
                hold on
                imshow(rgb)
                axis on;
                axis tight
                set(gca, 'XTickLabel',[]);
                yLabel = fliplr(round(ca(1):(ca(2)-ca(1))/10:ca(2)));
                set(gca, 'YTickLabel',yLabel);
                axis([0 20 0 200])
                ylabel('power (dB/Hz)')
                
            else if(strcmp(label,'map'))
                % colorbar
                m = colormap('jet');
                rgb=[];
                for j=1:3
                    rows=1;
                    for i=1:64
                        rgb(rows:rows+2,:,j)=m(65-i,j)*ones(3,20);
                        rows = rows+3;
                    end
                    rgb(193:204,:,j)=m(1,j)*ones(12,20);
                end
                
                axes('Position',[0.9,0.1,0.042,0.5],'FontSize',12);
                hold on
                imshow(rgb)
                axis on;
                axis tight
                set(gca, 'XTickLabel',[]);
                yLabel = fliplr(round(args(1):(args(2)-args(1))/10:args(2)));
                set(gca, 'YTickLabel',yLabel);
                axis([0 20 0 200])
                set(gca,'Box','off');
                axesPosition = get(gca,'Position');
                hNewAxes = axes('Position',axesPosition,... 
                'Color','none',...           
                'YTick',[],...            
                'YAxisLocation','right',...  
                'XTick',[],...               
                'Box','off','FontSize',14); 
                ylabel(hNewAxes,'power (dB/Hz)')
                end
            end
        end
    end
end