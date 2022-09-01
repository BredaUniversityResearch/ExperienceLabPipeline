%% DATA LOCATION
% This is one of the default ways for the experience lab to grab the
% location of your data. These 3 lines will take your currently active
% folder, and show the folder above it. Using the default Experience
% FolderTemplate, this would give you the location of the project on your
% computer.
mydir  = pwd;
idcs   = strfind(mydir,'\');
pdir = mydir(1:idcs(end)-1);

%% PARTICIPANT INFO
% Participant info is stored in an excel sheet, containing the participant
% number, start / duration / end time, the timezone, whether to include
% that participant, and other important information, excluding personally
% identifiable information

% Read the excel file as a table
participanttable = readtable([pdir,'\0.RawData\ParticipantData.xlsx'],"VariableNamingRule","preserve");

% Get the row, and then determine which partiicpant is in that row.
participantIndex = 1;
participant = participanttable.Participant(participantIndex);

%% EMPATICA 
% The ExperienceLab has developed several tools for importing, and editing
% empatica data to be used in your own project.

%% Fully Automatic Function (e4full2matlab)
% This function will, based on the parameters, import, segment, and
% resample the provided data. In this case it will automatically resample
% all data to 4hz as thats the sample rate of the empatica EDA data we use
cfg = [];
cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', participant)];
cfg.trigger_time = participanttable(participantIndex).start_time;
cfg.posttrigger = participanttable(participantIndex).duration;
e4_full = e4full2matlab(cfg);

%% Separate
% You can also call these manually, say you only want to work with EDA
% data, then you can use the following functions to:

%1. Import the EDA files
raw_eda = e4eda2matlab(cfg);

%2. Segment to the correct time-frame
segmented_eda = segment_generic(cfg, raw_eda);

%3. Resample to the desired frequency
resampled_eda = resample_eda(cfg, segmented_eda);

%% INDOOR BEACON DATA


%% OUTDOOR STRAVA DATA

