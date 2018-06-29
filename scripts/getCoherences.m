function [dataCoh,titles] = getCoherences(cohMat,labels,fs,freq)
% Returns cell array (Lx1) of mean coherences among frequency band defined 
% in freq and cell array (1xM) of string titles to be plotted above 
% pictures of coherences to distinguish bands.
% cohMat    - cell array (Lx1) of coherences between channels.
% labels    - cell array (Nx1) of names of the channels.
% fs        - sampling frequency of all signals
% freq      - matrix (Mx2) with lower frequency in first column and upper
%           frequency in second column. Each pair of frequencies at the
%           same row will define pass_band for one picture. freq may 
%           contain intervals <0.14,fs/2> Hz else restricted to this 
%           interval

    %number of coherences between two channels
    cohLen = length(cohMat{1}{2});   
    %number of frequency bands to be plotted (number of pictures)
    m = length(freq(:,1));    
    %number of channels
    n = length(labels);

    titles = cell(1,m);
    dataCoh = cell(length(labels),length(labels),m);

    if( (sum(sum(freq<0.14)>0)) || (sum(sum(freq>(fs/2))>0)) )
        freq(freq<0.14)=0.14;
        freq(freq>fs/2)=round(fs/2);
        warning('Frequency intervals in freq were restricted to allowed values.');
    end

    F = [(freq(:,1)*cohLen)/fs (freq(:,2)*cohLen)/fs];

    % for each picture (for each frequency band)
    for i = 1:m 
        titles{i} = [num2str(freq(i,1))  ' - '   num2str(freq(i,2))   ' Hz'];

        % computation of coherences
        for ch1 = 1:(n-1)
            if( isnan(labels{ch1})~=1 )

                for ch2 = (ch1+1):n
                    if( isnan(labels{ch2})~=1 )

                        f1=int16(F(i,1));
                        if(f1==0) f1=1; end
                        f2=int16(F(i,2));

                        x=f1:f2;

                        data=cohMat{ch1}{ch2};
                        dataCoh{ch1,ch2,i} = mean(data(x));
                       
                    end
                end
            end
        end
    end
end

