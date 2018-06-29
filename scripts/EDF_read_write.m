function varargout = EDF_read_write (varargin)

% Created by Jan Bukartyk

%% ToDo:
% EDF+ not supported - only continuous data
% data with lower fs then 1 Hz might not work for writing


%% CHANGE LOG
% 2012,03,01 - Created 1st version
% 2013,01,30 - making the functionality only for continuous data - merging all Data Records
% 2013,01,30 - fully functional reading function with all the input parameters fully working
% 2013,02,07 - Changed some variable names for header (Duration -> DRduration; DataRecords -> DRcount; number_of_samples -> samples_in_DR)
%            - preventing Matlab error when filepath invalid, add fs[Hz] in channel info
% 2013,04,01 - Corrected not finished code for Physiological limits calculation (code from whole number only was left by mistake)
% 2013,05,31 - Fixed ChannelCount in header when Channel selection used
% 2013,06,03 - Fixed Time and Date adjustment after the Crop is applied
% 2013,06,04 - Found and repair bug for the Crop - the last non complete data record would not read correctly (copy paste bug)
% 2013,06,19 - Changed default DRduration to 1 (set if not specified) from DataLength
% 2013,09,03 - Added progress [%] counting during the EDF file reading
% 2013,09,14 - cleared some memory before writing the file which should help to lower the max available memory demand
%            - Fixed when crop inside only one Data Record (added: '% READ PART -EXCEPTION-')
% 2013,09,16 - Add 'rmfield(edf.header, 'DRcount');' to remove DRcount from field during reading (not neede + when crop applied it is wrong value)
%            - Add Crop info into 'edf.header.Reserved'
% 2013,11,04 - Will not write 'EDF+C' when not specified as it mean it is EDF+ format which would have to have annotation signal
% 2013,11,08 - corrected mistake when instead of 'EDF+C' put '' which eraced those charactes causing shortening the string and shifting in any other information
% 2013,12,16 - Create directory of the ouput path if it does not exist
% 2014,01,22 - Added functionality for updating header without involving data (some duplication from Write!)
%            - parse inputs tune up
%            - function description tune up
%            - PatientID, RecordingID, Reserved - remove empty space before & after the text
% 2014,01,27 - Add EDF StartDateYMD and StartTimeHMS to read/write/writeheader
%            - Enhanced WriteHeader's resistance to wrong inputs and their error messages
% 2014,02,04 - Improved writing numerical values in the channel headers - maximalize usage of the 8 characters per number
%               - created custom function for num2str conversion (num2strMaxChar)
% 2014,02,06 - Corrected progress count when EDF read (if not all channels read)
% 2014,03,18 - description clarified - crop times - automatic adjustment
% 2014,06,20 - typo: dips corrected to disp -> disp('Warning: File extension changed to *.edf');
% 2014,08,13 - EDF write - edf.header.StartDateYMD - fixed error when year value is entered in YYYY format rather then YY



%% ---------------------- EXAMPLES ----------------------------------------
% EDF = W_read_write ('read', 'c:\...');
% EDF = W_read_write ('r',    'c:\...', 'double', 'crop',[0 100], 'ch', [1 5 6 7]);
%       W_read_write ('write','c:\...', edf);

% only header modification without involving data
%  EDF = W_read_write ('r', 'c:\...','ch',0);
%  ... header modification, some parameters directly linkded
%      to how the data are written are not allowed to be changed
%  W_read_write ('wh', 'c:\...', EDF);


%% --------------- EDF Output variable structure --------------------
% The same structure is needed when writing to EDF
% * are required fields for WRITE!!
% edf.header =
%    EDFversion:   '0       ' [8 char]
%    PatientID:    [80 char]  Ex1: ‘MCR-1-555-666 F 05-JUN-1975 Haagse_Harry’; Ex2: ‘X X X 012’ where 012 == de-ID as a name
%    RecordingID:  [80 char]  Ex1: ‘Startdate 06-NOV-2007 PSG-1234/2002 NN Telemetry_03’; Ex2: ‘Startdate 06-NOV-2007 X X X’
%    StartDate:    '07.03.09' [dd.mm.yy] (85-99):1985-1999; (00-84):2000-2084; >2084-> yy=’yy’ and only "RecordingID" defines the date
%    StartDateYMD: [9 3 7]    numeric values, if parameter exists with values => USED for writing
%    StartTime:    '13.57.35' [hh.mm.ss] - kept for compatibility with older scripts
%    StartTimeHMS: [13 57 35] numeric values, if parameter exists with values => USED for writing
%    Reserved:     [44 char]
%    DRcount:      90         recording splited to parts of same duration (for all EDF versions)
%    DRduration:   10         duration of Data Record - Duration of recording = DRcount * DRduration
%    ChannelCount: 20
     
% edf.ch(1:ChannelCount) =
%  * label         'EEG Fpz-Cz' % see EDF standard text rules
%    transducer
%    unit          'uV      ' % EDF name: physical_dimension
%    physical_min             EDF name: physical_minimum
%    physical_max             EDF name: physical_maximum
%    digital_min              EDF name: digital_minimum
%    digital_max              EDF name: digital_maximum
%    filters       'HP:0.1Hz LP:75Hz NOTCH:0'   % EDF name: prefiltering
%    samples_in_DR            EDF name: Number of Samples in Data Record
%    reserved      [32 bytes]
%  * fs            512        % calculated sampling frequency [Hz]
%  * data                     % numeric vector (int16 or single/double) - in EDF stored only in int16


%% ---------------------- INPUTs ------------------------------------------
% The input parameter strings are NOT case sensitive

% [...] = W_read_write ('read', 'c:\...')
% [...] = W_read_write (..., 'Param1', value1, 'Param2', value2, ...)

% REQUIRED:
% 1st   'r'  / 'read'
%       'w'  / 'write'
%       'wh' / 'write header'
% 2nd   filepath: 'c:\folder\...\filename.w' - path with filename *.w

