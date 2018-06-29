function [fig, width,height] = showChannelRelationGraph(data,titles,labels,minVal)
% Plots relations between EEG channels. Can plot several pictures into one
% window (figure). Returns figure holder and optimal size of the window.
% data      - cell array (Kx1) of relation coeficients of real values between -1 and 1
% titles    - cell array (1xM) of titles for individual graphs in window
% labels    - cell array (Nx1) with names of electrodes
% minVal    - real number treshold (lines won't be plotted for coeficients
%           with value minVal and lower.

    global mapObj
    t=linspace(0,2*pi);

    %number of pictures in one window
    m = length(titles); 
    n = length(labels);
    
    %number of channels
    nch = 0;
    for i=1:n
        if(~isnan(labels{i}))
            nch = nch+1;
        end
    end

    fig=figure;
    ax = gca; axis off;
    p = panel();

    % computes figure layout
    if(m<5)                          
        if(m==1)
            r = 1;
            c = 1;
        end
        if(m==2)
            r=1;
            c=2;
        end
        if(m==3)
            r=1;
            c=3;
        end
        if(m==4)
            r=2;
            c=2;
        end
    else
        %number of rows in the figure
        r = round(sqrt(m)); 
        %number of columns in the figure
        c = ceil(m/r);                 
    end
    
    screenSizes = get(0,'MonitorPositions');
    screenSize = screenSizes(1,:);   % in case of second screen extend
    [width,height] = getFigureSize(screenSize,c,r);
    
    % setting sizes for visual elements with respect to number of channels.
    if(nch > 10)
        %width of lines with coeficient 1 (highest)
        linewidth = 3;
        %radius of electrodes
        radius=0.35;
        fontcoef = 1;
    else
        linewidth = 12;
        radius=0.6; 
        fontcoef = 1.3;
    end

    p.pack(r,c);
    %for each picture
    for i = 1:m 
        pr = ceil(i/c);
        pc = ceil(mod(i,c));
        pc(pc==0)=c;
        ax(i)=p(pr,pc).select();
        axis([-5.1 5.1 -5.1 5.1])
        axis off
        axis square
        % head outline
        viscircles([0,0],5,'EdgeColor','black','LineWidth',1);
        hold on
        axis([-5.5 5.5 -5.5 5.5])
        
        text(-0.5,5.5,titles{i},'FontSize', 12*fontcoef)
        
        % plotting lines
        for ch1 = 1:(n-1)
            if( isnan(labels{ch1})~=1 )
                v1=mapObj(labels{ch1});

                for ch2 = (ch1+1):n
                    if( isnan(labels{ch2})~=1 )
                        v2=mapObj(labels{ch2});
                        value = data{ch1,ch2,i};
                        %for positive coeficients
                        if(value>0)
                            % line coloring
                            cmap=colormap(summer);      
                            k = length(colormap);
                            cmap = flipud(cmap);

                            if(value>minVal)
                                linehandler=line([v1(1)*13-6.5 v2(1)*13-6.5],...
                                                [v1(2)*13-6.5 v2(2)*13-6.5],...
                                                'lineWidth',(value-minVal)*(linewidth/(1-minVal)),...
                                                'Color', cmap(int16((k-1)*(value-minVal)/(1-minVal))+1,:));
                                uistack(linehandler, 'bottom');
                            end
                        %for negative coeficients
                        else
                            value = abs(value);
                            % line coloring
                            cmap=colormap(autumn);      
                            k = length(colormap);
                            cmap = flipud(cmap);

                            if(value>minVal)
                                linehandler=line([v1(1)*13-6.5 v2(1)*13-6.5],...
                                                [v1(2)*13-6.5 v2(2)*13-6.5],...
                                                'lineWidth',(value-minVal)*(linewidth/(1-minVal)),...
                                                'Color', cmap(int16((k-1)*(value-minVal)/(1-minVal))+1,:));
                                uistack(linehandler, 'bottom');
                            end
                            
                        end
                    end
                end
            end
        end
        
        % plotting channels
        len = length(labels);
        for l = 1:len
            if( isnan(labels{l})~=1 )
                v=mapObj(labels{l})*13;

                cir = fill(v(1)+radius*cos(t)-6.5,v(2)+radius*sin(t)-6.5,'white');
                uistack(cir, 'top');
                
                fontsize = [12, 12, 9, 7, 7, 7]*fontcoef; 
                
                % channel labels off for more than 6 pictures in one
                % window.
                if(m<7)
                    text(v(1)-6.8,v(2)-6.5,labels{l},'FontSize',fontsize(m));
                end
            end
        end
        axis off

    end

end

