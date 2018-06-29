clear
close all
close all hidden

%load positions of electrodes and all defined systems (global variables).
electrodes

%% load data

% load information from XML and .m data from the same directory example_data/
[fs,labels,origDataContainer,expertMarks] = getDataFromXml('example_data/');

% in expertMarks data is devided in to 3 classes. For this example we
% choose to show data in only one class - 35. We want to avarage the data, 
% therefor we will choose all segments classified as class 35.
class = 35; 
% length of segments in seconds
segmentLen = 2;
dataContainer35 = cell(length(origDataContainer),1);
% we will use system 10-20. In labels19 the right order of electrodes will
% be held
labels19 = getChannels('10-20',labels);
for i = 1:length(expertMarks(:,1))
    % used segments must be long enaugh. Must be long at least segmentLen.
     if( (expertMarks(i,3) == class) && (expertMarks(i,2) > (expertMarks(i,1) + segmentLen*fs)) )
        [dataContainerTemp35] = getNewContainer(origDataContainer,expertMarks(i,1),expertMarks(i,2));
        %adds new segment at bottom of matrix
        [dataContainer35] = extendDataContainer(dataContainer35,dataContainerTemp35);
    end
end   

% number of obtained segments for averaging
N35 = length(dataContainer35{1}(:,1));

%--------------------------------------------------------
% to load data from EDF (not included in CD):
% 1. create struct from EDF file
%       channels = EDF_read_write ('read', 'filename.edf');
% 2. load expert marks
%       load('expert_marks.mat');
% 3. use expert marks, for example to obtain arefact free signals
%       [newChannelsArtifactFree] = getArtifactFreeSignal(channels,expert_marks);
% 4. create struct with desairable segments
%       [newChannels] = getNRandomSegmentsOfSignal(newChannelsArtifactFree,N,segmentTime);
%       to get N segments of segmentTime length (in seconds) randomly taken
%       from the signal, or
%       [newChannels] = getSegmentOfSignal(newChannelsArtifactFree,startPosition,segmentTime);
%       to get one segment of segmentTime length starting at startPosition
%       in seconds.
% 5. get data from the struct
%       [fs,labels,dataContainer] = getDataFromStruct(newChannels);
   
 %% coherence
window = hanning(segmentLen*fs);
noverlap = 0;
% will start parallel pool
[coherenceMatrix35] = getCoherenceMatrix(dataContainer35,window,noverlap);
% array of frequency bands to show. First picture will represent delta band
% - frequencies from 0 to 4 Hz, second picture will represent alpha band -
% frequencies from 8 to 13 Hz. More frequency bands can be added in array 
% according the example.
freq=[0 4;8 13];
[dataCoh35,cohtitles35] = getCoherences(coherenceMatrix35,labels19,fs,freq);

%treshold for coherences
treshold = 0.3;
[f, width,height]=showChannelRelationGraph(dataCoh35,cohtitles35,labels19,treshold);
plotLegend(f,'coh',[treshold]);
set(f, 'position', [1 1 width height]);

path = 'temp/';
filepath = strcat( path, 'coh_35_', num2str(N35), 'averaged');
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden

 %% data for PS, PSavg, PSmap
 
% to compute psd, average psd and power topografic map, we must prepare
% container with psd.
smoothSpan = 51;
smoothMethod = 'moving';

[PSContainer35,PSref,samplesPer1Hz] = getPSContainer(dataContainer35,labels19,fs,smoothSpan,smoothMethod);

% if multiple pictures are desired to be comparable, it is necessary to
% find common PSref, typically the largest PSmax from the set

 %% PS
 
% if more PS multigraph pictures needs to be generated give everyone unique ID
ID = '';
path = 'temp';
% will store graphs in path directory (temp/)
[filenameContainerPS35,labelPSmin,labelPSmax, limits] = getPSplots(PSContainer35,samplesPer1Hz,PSref,path,ID);

% if multiple pictures are desired to be comparable, it is necessary to
% find common limits, labelPSmin and labelPSmax

[f]=plotGraphOnChannel(labels19,filenameContainerPS35,limits,0);        
plotLegend(f,'PS',[labelPSmin,labelPSmax,length(filenameContainerPS35)]);

path = 'temp/';
filepath = strcat( path, 'PS_35_', num2str(N35), 'averaged');
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden

 %% PSavg

% if more PSavg multigraph pictures needs to be generated give everyone unique ID
ID = '';
path = 'temp';
% will store graphs in path directory (temp/)
[filenameContainerPSavg35,labelPSmin,labelPSmax,limits] = getPSavgPlots(PSContainer35,samplesPer1Hz,PSref,path,ID);

% if multiple pictures are desired to be comparable, it is necessary to
% find common limits, labelPSmin and labelPSmax.

[f]=plotGraphOnChannel(labels19,filenameContainerPSavg35,limits,0);           
plotLegend(f,'PS',[labelPSmin,labelPSmax,length(filenameContainerPSavg35)]);

path = 'temp/';
filepath = strcat( path, 'PSavg_35_', num2str(N35), 'averaged');
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden

 %% PS map
 
% choose frequency band. In this case we use alpha frequencies - from 8 to 13 HZ.
band = [8,13];
[data35] = getPSmapData(PSContainer35,band,samplesPer1Hz,PSref);

PSmax = max(data35);
PSmin = min(data35);

% if multiple pictures are desired to be comparable, it is necessary to
% find common PSmax and PSmin

im = psglab_2d_map(data35,labels19,PSmin,PSmax);
f=figure(1);
imshow(im);    
plotLegend(f,'map',[PSmin PSmax]);

path = 'temp/';
filepath = strcat( path, 'PSmap_35_alpha_', num2str(N35), 'averaged'); 
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden

 %% correlation
 
% will start parallel pool
[corrMatrix35] = getCorrMatrix(dataContainer35);
[dataCorr35] = getCorrelations(corrMatrix35,labels19);
cortitles35 = {''};
% correlation treshold - correlations lower than treshold will not be shown
treshold = 0.3;
[f, width,height]=showChannelRelationGraph(dataCorr35,cortitles35,labels19,treshold);
plotLegend(f,'corr',[treshold]);
set(f, 'position', [1 1 width height]);

path = 'temp/';
filepath = strcat( path, 'corr_35_', num2str(N35), 'averaged'); 
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden

%% spectrum
window = hanning(250);
noverlap = 230;
% if more spectrum multigraph pictures needs to be generated give everyone unique ID
ID = '';
path = 'temp';
% will store graphs in path directory (temp/)
[filenameContainerSpec35,ca] = getSpectrogram(dataContainer35,labels19,fs,window,noverlap,path,ID);

% if multiple pictures are desired to be comparable, it is necessary to
% find common color axis ca

[f]=plotGraphOnChannel(labels19,filenameContainerSpec35,0,ca);
plotLegend(f,'spec',[fs,length(dataContainer35{1}),0,length(filenameContainerSpec35),ca(1),ca(2)]);

path = 'temp/';
filepath = strcat( path, 'spec_35_', num2str(N35), 'averaged');  
% picture will be stored in path directory (temp/)
save2pdf(filepath,f);
close all
close all hidden