% REQUIRED only for WRITE:
% 3rd   STRUCT VARIABLE: containing: file header + channels headers + data (see structure above)
%       the data type the data are store with decide whather conversion will be applied before writing to file
%         - 'int16'              - writen as is
%         - 'single' or 'double' - will be converted to 'int16' and header Phy/Dig_min/max will be calculated
%         - It is decided on channel basis (1st channel can be 'int16' and the 2nd 'double' (just the 2nd will be converted!)

% REQUIRED only for WRITE HEADER:
% 3rd   STRUCT VARIABLE: containing: file header + channels headers
%           - Any other information like data are ignored

% OPTIONAL for READ  (anywhere after the required inputs):
%    'channels'/'ch'   followed by [1,2,11...]/0/-1/'all'/{'ECG','emg'}
%    'crop'/'select'   followed by [start stop] in seconds
%                      the times may be slightly adjusted to fit the channel with lowest sampling frequency
%    'double', 'convert', 'real'
%                      All channels will be converted from 'int16' to physiological
%                         values in 'double' data type
%                      It does not have any value, just the parameter alone



%% ---------------------- INPUTs Details ----------------------------------

%  'channels'/'ch'  -  channels to import
%      = not present/-1 -> all channel headers and data will be read
%      = 0 -> No data, just headers will be read
%                 when the headers are known, just certain channels can be specified and read     
%      = vector [1,2,5,11,...] -> reading headers and data just for the specified channels
%                 Channel number depends on the order the channels are physicaly writen in the file
%                 If channel number is higher then the channel count => it will be ignored

%  'crop'/'time'  -  Time Interval to specify what part of data will be imported [seconds]
%      = vector [start stop] -> values in seconds
%               start < stop, with exception of stop equal to -1, which stands for "the end" of the recording
%
%               [10 50] -> crop from 10 sec to 50 sec from the begining of the recording
%               [0 -1] -> from the begining to the end
%               [500 -1] -> from 500sec to the end
%
%          The times may be slightly adjusted to fit the channel
%              with the lowest sampling frequency in the EDF file


if nargin < 2
   disp('There are not enought input variables specified');
   return;
end


%% READ
if strcmpi(varargin{1},'r') || strcmpi(varargin{1},'read')
   
   % Parse inputs
   [FilePath, Channels, Crop, DataConvert] = Parse_inputs_Read (varargin{:});
   if isempty(FilePath), varargout{1} = []; return; end % wrong path
   
   varargout{1} = EDF_read (FilePath, Channels, Crop, DataConvert);
   return;
end


%% WRITE
if strcmpi(varargin{1},'w') || strcmpi(varargin{1},'write')
   
   % Parse inputs
   [FilePath, edf] = Parse_inputs_Write (varargin{:});
   if isempty(FilePath) || isempty(edf), return; end % wrong path or not valid data
   
   EDF_write (FilePath, edf);

   return;
end 


%% WRITE HEADER ONLY
if strcmpi(varargin{1},'wh') || strcmpi(varargin{1},'write header')
   
   % Parse inputs
   [FilePath, EDFh] = Parse_inputs_WriteHeader (varargin{:});
   if isempty(FilePath) || isempty(EDFh), return; end % wrong path or not valid data
   
   EDF_writeHeader (FilePath, EDFh);

   return;
end 

disp('The first input have to specify the mode: ''r''/''read'' or ''w''/''write''');
return;








%% PARSE INPUTS for READ
function [FilePath, Channels, Crop, DataConvert] = Parse_inputs_Read (varargin)

% Default values
FilePath = varargin{2};
Channels = -1; % all channels
Crop = [0 -1]; % whole length
DataConvert = 0; % output data will be int16 as stored in EDF file (no conversion)

% check if the path is valid and it is a file, not folder
D = dir(FilePath);
if isempty(D) || isdir(FilePath) == 1
   disp('Input Error: The second input argument needs to be Filepath to a file including extension');
   FilePath = [];
   return;
end

InputsUsed = zeros(1,nargin-2,'int8'); % keep track of which inputs were recognized and used

% Parameters and its values
for i = 3:nargin
   if ~ischar(varargin{i})
      continue; % skip inputs which are not char type
   end
   
   switch lower(varargin{i})
      
      case {'channels', 'ch'}
         InputsUsed(i-2:i-1) = 1;
         V = varargin{i+1}; % V ... abbreviation for value
         if ~isnumeric(V)
            disp('Input Error: The channel selection can contain only numeric vector!');
            disp('Resolution: Only headers will be read');
            Channels = 0; continue;
         end
         if max(V < 1) && max(V~=-1) && max(V~=0)
            % no number can be less then -1, when multiple channels - non of them can be -1 or 0
            disp('Input Error: The channel number cannot be less then 1, with exception of single number of 0 or -1');
            disp('Resolution: Only headers will be read');
            Channels = 0; continue;
         end
         if length(V)>1 && max(V < 1)
            disp('Input Error: Channel vector cannot contrain 0 or -1; 0 for reading just header, -1 for reading all channels');
            disp('Resolution: Only headers will be read');
            Channels = 0; continue;
         end
         Channels = V;
         
         
      case {'crop', 'time'}
         InputsUsed(i-2:i-1) = 1;
         V = varargin{i+1}; % V ... abbreviation for value
         if length(V) ~= 2 || ~isnumeric(V)
            disp('Input Error: ''crop''/''time'' parameter: required numeric vector of exactly two values; [start stop]; in seconds from the begining of the recording.');
            disp('Resolution: Whole record will be read');
            continue;
         end
         if V(2)~=-1 && V(1)>V(2)
            disp('Input Error: ''crop''/''time'' parameter: the 2nd value in the vector needs to be higher then the 1st value.');
            disp('Resolution: Whole record will be read');
            continue;
         end
         if V(1) < 0
            disp('Input Error: ''crop''/''time'' parameter: the 1st value cannot be smaller then 0');
            disp('Resolution: Changed to zero');
            V(1) = 0;
         end
         Crop = V;
         
         
      case {'double', 'convert', 'real'}
         % it does not have any value, only the parameter
         % data will be converted from int16 to double with physyological values
         InputsUsed(i-2) = 1;
         DataConvert = 1;
   end
end

if min(InputsUsed) == 0
   disp('Warning: Some input parameters were not recognized:');
   I = find(InputsUsed == 0) + 2;
   varargin{I} % will show them in command window
end




%% Read EDF file
function edf = EDF_read (FilePath, Channels, Crop, DataConvert)
% OPEN FILE FOR READING
fid = fopen(FilePath);

%% READ FILE HEADER

% Load the whole File Header
FileHeader = fread(fid,256)';

% Create a "File" structure containing the File Header

% (x) 'My EDF description.docx' bullet point

% (1)
edf.header.EDFversion = char(FileHeader(1:8));

% (2)
edf.header.PatientID = RemoveSpaces_BeforeAndAfter_Text (char(FileHeader(9:88)));
% Local patient identification
% For example:
% 		‘MCR-1-555-666 F 05-JUN-1975 Haagse_Harry’
% 		‘X X X 012’ where 012 is de-ID for the patient name

% (3)
edf.header.RecordingID = RemoveSpaces_BeforeAndAfter_Text (char(FileHeader(89:168)));
% Local recording identification
% For example:
% 		‘Startdate 06-NOV-2007 PSG-1234/2002 NN Telemetry_03’
% 		‘Startdate 06-NOV-2007 X X X’

% (4)
edf.header.StartDate = char(FileHeader(169:176));
N = Find_separate_WholeNumbers_inString( edf.header.StartDate );
edf.header.StartDateYMD = [N(3) N(2) N(1)];
% Start date of recording
% 'dd.mm.yy'
% possible years 1985 - 2084

% (5)
edf.header.StartTime = char(FileHeader(177:184));
N = Find_separate_WholeNumbers_inString( edf.header.StartTime );
edf.header.StartTimeHMS = N;
% Start time of recording
% 'hh.mm.ss'

clear N;

% (6)
HeadersSize = str2double(char(FileHeader(185:192)));
% Used just for verification!
% Number of bytes for all headers (file header + channels header)
% In other words index of the header's last byte
% this can be easily calculated from the other information

% (7)
edf.header.Reserved = RemoveSpaces_BeforeAndAfter_Text (char(FileHeader(193:236)));
% Reserved
% EDF+:
%  ‘EDF+C’	for EDF+ … recording is continuous, not interrupted (EDF compatible!)
%  ‘EDF+D’	for EDF+ … recording is interrupted, not continuous

% (8)
edf.header.DRcount = str2double(char(FileHeader(237:244)));
% Number of data records in EDF+ - for neurology, number of interrupted parts (data records)
% [# of recording parts]

% (9)
edf.header.DRduration = str2double(char(FileHeader(245:252)));
% duration of a data record, in seconds
% the recording can be and usually is splited to many parts with fixed duration = data record
% [sec]

% (10)
edf.header.ChannelCount = str2double(char(FileHeader(253:256)));
% Number of signals/channels (ns) in EDF file (continuous) or each data record (multiple parts, EDF+)
% [# of channels]


%% READ DATA HEADERs
% The data header contain headers for all channels (data signals)
% Create a record structure edf.ch. Populate it with description for each signal

% Vector of one Channel header field lenght
% CAUSION, one channel info is not continuous!
%  - it is sorted by the header information below
%  - first will be labels for all changes, then transducer types for all channels, etc.
DataHeader_1Ch_Indexes = ...
   [16 ; ... % * nCh ... labels (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    80 ; ... % * nCh ... transducer types (e.g. AgAgCl electrode)
    8 ; ...  % * nCh ... units, physical dimensions (e.g. uV or degreeC)
    8 ; ...  % * nCh ... physical minimums (e.g. -500 or 34)
    8 ; ...  % * nCh ... physical maximums (e.g. 500 or 40)
    8 ; ...  % * nCh ... digital minimums (e.g. -2048)
    8 ; ...  % * nCh ... digital maximums (e.g. 2047)
    80 ; ... % * nCh ... filters, prefilterings (e.g. HP:0.1Hz LP:75Hz)
    8 ; ...  % * nCh ... # of samples in each data record
    32] ; ...% * nCh ... reserved
    
% Variable name shortening
nCh = edf.header.ChannelCount; % Number of channels(signals)
 
% indexes of field ends for all channels counted for
DataHeader_Indexes = nCh * DataHeader_1Ch_Indexes;

DataHeader = fread(fid,sum(DataHeader_Indexes));


% struct "edf.ch" field labels
dhFields = {...
    'label',...
    'transducer',...
    'unit',...
    'physical_min',...
    'physical_max',...
    'digital_min',...
    'digital_max',...
    'filters',...
    'samples_in_DR',...
    'reserved'};

% Fill the Channel fields with the header data
% first parameter (string)
 FieldChar = char(reshape(DataHeader(1:DataHeader_Indexes(1)),DataHeader_1Ch_Indexes(1),nCh)');
 edf.ch = struct(dhFields{1}, cellstr(FieldChar));
for k = 2:length(DataHeader_Indexes)
   FieldChar = char(reshape(DataHeader(sum(DataHeader_Indexes(1:k-1))+1:sum(DataHeader_Indexes(1:k))), DataHeader_1Ch_Indexes(k),nCh)');
   FieldValue = cellstr(FieldChar);
   if max(k == [4 5 6 7 9])
      % convernt numeric parameters in cell char to number
      FieldValue = cellfun(@str2double,FieldValue); % convert to numeric vector
      for i=1:nCh
         edf.ch(i).(dhFields{k}) = FieldValue(i); % I could not find how to do it without loop
      end
   else
      % original string
      [edf.ch.(dhFields{k})] = deal(FieldValue{:});
   end
end

clear FieldChar FieldValue;


%% Parse the input: "Channels"
if length(Channels) == 1 && Channels(1) == 0 
   % no channel data will be read => done with the function
   for ch = 1:nCh
      edf.ch(ch).fs = edf.ch(ch).samples_in_DR ./ edf.header.DRduration; % sampling frequency [Hz]
   end
   fclose(fid);
   return;

elseif Channels(1) == -1
   % read data for ALL channels
   Channels = 1 : edf.header.ChannelCount;

elseif max(Channels > edf.header.ChannelCount)
   % only if some channels specified are higher then the channel count
   disp(' ');disp('Warning: Some of the specified channels exceeds the channel count! They will be ignored.');
   disp(['   Channel count is: ', num2str(edf.header.ChannelCount)]);
   Channels(Channels > edf.header.ChannelCount) = [];
end

Channels(Channels == 0) = []; % in case there are zeros among valid channel indexes

if isempty(Channels)
   disp('Input Error: There are no valid channels in your selection! No data will be read.');
   fclose(fid); return;
end
   


%% Prepare for Crop
T_DR = edf.header.DRduration; % duration of one DataRecord [seconds]
SampPerDR = [edf.ch(1:nCh).samples_in_DR]; % Samples per DataRecord for each channel
Fs(1:nCh) = SampPerDR ./ T_DR; % channel sampling frequency[Hz]

if Crop(2) == -1
   % will assign the duration
   Crop(2) = edf.header.DRcount * T_DR;
end

if Crop(2) > edf.header.DRcount * edf.header.DRduration
   % In case the crop limit is set above the data duration
   disp(' ');disp('Warning: The Crop value for END was set above the data lenght.');
   disp(['Data duration is: ',num2str(edf.header.DRcount * T_DR),' seconds']);
   Crop(2) = edf.header.DRcount * edf.header.DRduration;
end

if Crop(2) <= Crop(1)
   % no channel data will be read => done with the function
   disp(' ');disp('Warning: The Cropped area starts outside the data duration');
   disp(' => NO DATA WILL BE READ! See read headers for more info.');
   for ch = 1:nCh
      edf.ch(ch).fs = edf.ch(ch).samples_in_DR ./ edf.header.DRduration; % sampling frequency [Hz]
   end
   fclose(fid);
   return;   
end

% Crop times adjustment to comply with the lowest Fs in the edf file
Crop(1) = floor(Crop(1)*min(Fs))./min(Fs); % rounded to the nearest lower value
Crop(2) =  ceil(Crop(2)*min(Fs))./min(Fs); % rounded to the nearest higher value

% Calculation of starting and ending DataRecords for Crop
DRcrop = Crop ./ T_DR;   % not complete calculation of: DR which the crop starts/ends with
DRcropPart = DRcrop - floor(DRcrop); % exact start/end whithin the DR [percentual]
DRcrop(1) = ceil(DRcrop(1))+1; % whole DR index which the crop starts with
DRcrop(2) = floor(DRcrop(2));  % whole DR index which the crop ends with
DRcountWhole = DRcrop(2)-DRcrop(1)+1; % number of whole DataRecords in the crop (partial does not count)

% DRcrop, DRcountWhole & DRcropPart WILL BE USED TO READ THE DATA
%  - DRcropPart will allow to read just part of the DataRecord exacly as specified by the "Crop"



%% READ DATA

% Calculating the end of headers (one byte before the data starts)
HeaderEnd = 256 + sum(DataHeader_Indexes); % Index of All headers end
if HeaderEnd ~= HeadersSize
   disp('Warning: The Headers_Size noted in the file header is different from the one calculated from Channel_Count and other parameters.');
end


Progress = 0;
%fprintf('EDF loading: %03d%%',Progress); % progress display

for i = 1 : length(Channels)
   ch = Channels(i);
   
   %if ceil(i/length(Channels)*100) > Progress
    %  Progress = ceil(i/length(Channels)*100);
    %  fprintf('\b\b\b\b\b %03d%%',Progress);
   %end
   
   % READ PART -1-
   % READ begining partial DataRecord in the Crop (if any)
   if DRcropPart(1) > 0 && DRcountWhole >= 0
      
      % # of samples before the crop inside the DR
      SamplesBefore = DRcropPart(1) * SampPerDR(ch);
      
      PreviousEnd = HeaderEnd +2*( sum(SampPerDR(:))*(DRcrop(1)-2) +sum(SampPerDR(1:ch-1))+SamplesBefore);
      
      % point at the PreviousEnd in the file
      status = fseek(fid,PreviousEnd,-1);
      if status == -1, error('Error while reading Channel Data from the file'); end
      
      Int16_partial_1stDR = fread(fid, SampPerDR(ch)-SamplesBefore, '*int16')';
   else
      Int16_partial_1stDR = [];
   end
   
   
   % READ PART -2-  
   % READ the WHOLE DataRecords from the Crop      
   if DRcountWhole > 0
     % inicialization
     Int16_wholeDRs = zeros(0,'int16');
     Int16_wholeDRs(SampPerDR(ch) * DRcountWhole) = 0;
    DRindex = 0; % because of Crop the DR index cannot be used to index save data  
    for DR = DRcrop(1) : DRcrop(2)
      
       DRindex = DRindex + 1; % indexind DR for saving the read data
      
       % PreviousEnd -> one Byte before the whole DataRecord starts
       PreviousEnd = HeaderEnd + ...
          2* ( sum(SampPerDR(:)) * (DR-1) +       sum(SampPerDR(1:ch-1)));
               %Shifts to the right Data Record   %Shift to the right channel
          % times 2 because 2 bytes number
      
       % point at the PreviousEnd in the file
       status = fseek(fid,PreviousEnd,-1);
       if status == -1, error('Error while reading Channel Data from the file'); end
         
       % Read DATA for each channel - it is read as 2 Bytes per number (int16)
       Int16_wholeDRs(SampPerDR(ch)*(DRindex-1)+1 : SampPerDR(ch)*DRindex) = ...
              fread(fid, SampPerDR(ch), '*int16');
   end
   else
      % in case there is no whole DR in the cropped area
      Int16_wholeDRs = zeros(0,'int16');
   end
   

   % READ PART -3-
   % READ partial DataRecord at the end in the Crop (if any)
   if DRcropPart(2) > 0 && DRcountWhole >= 0
      
      PreviousEnd = HeaderEnd +2*( sum(SampPerDR(:))*(DRcrop(2)) +sum(SampPerDR(1:ch-1)));
      
      % point at the PreviousEnd in the file
      status = fseek(fid,PreviousEnd,-1);
      if status == -1, error('Error while reading Channel Data from the file'); end
      
      % # of signal samples in the incomplete last DR
      Samples = DRcropPart(2) * SampPerDR(ch);
      
      Int16_partial_lastDR = fread(fid, Samples, '*int16')';
   else
      Int16_partial_lastDR = [];
   end
   
   
   % READ PART -EXCEPTION-
   % The crop is inside one DataRecord
   if DRcountWhole == -1
      
      % # of samples before the crop inside the DR
      SamplesBefore = DRcropPart(1) * SampPerDR(ch);
      
      PreviousEnd = HeaderEnd +2*( sum(SampPerDR(:))*(DRcrop(1)-2) +sum(SampPerDR(1:ch-1))+SamplesBefore);
      
      % point at the PreviousEnd in the file
      status = fseek(fid,PreviousEnd,-1);
      if status == -1, error('Error while reading Channel Data from the file'); end    
      
      % # of signal samples in the incomplete last DR
      Samples = (DRcropPart(2)-DRcropPart(1)) * SampPerDR(ch);
      Int16_partial_DR_only = fread(fid, Samples, '*int16')';
   else
      Int16_partial_DR_only = [];
   end
   
   
   % Sampling frequency [Hz]
   edf.ch(ch).fs = edf.ch(ch).samples_in_DR ./ edf.header.DRduration; 
   
   
   if DataConvert == 0
      % Keep data in "int16" format as stored in EDF file
      edf.ch(ch).data = [Int16_partial_1stDR, Int16_wholeDRs, Int16_partial_lastDR, Int16_partial_DR_only];
      
   else
      % Convert the int16 data to real values in 'double'!
      x(1) = edf.ch(ch).digital_min;   x(2) = edf.ch(ch).digital_max;
      y(1) = edf.ch(ch).physical_min;  y(2) = edf.ch(ch).physical_max;
      k = (y(2)-y(1)) ./ (x(2)-x(1));
      q = y(1) - k .* x(1);
      
      edf.ch(ch).data = double([Int16_partial_1stDR, Int16_wholeDRs, Int16_partial_lastDR, Int16_partial_DR_only]) .*k + q;
   end
   
end
fclose(fid);


%% Adjust Headers Information to match the modification - Crop, Channel selection

DurationOrig = (edf.header.DRcount * edf.header.DRduration); % original signal duration in seconds
DurationRead = Crop(2)-Crop(1); % cropped duration
edf.header.Reserved = RemoveSpaces_BeforeAndAfter_Text (edf.header.Reserved);
if DurationOrig > DurationRead
   % in edf.header.reserved put the note about the crop
   if ~isempty(edf.header.Reserved), edf.header.Reserved = [edf.header.Reserved,'; ']; end % add semicolon if info present
   edf.header.Reserved = [edf.header.Reserved,'Cropped[sec]:',num2str(Crop(1)),'-',num2str(Crop(2))];
end

% DRcount is not needed, the value would be wrong in case crop is applied
edf.header = rmfield(edf.header, 'DRcount');

if length(Channels) < edf.header.ChannelCount || ... % if importing just some channels
      sum(abs(Channels - 1:edf.header.ChannelCount)) > 0 % if the order is different
   % will delete the channel headers without data (which were not chosen to import)
   
   
   for i=length(Channels):-1:1
      ChKeep(i) = edf.ch(Channels(i));
   end
   edf.ch = ChKeep;
   
   % Adjust the ChannelCount
   edf.header.ChannelCount = length(Channels);
   
end


% Recalculate the Study Start Time in case the data were cropped
if Crop(1) > 0
   
   [H, M, S] = Read_TimeOrDate (edf.header.StartTime);
    
   if H > -1
      % add the crop time to the Start Time
      T = Sec_to_DHMSms (S+ M*60+ H*3600 + round(Crop(1)));
      
      % Record new START TIME
      edf.header.StartTime = [num2str(T.h,'%2.2d'),'.',num2str(T.m,'%2.2d'),'.',num2str(T.s,'%2.2d')];
      
      if T.days > 0
         % if time jumped over midnight => add one day to the date
         [Day, Month, Year] = Read_TimeOrDate (edf.header.StartDate);
         
         if Day > -1
            D = datenum([Year,Month,Day]) + round(T.days);
            
            % Record new START DATE
            edf.header.StartDate = datestr(D,'dd.mm.yy');
            
         else
            % the Date could not be read from header (unknown format)
            disp(' ');disp('Error: the study START DATE could not be read! Unknown format.');
            disp('Warning: Study START DATE will not be adjusted according the Cut selection.');
         end
      end
      
   else
      % The time could not be read from header (unknown format)
      disp(' ');disp('Error: the study START TIME could not be read! Unknown format.');
      disp('Warning: study START TIME will not be adjusted according the Cut selection.');
   end
end




function Text = RemoveSpaces_BeforeAndAfter_Text (Text)
%% removes spaces on the begining and at the end of the text (will keep all the spaces inside the text)

S = Text == ' '; % indexes of spaces
T = find(S==0); % indexes of text (anything else then space)

if isempty(T)
   Text = ''; % there is no text detected
else
   Text(T(end)+1:end)=[]; % remove the spaces on the end
   Text(1:T(1)-1)=[]; % remove spaces before the text starts
end




function [Num1, Num2, Num3] = Read_TimeOrDate (Str)
%% will convert Time or Date string to numeric vector
% Time: [H, M, S]
% Date: [D, M, Y]

% in case the rule for two digits would not be fallowed
% + if a different symbol would be used as a value separator
Symbols = {'.',',',':','-','/','_'};
for s=1:length(Symbols)
   I = strfind(Str,Symbols{s}); 
   if ~isempty(I)
      break;
   end
end

if ~isempty(I) && length(I) == 2
   % reading the time from EDF
   Num1 = str2double( Str(1 : I(1)-1));      % Hour or Day
   Num2 = str2double( Str(I(1)+1 : I(2)-1)); % Min  or Month
   Num3 = str2double( Str(I(2)+1 : end));    % Sec  or Year

else
   % when the value separator cound not be located in the string
   Num1 = -1; Num2 = -1; Num3 = -1;
end




function T = Sec_to_DHMSms (Sec)
%% converts seconds to numbers of days, hours, minutes, seconds and miliseconds
% for example: 80883.000583999 -> T.days=0, T.h=22, T.m=28, T.s=3, T.ms=000583999 
% Output: T.days, T.h, T.m, T.s, T.ms

% number of whole days
T.days = floor(Sec / (24*3600));

% Seconds count less then a day
Sec = Sec - T.days*(24*3600);
T.h = floor(Sec / 3600);

% Seconds count less then an hour
Sec = Sec - T.h*3600;
T.m = floor(Sec / 60);

% Seconds count less then an minute
Sec = Sec - T.m*60;
T.s = floor(Sec);

% milisecons
T.ms = Sec - T.s;



function Numbers = Find_separate_WholeNumbers_inString (String)
%% will find any whole numbers in the input string
%% output is numeric vector
% any character which is not "0123456789" will separate present numbers
% example: 'number: 12.457 is higher then 5' will return [12 457 5]
% if no number is found [] will return

Numbers = [];

if ~ischar(String)
   disp('Error: The input for function "Find_separate_WholeNumbers_inString" has to be STRING!');
   return;
end

Native = unicode2native(String);
Native = [0 Native 0]; % when the number is on the begining or the end - to make the algorithm easier
Numeric(length(Native)) = false;
Numeric(Native>=48 & Native <=57) = 1; % mark numeric string values

i=1:length(Numeric)-1;
Edge = find(Numeric(i) ~= Numeric(i+1)); % find edge of each number
Edge(1:2:end) = Edge(1:2:end)+1;

for e = length(Edge)-1:-2:1
   Numbers((e+1)/2) = str2double(String( Edge(e)-1 : Edge(e+1)-1 )); % -1 is to remove the added 0 on the begining of the string
end






%% PARSE INPUTS for WRITE
function [FilePath, edf] = Parse_inputs_Write (varargin)

if length(varargin) < 3
   disp('Error: EDF write has to have 3 inputs: "''w'',FilePath,EDFstructure"');
   return;
end

% Default values
FilePath = [];
edf = [];

% Check if the path is valid
I = find(varargin{2} == '\');
if isempty(I) || ~isdir(varargin{2}(1:I(1)));
   % basic check if it is a folder path
   disp('Input Error: The second input argument needs to be Filepath to a file including extension');
   return;
end
FilePath = varargin{2};
if ~strcmpi(FilePath(end-2:end),'edf')
   FilePath = [FilePath,'.edf'];
   disp('Warning: File extension changed to *.edf');
end

% Check EDF structure
V = varargin{3};
if ~isstruct(V)
   disp('Input Error: the data type for input data has to be STRUCT'); return;
end

% Required fields:
Fields = {'label', 'fs', 'data'};
for f=1:length(Fields)
   if ~isfield(V.ch,Fields{f})
      disp(['Input Error: X.ch.',Fields{f},' does not exist!']);
      disp('Script Terminated!!!');
      return;
   end   
end
edf = varargin{3};

if length(varargin) > 3
   disp('Warning: there are unsupported inputs. There is only 3 inputs supported!');   
end




%% PARSE INPUTS for WRITE HEADER
function [FilePath, EDFh] = Parse_inputs_WriteHeader (varargin)

FilePath = []; EDFh = [];

if length(varargin) < 3
   disp('Error: EDF Header Write has to have 3 inputs: "''wh'',FilePath,EDFheaderStructure"');
   return;
end

FilePath = varargin{2};
% check if the path is valid and it is a file, not folder
D = dir(FilePath);
if isempty(D) || isdir(FilePath) == 1
   disp('Input Error: The second input argument needs to be Filepath to an EDF file');
   return;
   
elseif ~strcmpi(FilePath(end-3:end), '.edf')
   disp('Input Error: The second input argument needs to be Filepath to an EDF file');
   return;
end

% Check if EDFh is structure  type
V = varargin{3};
if ~isstruct(V)
   disp('Input Error: the data type for input data has to be STRUCT');
   return;
end

% Required fields in the EDFh (header):
Fields = {'label', 'transducer', 'unit', 'physical_min', 'physical_max'};
for f=1:length(Fields)
   if ~isfield(V.ch,Fields{f})
      disp(['Input Error: X.ch.',Fields{f},' does not exist!']);
      disp('Script Terminated!!!');
      return;
   end   
end
EDFh = varargin{3};

if length(varargin) > 3
   disp('Warning: there are unsupported inputs. There is only 3 inputs supported!');
end




function EDF_write (FilePath, edf)
% there are two ways to set DRcount by default if not specified
% 1. DRcount will be 1 and DRduration will be same as the length of the recording
% 2. DRcount will be calculated for DRduration = 1 second (higher values could cause unnecessary crop of the data)
% option (2) is used

%% calculation of the recording duration and set DRcount and DRduration(if not specified)
Fs = cell2mat({edf.ch.fs});
I = find(Fs==min(Fs));
DataLength = floor(length(edf.ch(I(1)).data)/min(Fs)); % [seconds], It has to be whole number => floor

if isfield (edf,'header') && isfield (edf.header,'DRduration') && ~isempty(edf.header.DRduration)
   % the DRduration is set
   if ~isnumeric(edf.header.DRduration)
      edf.header.DRduration = str2double(edf.header.DRduration);
   end
   edf.header.DRduration = floor(edf.header.DRduration); % has to be whole number (precausion) 
   
else
   % DRduration is NOT set => devault value will be applied
   edf.header.DRduration = 1;
end

DRcount_calc = floor(DataLength / edf.header.DRduration); % counts only whole records
% check if the calculated DRcount is the same as specified
if isfield (edf.header,'DRcount') && ~isempty(edf.header.DRcount)
   % is set up in the function inputs
   if ~isnumeric(edf.header.DRcount)
      edf.header.DRcount = str2double(edf.header.DRcount);
   end
   if edf.header.DRcount ~= DRcount_calc
      disp(['Warning: The specified DRcount value "',num2str(edf.header.DRcount),...
            '" is different from the calculated value "',num2str(DRcount_calc),'"!']);
      edf.header.DRcount = DRcount_calc;
   end
   
else
   % not set up => calculated value will be used
   edf.header.DRcount = DRcount_calc;
end

% the last data record would not be complete => will not be writen
% info: EDF does not support lengths not rounded to seconds

clear DataLength Fs I DRcount_calc;

% At this point the following variables are correct and set:
% - edf.header.DRcount
% - edf.header.DRduration



%% Check ChannelCount correctnes(if specified), otherwise set it from calculated value
ChannelCount_calc = length(edf.ch);
if isfield(edf.header,'ChannelCount') && ~isempty(edf.header.ChannelCount)
   % Compare set edf.header.ChannelCount(if exist) with calculated ChannelCount_calc
   if ~isnumeric(edf.header.ChannelCount)
      edf.header.ChannelCount = str2double(edf.header.ChannelCount);
   end   
   if edf.header.ChannelCount ~= ChannelCount_calc
      disp(['Warning: The specified ChannelCount value ''',num2str(edf.header.ChannelCount),...
            ''' is different from the calculated value ''',num2str(ChannelCount_calc),'''!']);
      edf.header.ChannelCount = ChannelCount_calc;
   end
   
else
   edf.header.ChannelCount = ChannelCount_calc;
end

edf.header.HeaderEnd = 256 + 256 * ChannelCount_calc; % File Header = 256 Bytes, one channel heade = 256 Bytes



%% Filling out the File Header
Header(1:256) = ' '; % initialize file header

% EDF version
Header(1) = '0';

Fields = {...
    'PatientID', ...    %1 local patient identification
    'RecordingID', ...  %2 local recording identification
    'StartDate', ...    %3 start date of recording (dd.mm.yy)
    'StartTime', ...    %4 start time of recording (hh.mm.ss)
    'Reserved', ...
    'DRcount', ...      %5 number of Data Records
    'DRduration', ...   %6 duration of Data Record [seconds]
    'ChannelCount', ... %7 number of channels
    'HeaderEnd'};       %8 index of the last byte in Headers, complete size of All Headers [Bytes]

HeaderI = [9 88; 89 168; 169 176; 177 184; 193 236; 237 244; 245 252; 253 256; 185 192];

for f =1:length(Fields)
   % Writing values (from input, calculated or default) to the Header string
   Lmax = HeaderI(f,2) - HeaderI(f,1) +1; % max field lenght which can be writen
   
   % get Date and Time from numeric fields if exist (will rewrite string values!!!)
   if f == 3 && isfield(edf.header,'StartDateYMD') && ...
      isnumeric(edf.header.StartDateYMD) && length(edf.header.StartDateYMD)==3% Date
      D = edf.header.StartDateYMD;
      if D(1) > 99, D(D>1999)=D(1)-2000; D(D>1900)=D(1)-1900; end % removes first two digits when YYYY format is used
      edf.header.StartDate = [num2str(D(3),'%02d'),'.',num2str(D(2),'%02d'),'.',num2str(D(1),'%02d')];
      clear D;
   end
   if f == 4 && isfield(edf.header,'StartTimeHMS') && ...
      isnumeric(edf.header.StartTimeHMS) && length(edf.header.StartTimeHMS)==3% Time
      T = edf.header.StartTimeHMS;
      edf.header.StartTime = [num2str(T(1),'%02d'),'.',num2str(T(2),'%02d'),'.',num2str(T(3),'%02d')];
      clear T;
   end
   
   if isfield(edf.header,Fields{f}) && ~isempty(edf.header.(Fields{f}))
      if ~ischar(edf.header.(Fields{f}))
         % convert to char
         edf.header.(Fields{f}) = num2str(edf.header.(Fields{f}));
      end
      if length(edf.header.(Fields{f})) > Lmax
         % shorten if necessary
         disp(['Warning: Data in header in field ''',Fields{f},''' had to be shortened.']);
         disp(['  From: "',edf.header.(Fields{f}),'"']);
         disp(['  To: "',edf.header.(Fields{f})(1:Lmax),'"']);
         edf.header.(Fields{f}) = edf.header.(Fields{f})(1:Lmax);
      end
      L = length(edf.header.(Fields{f}));

      Header(HeaderI(f,1):HeaderI(f,1)+L-1) = edf.header.(Fields{f});
      
   else
      % DEFAULT VALUES - if the fields are not specified
      switch f
         case 1 % PatientID
            Header(HeaderI(f,1):HeaderI(f,1)+6) = 'X X X X';
         case 2 % RecordingID
            Header(HeaderI(f,1):HeaderI(f,1)+26) = 'Startdate 01-Jan-1900 X X X';
         case 3 % StartDate
            Header(HeaderI(f,1):HeaderI(f,1)+7) = '01.01.00';
         case 4 % StartTime
            Header(HeaderI(f,1):HeaderI(f,1)+7) = '00.00.00';
         case 5 % Reserved
            % Header(HeaderI(f,1):HeaderI(f,1)+4) = 'EDF+C’'; % EDF+C is for continuous, but EDF+ ... contain annotation signal       
         case {6, 7, 8} % DRcount, DRduration, ChannelCount
            disp([char(10),'ERROR: Problem with the script. DRcount, DRduration or ChannelCount not processed correctly!']);
            disp('Script TERMINATED!!!');
            return;
      end
   end % if
end % for



%% Fill out the Channel Headers + prepare the data to int16 (convert if necessary)

% if Data type is 'INT16': there is no conversion needed
%  - physical_min/max and digital_min/max HAS TO BE SET - otherwise Warning
%   => defaults for non-calibrated input will be chosen

% if Data type is 'SINGLE' or 'DOUBLE':
%  - Real/Physiological data
%  - conversion to 'int16' and calculate Phy/Dig_Min/Max parameters in header

% if Data type is different from 'int16', 'single' or 'double'
%  => Error message and script termination

nCh = ChannelCount_calc;
clear ChannelCount_calc;

Fields = {...
    'physical_min', ...
    'physical_max', ...
    'digital_min', ...
    'digital_max'};

for c = 1:nCh
   
   % calculate "samples_in_DR"
   edf.ch(c).samples_in_DR = num2str(str2double(edf.header.DRduration) * edf.ch(c).fs);
   
   for f = 1:length(Fields)
      % prepare Phy/Dig_min/max values for data evaluation
      %  - will be set to NaN if not specified
      if isfield(edf.ch(c), Fields{f}) && ~isempty(edf.ch(c).(Fields{f})) 
         if ~isnumeric(edf.ch(c).(Fields{f}))
            % convert to number
            edf.ch(c).(Fields{f}) = str2double(edf.ch(c).(Fields{f}));
         end
         if f > 2 && edf.ch(c).(Fields{f}) - int16(edf.ch(c).(Fields{f})) ~= 0
            % digital_min or max NOT complient with 'int16' rules
            disp(['Warning: The value ''', num2str(edf.ch(c).(Fields{f})),...
                  ''' in field ''',Fields{f},''' does not comply with ''int16'' rules!']);
            edf.ch(c).(Fields{f}) = int16(edf.ch(c).(Fields{f})); % adjusted to int16
            disp(['   number adjusted to: ', edf.ch(c).(Fields{f})]);
         end
         
      else
         % if not set value of 'nan' temporarily assigned
         edf.ch(c).(Fields{f}) = nan;
      end
      
      PhyDig_MinMax(f) = edf.ch(c).(Fields{f}); % convert to numeric vector for easier work
   end
   
      
   Class = class(edf.ch(c).data); % result is in char ('int16', 'single', 'double', ...)  
   switch Class
      case 'int16'
         % check correctness of the header min/max
         if max(isnan(PhyDig_MinMax))
            % at least one parameter is NaN => cannot be calibrated
            % int16 min and max values will be used
            PhyDig_MinMax = [-32768, 32767, -32768, 32767];
            
            if isfield(edf.ch(c),'unit') && ~isempty(edf.ch(c).unit)
               % if unit exist it needs to be erased as for non-calibrated channel
               disp(['Warning: Channel ''',edf.ch(c).label,''' calibration was incorrect!']);
               disp(['         Its unit ''', edf.ch(c).unit,''' was deleted.']);
               edf.ch(c).unit = '';
            end
            
         else
            if edf.ch(c).digital_min > min(edf.ch(c).data)
               disp(['Warning: Digital_min (',num2str(edf.ch(c).digital_min),...
                     ') is bigger then Data minimum (',num2str(min(edf.ch(c).data)),') for ',...
                     edf.ch(c).label,' channel']);
            end
            if edf.ch(c).digital_max < max(edf.ch(c).data)
               disp(['Warning: Digital_max (',num2str(edf.ch(c).digital_max),...
                     ') is lower then Data maximum (',num2str(max(edf.ch(c).data)),') for ',...
                     edf.ch(c).label,' channel']);
            end
            if edf.ch(c).digital_min > edf.ch(c).digital_max
               disp(['Warning: Digital_min (',num2str(edf.ch(c).digital_min),...
                     ') is bigger then Digital_max (',num2str(edf.ch(c).digital_max),')!']);
               % Switching Digital min/max values
               Min = edf.ch(c).digital_min;
               edf.ch(c).digital_min = edf.ch(c).digital_max;
               edf.ch(c).digital_max = Min;
            end
            % Physical Min can be higher then Physical Max as it is used to reverse the signal polarity
         end
         
      case {'single', 'double'}
         % convert from single/double to int16 and calculate the header Phy/Dig_min/max values
         %  - any values inside Phy/Dig_min/max values will be ignored and overwriten
         Dig_MinMax = [-32768, 32767]; % maximum range for digital values will be used
         
         % Calculate the closest Physical Min and Max:
         % Examples: 827.6336;  1375.501;  -914.859;  -1200;  -1514.14
         % Can have decimal figures, but the number of digits including "-" sign has to be 8 or lower
         %  and it needs to be above the signal range
         Phy_MinMax = [min(edf.ch(c).data),  max(edf.ch(c).data)];
%          MinMax = [-5.1111111 456.9999991 12 0.12 0.15648]; % testing data
         for i=1:length(Phy_MinMax)
            Str = num2str(Phy_MinMax(i));
            I = find(Str=='.', 1); % positon of the '.' to round to 8 digits (including sign)
            if isempty(I), continue; end % no decimal point -> skipped
            
            if i == 1 % Min => dound down
               Phy_MinMax(i) = floor(Phy_MinMax(i) *10^(8-I)) / 10^(8-I);
            else      % Max => round up
               Phy_MinMax(i) =  ceil(Phy_MinMax(i) *10^(8-I)) / 10^(8-I);
            end
         end
                 
        
         x = Phy_MinMax;
         y = Dig_MinMax;
         k = (y(2)-y(1)) ./ (x(2)-x(1));
         q = y(1) - k .* x(1);
      
         edf.ch(c).data = int16(edf.ch(c).data .*k + q);
         
         edf.ch(c).physical_min = num2str(Phy_MinMax(1));
         edf.ch(c).physical_max = num2str(Phy_MinMax(2));
         edf.ch(c).digital_min = num2str(Dig_MinMax(1));
         edf.ch(c).digital_max = num2str(Dig_MinMax(2));
         
      otherwise
         %%-------------------------------------------------------------
         % if still compliand with int16 then convert it and process
         % otherwise error
         disp('Input data Error: The data are not either format: int16, single or bouble!');
         disp('Script Termination!!');
         return;
   
   end % switch
end % for c


ChHeader(1: 256*nCh) = ' '; % initialize channels header
 
% Vector of one Channel header field lenght
% CAUSION, one channel info is not continuous!
%  - it is sorted by the header information below
%  - first will be labels for all changes, then transducer types for all channels, etc.
ChHeaderI_1Ch = ...
   [16 ; ... % * nCh ... labels (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    80 ; ... % * nCh ... transducer types (e.g. AgAgCl electrode)
    8 ; ...  % * nCh ... units, physical dimensions (e.g. uV or degreeC)
    8 ; ...  % * nCh ... physical minimums (e.g. -500 or 34)
    8 ; ...  % * nCh ... physical maximums (e.g. 500 or 40)
    8 ; ...  % * nCh ... digital minimums (e.g. -2048)
    8 ; ...  % * nCh ... digital maximums (e.g. 2047)
    80 ; ... % * nCh ... filters, prefilterings (e.g. HP:0.1Hz LP:75Hz)
    8 ; ...  % * nCh ... # of samples in each data record
    32] ; ...% * nCh ... reserved

Fields = {...
    'label', ...
    'transducer', ...
    'unit', ...
    'physical_min', ...
    'physical_max', ...
    'digital_min', ...
    'digital_max', ...
    'filters', ...
    'samples_in_DR', ...
    'reserved'};

for f=1:length(Fields)
   
   last = sum(ChHeaderI_1Ch(1:f-1))*nCh; % end index of the previous fields
   
   for c = 1:nCh
      I = [last+ChHeaderI_1Ch(f)*(c-1)+1 ,  last+ChHeaderI_1Ch(f)*c]; % Indexes of begining and end of the filed in the Channel Header
      Lmax = I(2)-I(1)+1; % max field length which can be writen
      
      if isfield(edf.ch(c),Fields{f}) && ~isempty(edf.ch(c).(Fields{f}))
         if ~ischar(edf.ch(c).(Fields{f}))
            % convert to char
            edf.ch(c).(Fields{f}) = num2strMaxChar(edf.ch(c).(Fields{f}), 8); % max 8 characters if possible
         end
         if length(edf.ch(c).(Fields{f})) > Lmax
            % shorten if necessary
            disp(['Warning: Data in channel "', edf.ch(c).label, '" in field "',Fields{f},'" had to be shortened.']);
            disp(['  From: "',edf.ch(c).(Fields{f}),'"']);
            disp(['  To: "',edf.ch(c).(Fields{f})(1:Lmax),'"']);
            edf.ch(c).(Fields{f}) = edf.ch(c).(Fields{f})(1:Lmax);
         end
         L = length(edf.ch(c).(Fields{f}));

         ChHeader(I(1):I(1)+L-1) = edf.ch(c).(Fields{f});
      end
   end
   
end



%% Create string with All Data

DRcount = str2double(edf.header.DRcount);
DRduration = str2double(edf.header.DRduration);

for c=1:nCh
   fs(c) = edf.ch(c).fs;
end
DRlength_allCh = sum(fs) * DRduration;

Data(DRlength_allCh*DRcount) = int16(0);

% filling all data in int16 format to one variable according to the EDF (DRcount, DR duration) standard
for c = 1:nCh
   for dr = 1:DRcount
      start = sum(fs(1:c-1))*DRduration + 1  +  DRlength_allCh*(dr-1);
      stop =  sum(fs(1:c  ))*DRduration      +  DRlength_allCh*(dr-1);
      Data(start:stop) = edf.ch(c).data( (dr-1)*fs(c)*DRduration+1 : dr*fs(c)*DRduration  );
   end
end

clear edf; %save some memory before writing file


%% Create the folder if it does not exist
I = strfind(FilePath,'\');
if isempty(dir(FilePath(1:I(end))))
   mkdir(FilePath(1:I(end)));
end

%% Write to the file
fid = fopen(FilePath, 'w');

fwrite(fid, Header,   'uint8');    % write File Header
fwrite(fid, ChHeader, 'uint8');    % write Channel Header
fwrite(fid, Data,     'int16');    % Write Data

fclose(fid);





function EDF_writeHeader (FilePath, EDFh)
%% write modified header to already existing EDF file!
% Has to be the same EDF the header comes from originnaly!

%% first check the header compatibility with the EDF
% ALL BELOW HAS TO MATCH! (the custom header has to match the EDF file header for those)
Match_Header = {'DRduration' 'ChannelCount'}; % all numeric (not DRcount as it is not present when data are read too)
Match_Ch = {'digital_min' 'digital_max' 'samples_in_DR' 'fs'}; % all numeric

origEDF = EDF_read_write('r',FilePath, 'ch',0);
nCh = origEDF.header.ChannelCount;

EDFh.header.HeaderEnd = 256 + 256 * nCh; % File Header = 256 Bytes, one channel heade = 256 Bytes

% FILE HEADER
for i = length(Match_Header):-1:1
   MatchH(i) = origEDF.header.(Match_Header{i}) == EDFh.header.(Match_Header{i});
end
if min(MatchH) == 0
   % some of the nonchangable parameters were changed -> termination
   disp('Error: The following structure parameters has to match the EDF file:');
   disp({'FILE HEADER:' Match_Header{~MatchH}});
   return;
end

% CHANNEL HEADERS
for i = 1:length(Match_Ch)
   for ch = 1:origEDF.header.ChannelCount
      MatchCH(i,ch) = ...
               origEDF.ch(ch).(Match_Ch{i}) == EDFh.ch(ch).(Match_Ch{i});
   end
end
if min(min(MatchCH)) == 0
   % some of the nonchangable parameters were changed -> termination
   disp('Error: The following structure parameters has to match the EDF file:');
   disp({'CHANNEL HEADERS:' Match_Ch{~min(MatchCH,[],2)}});
   disp({'CHANNELS: ', num2str(find(~min(MatchCH,[],1)))});
   return;
end

% now all data are fine and ready to be replacing the file header

%% Filling out the File Header
Header(1:256) = ' '; % initialize file header

% EDF version
Header(1) = '0';

Fields = {...
    'PatientID', ...    % local patient identification
    'RecordingID', ...  % local recording identification
    'StartDate', ...    % start date of recording (dd.mm.yy)
    'StartTime', ...    % start time of recording (hh.mm.ss)
    'Reserved', ...
    'DRcount', ...      % number of Data Records
    'DRduration', ...   % duration of Data Record [seconds]
    'ChannelCount', ... % number of channels
    'HeaderEnd'};       % index of the last byte in Headers, complete size of All Headers [Bytes]

 
HeaderI = [9 88; 89 168; 169 176; 177 184; 193 236; 237 244; 245 252; 253 256; 185 192];

for f =1:length(Fields)
   % Writing values (from input, calculated or default) to the Header string
   Lmax = HeaderI(f,2) - HeaderI(f,1) +1; % max field lenght which can be writen

   % get Date and Time from numeric fields if exist (will rewrite string values!!!)
   if f == 3 && isfield(EDFh.header,'StartDateYMD') && ...
      isnumeric(EDFh.header.StartDateYMD) && length(EDFh.header.StartDateYMD)==3% Date
      D = EDFh.header.StartDateYMD;
      EDFh.header.StartDate = [num2str(D(3),'%02d'),'.',num2str(D(2),'%02d'),'.',num2str(D(1),'%02d')];
      clear D;
   end
   if f == 4 && isfield(EDFh.header,'StartTimeHMS') && ...
      isnumeric(EDFh.header.StartTimeHMS) && length(EDFh.header.StartTimeHMS)==3% Time
      T = EDFh.header.StartTimeHMS;
      EDFh.header.StartTime = [num2str(T(1),'%02d'),'.',num2str(T(2),'%02d'),'.',num2str(T(3),'%02d')];
      clear T;
   end
   
   if isnumeric(EDFh.header.(Fields{f}))
      % convert to char
      EDFh.header.(Fields{f}) = num2str(EDFh.header.(Fields{f}));
   end
   
   if length(EDFh.header.(Fields{f})) > Lmax
      % shorten if necessary
      disp(['Warning: Data in header in field ''',Fields{f},''' had to be shortened.']);
      disp(['  From: "',EDFh.header.(Fields{f}),'"']);
      disp(['  To: "',EDFh.header.(Fields{f})(1:Lmax),'"']);
      EDFh.header.(Fields{f}) = EDFh.header.(Fields{f})(1:Lmax);
   end
   
   L = length(EDFh.header.(Fields{f}));
   
   % write the field value to the string:
   Header(HeaderI(f,1):HeaderI(f,1)+L-1) = EDFh.header.(Fields{f});
end % for


%% Fill out the Channel Headers
ChHeader(1: 256*nCh) = ' '; % initialize channels header
 
% Vector of one Channel header field lenght
% CAUSION, one channel info is not continuous!
%  - it is sorted by the header information below
%  - first will be labels for all changes, then transducer types for all channels, etc.
ChHeaderI_1Ch = ...
   [16 ; ... % * nCh ... labels (e.g. EEG Fpz-Cz or Body temp) (mind item 9 of the additional EDF+ specs)
    80 ; ... % * nCh ... transducer types (e.g. AgAgCl electrode)
    8 ; ...  % * nCh ... units, physical dimensions (e.g. uV or degreeC)
    8 ; ...  % * nCh ... physical minimums (e.g. -500 or 34)
    8 ; ...  % * nCh ... physical maximums (e.g. 500 or 40)
    8 ; ...  % * nCh ... digital minimums (e.g. -2048)
    8 ; ...  % * nCh ... digital maximums (e.g. 2047)
    80 ; ... % * nCh ... filters, prefilterings (e.g. HP:0.1Hz LP:75Hz)
    8 ; ...  % * nCh ... # of samples in each data record
    32] ; ...% * nCh ... reserved

Fields = {...
    'label', ...
    'transducer', ...
    'unit', ...
    'physical_min', ...
    'physical_max', ...
    'digital_min', ...
    'digital_max', ...
    'filters', ...
    'samples_in_DR', ...
    'reserved'};

for f=1:length(Fields)
   
   last = sum(ChHeaderI_1Ch(1:f-1))*nCh; % end index of the previous fields
   
   for c = 1:nCh
      I = [last+ChHeaderI_1Ch(f)*(c-1)+1 ,  last+ChHeaderI_1Ch(f)*c]; % Indexes of begining and end of the filed in the Channel Header
      Lmax = I(2)-I(1)+1; % max field length which can be writen
      
      if isfield(EDFh.ch(c),Fields{f}) && ~isempty(EDFh.ch(c).(Fields{f}))
         % only when field exist and is not empty
         if isnumeric(EDFh.ch(c).(Fields{f}))
            % convert to char
            EDFh.ch(c).(Fields{f}) = num2strMaxChar(EDFh.ch(c).(Fields{f}), 8); % max 8 characters if possible
         end
         
         if length(EDFh.ch(c).(Fields{f})) > Lmax
            % shorten if necessary
            disp(['Warning: Data in channel "', EDFh.ch(c).label, '" in field "',Fields{f},'" had to be shortened.']);
            disp(['  From: "',edf.ch(c).(Fields{f}),'"']);
            disp(['  To: "',edf.ch(c).(Fields{f})(1:Lmax),'"']);
            EDFh.ch(c).(Fields{f}) = EDFh.ch(c).(Fields{f})(1:Lmax);
         end
         
         L = length(EDFh.ch(c).(Fields{f}));

         % write the field value to the string:
         ChHeader(I(1):I(1)+L-1) = EDFh.ch(c).(Fields{f});
      end
   end
   
end


%% Write to the file
fid = fopen(FilePath, 'r+');

frewind(fid);
fwrite(fid, [Header, ChHeader],   'uint8');    % write File & Channel Headers

fclose(fid);






function String = num2strMaxChar (Num, N)
% Created by: Jan Bukartyk in 2014,02,04

%% Description, inputs:
% Will convert number to a string with strictly specified maximum characters

% Num ... number to convert to string
% N ... Maximal number of characters in the output string
%       number of characters including "minus" sign, decimal point and exponent

% matlab can only specify number of digits without counting the "minus" sign or the decimal point

%% examples of combination for 8 character numbers
% 12345678  12345678
% -1234567
% -12.3456
% -12.34e6
% -1.23e-6  -0.00000
% 0.012345  1.234e-2
% -0.00123  -1.23e-3

%%
if N > 30, disp('Number of characters cannot be higher then 30!'); return; end

String = [];

Negative = Num < 0; % is the number negative
if Negative == 1
   Num = -1 * Num; % make it positive for the calculations
end

NumStr = num2str(Num, '%30.30f'); % fixed number of digits, this way there will not be any exponent!

Idot = find(NumStr == '.', 1,'first');

Left = NumStr(1:Idot-1);    % left  side from '.' (whole number)
Right = NumStr(Idot+1:end); % right side from '.' (decimal number)

if length(Left) == 1 && Left(1) == '0'
   % original number is smaller then 0 (left side is '0')
   LeftN = 0; % number of valid digits on the left side
else
   % original number is bigger then 0 (non zero number on left side)
   LeftN = length(Left); % number of valid digits on the left side
end

I = find(Right ~= '0', 1,'first');
if ~isempty(I)
   RightZeros = I-1; % how meny zeros in between '.' and first number
else
   RightZeros = 0; % there is number immediately after '.'
end



%% evaluation of the number and converting to the number of strings needed while keeping best precision possible
Nmax = (N-Negative);
if LeftN > Nmax
   % the whole number has already more digits then allowed
   % => exponent has to be used!
   Diff = LeftN - Nmax +2; % exponent value
   if Diff > 9
      Diff = Diff +1; % two digits exponent 'eXX'
   end
   if Diff >= LeftN, disp('Cannot convert to string, increase number of characters!'); return; end
   NumStr = [num2str(round(str2double([Left(1:end-Diff),'.',Left(end-Diff+1:end),Right]))),...
               'e',num2str(Diff)];
   
elseif LeftN > 0 && LeftN == Nmax
   % whole number exacly match the digits
   NumStr = num2str(round(str2double([Left,'.',Right])));
   
elseif LeftN > 0 && LeftN < Nmax % account for decimal point which takes one character
   Diff = Nmax - LeftN; % always positive
   NumStr = num2str(round(str2double([Left,Right(1:Diff-1),'.',Right(Diff:end)])) /10^(Diff-1));
   
   
   % from this point the number has to be only decimal (smaller then zero)
elseif RightZeros < 3
   % in this case there is no advantage of the exponent => exponnet would shorten the valid digits
   Diff = Nmax-2;
   if Diff < 1, disp('Cannot convert to string, increase number of characters!'); return; end
   NumStrTemp(1:RightZeros) = '0';
   NumStr = ['0.',NumStrTemp, num2str(round( str2double([Right(1:Diff),'.',Right(Diff+1:end)]) ))];

else
   % will add negative exponent => another character for '-'
   Nmax = Nmax - 4;           % exclude characters: '.e-X'
   Exp = -(RightZeros+1);
   Nmax(Exp < -9) = Nmax - 1; % if 2 digits exponent '.e-XX' 
   if Nmax < 1, disp('Cannot convert to string, increase number of characters!'); return; end
   NumStrTemp = num2str(round(str2double([Right(RightZeros+1:RightZeros+Nmax),'.',...
                            Right(RightZeros+Nmax+1:end)])) /10^(Nmax-1));
   NumStr = [NumStrTemp,'e',num2str(Exp)];
end
   

%% apply negative sign to the string
if Negative == 1
   String = ['-',NumStr];
else
   String = NumStr;
end

%% easy function which did not solve all combinations
% % Num ... number to convert to string
% % N ... Maximal number of characters in the output string
% 
% % number of characters including "minus" sign and decimal point
% % matlab can only specify number of digits without counting the "minus" sign or the decimal point
% 
% NumStr = num2str(Num);
% 
% I1 = max(NumStr == '-');
% I2 = max(NumStr == '.'); % decimal point
% 
% String = num2str(Num,N-I1-I2); % this way the number of characters will include the "-" and "."










