function [f] = plotGraphOnChannel(labels,filenameContainer,limits,ca) 
% Plots saved graphs (filenames in filenameContainer) in to one common
% figure on a position specified in mapObj. Returns figure holder.
% labels                - cell array (Lx1) with used electrodes names
% filenameContainer     - cell array (Nx1) with paths to saved graphs
% limits                - array (1x4) of axis limits to set for all graphs (for
%                       comparability). If graphs need only colormap to be 
%                       adjusted (spectrograms etc.), set this parameter 
%                       to value 0 
% ca                    - array (1x2) of colormap axis. If graphs does not use 
%                       colormaps, set this parameter to value 0 

    global mapObj

    close all
    close all hidden
    
    %number of channels (graphs)
    len = length(labels);

    screenSizes = get(0,'MonitorPositions');
    screenSize = screenSizes(1,:);   % in case of extended screen
    [width,height] = getFigureSize(screenSize,1,1);
    f=figure('Position',[1 1 width height]);
    set(gcf,'Resize','off')
    % The size of the figure will be set for a display which was set as output
    % device when starting MATLAB (some inner setting of MATLAB)

    t=linspace(0,2*pi);
    head = fill(0.5+0.4*cos(t),0.5+0.4*sin(t),'white');
    temp=get(gca,'Position');
    axis([0.099 0.901 0.099 0.901])
    axis off

    index = 1;
    for i=1:len

        if( isnan(labels{i})~=1 )
            v=mapObj(labels{i});
            
            openfig(filenameContainer{index},'new','invisible');
            h = findobj(gcf,'type','axes'); % Find the axes object in the GUI
            
            %Setting size of graphs. If new size added here, it is needed
            %to also add the same size into plotLegend.m script for
            %vizualization of PS and spec
            if(length(filenameContainer) > 10)
                size = 0.1;
            else
                size = 0.14;
            end
            
            set(h,'Position',[v(1)-0.05+temp(1)/10-((size-0.1)/2),v(2)-0.05+temp(2)/10,size,size]);

            if ( sum(limits) ~= 0)
                set(h,'YLim',[limits(3) limits(4)]);
                set(h,'XLim',[limits(1) limits(2)]);
            end
            
            if ( sum(ca) ~= 0)
                caxis(ca)
            end
            
            set(h,'XTickLabel','')
            set(h,'YTickLabel','')
            x=xlabel('');
            delete(x)
            x=ylabel('');
            delete(x)
            copyobj(h,f);
            index = index+1;
        end

    end

end