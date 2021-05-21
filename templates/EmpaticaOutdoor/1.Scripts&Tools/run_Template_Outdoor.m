%script for analyzing and combining GPS and EMPATICA data
%% DIRECTORY
%Remove all data currently in the workspace
clear;

%Get project directory, make sure the CURRENT FOLDER in MATLAB is the
%1.Scripts&Tools folder inside the PROJECT FOLDER
mydir  = pwd
idcs   = strfind(mydir,'\')
pdir = mydir(1:idcs(end)-1)

%Create a list for all participant numbers, to (in one go) cycle through
%add missing participants between the [], to skip these during the analysis
subject = setdiff(1:2,[]);

%Get the total amount of subjects from the subject list
nsubjects = numel(subject);

%% TIMES
% CHECK: Make sure that the onset and offset files are placed in the
% 0.RawData\ Directory
% Use above calculated directory is used to read ride onset times for all 
% ppts from excel file. 
[num, txt, raw] = xlsread([pdir,'\0.RawData\onsets']);
session_onset = txt(:,1); % time is provided in human time
 
%read ride offset times for all ppts from excel file.
clear num txt raw
[num, txt, raw] = xlsread([pdir,'\0.RawData\offsets']);
session_offset = num(:,1); % time is provided in seconds

%% LOOP
% CHECK: Make sure that the data per participant is placed in the
% \0.RawData\PARTICIPANTNUMBER(P09) directory. This must include all data
% used by the functions below (empatica, strava, beacon), using the correct
% naming convention and file structure
for i=1:nsubjects
    %% EMPATICA
    % CHECK: Make sure all empatica files are stored in the correct
    % participant folders (ACC,BVP,EDA,HR,IBI,tags,TEMP)
    
    % Import, Resample, and Segment all e4 data from empatica CSV files to matlab.
    cfg = []; % empty any existing configuration settings.
    cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', subject(i))];
    cfg.trigger_time = session_onset(subject(i));
    cfg.pretrigger = 0;
    cfg.posttrigger = session_offset(subject(i));
    e4_full = e4full2matlab(cfg);
    disp("imported and segmented E4 Data for subject: " + subject(i))

    % Correct EDA data for motion artifacts
    cfg = []; % empty any existing configuration settings.
    cfg.timwin    = 20; % define the timewindow for artifact detection (default = 20)
    cfg.threshold  = 4; % define the threshold for artifact detection (default = 5)
    cfg.validationdata = e4_full.acceleration(1:end,4); % data visualized under artifacts for validating the artifact (acceleration data)
    cfg.blockreplacement = "post"; % add replacement for blocks detected by the MIT EdaExplorer, can be "pre" "post" or "both" 
    e4_corrected = artifact_eda(cfg, e4_full);
    disp('Corrected Eda Data for subject: '+ subject(i))

    % Compute phasic and tonic data (deconvolve)
    cfg = []; % empty any existing configuration settings.
    cfg.tempdir = 'C:\Temp'; % define temporary directory for datafiles, C:/Temp = default
    e4_deconvolved = deconvolve_eda(cfg, e4_corrected); 
    disp('Deconvolved EDA Data for subject: '+ subject(i))

    %%  STRAVA
    % CHECK: Make sure the strava files are stored in the correct
    % participant folders (strava.tcx)
    
    % Import Strava data from tcx files
    cfg = [];
    cfg.trigger_time = session_onset(subject(i)); %onset time of this participant, pre-setup for the segmentation
    cfg.pretrigger = 0; %pre startin time of this participant, pre-setup for the segmentation
    cfg.posttrigger = session_offset(subject(i)); %session offset time of this participant, pre-setup for the segmentation
    cfg.fsample = e4_full.fsample; %sampling frequency used to resample the strava data, 
    cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', subject(i))]; %location of the strava data of this participant
    cfg.stravafile = 'strava.tcx'; %name of the strava data (default = 'strava.tcx'
    raw_strava = stravatcx2matlab(cfg);
    disp("imported Strava" + subject(i))
    
    % Cut the STRAVA data to the defined on/offset
    segmented_strava = segment_strava(cfg,raw_strava);
    disp("segmented Strava" + subject(i))
    
    % Resample the Strava data to the defined on/offset
    resampled_strava = resample_strava(cfg, segmented_strava);
    disp("resampled strava" + subject(i))
    
    %% COMBINE
    %CHECK: Make sure the data is properly stored (store the data per
    %source in a separate structure, make sure there is a structure per type, and
    %a combined structure)
    %When combining data sources, make sure the correct datanames are used in the
    %combine_data configuration
    
    % Combine all participant E4 and Strava data in 2 separate structures
    e4_data(i) = e4_deconvolved;      
    strava_data(i) = resampled_strava;
    
    %Combine the data in a single structure, you can add or
    %remove data from these lists to change the output. data1names is the
    %default list for E4 Data, cfg.data2names is the default list for
    %outdoor data.
    cfg.data1names = {'initial_time_stamp';'initial_time_stamp_mat';'fsample';'time';'conductance';'conductance_z';'phasic';'phasic_z';'tonic';'tonic_z';'bvp';'heartrate';'temperature';'acceleration';'event';'orig';'analysis';'eventchan'};
    cfg.data2names = {'lat';'long';'altitude';'distance';'speed'};    
    combined_data = combine_data(e4_data(i), strava_data(i), cfg);%
        
    %Add the subject number to the combined data. This is used to later
    %identify what data belongs to what subject.
    combined_data.participant=subject(i);

    %Add the combined data to the struct with all data, this will become
    %the final data structure outputted as a matlab file for later eiting
    scr_data(i) = combined_data;
    disp("Combined All Data and Strava data in one scr_data variable: "  + subject(i))
    
    %% CLEAR AND SAVE
    % save current results to file, this is done to make sure that any
    % false participants do not cause a complete data loss for previous
    % participants. Separate .mat files can later be combined by Marcel or
    % Wilco.
    save ([pdir,strcat('\2.ProcessedData\SCR_data_',num2str(subject(i)),'.mat')], 'combined_data');    
    disp('Saved SCR_temp to .mat file')
    
    %Clear the non-required data. 
    clearvars -except pdir i nsubjects subject session_onset session_offset scr_data
end

%% SAVE MAT
% save final results to file
save ([pdir,'\2.ProcessedData\SCR_data.mat'], 'scr_data'); % save all phasic and tonic data to matlab file
disp('Saved SCR_data to .mat file')

%% SAVE CSV
% Save the data into a long csv format
% Make sure all datanames are either single values, or arrays of the same
% length for the entire participant (example 1x4556, or 4556x1)
cfg = [];
cfg.savename = 'template_outdoor.csv';
cfg.datanames = {'initial_time_stamp' 'initial_time_stamp_mat' 'fsample' 'time' 'participant' 'conductance' 'conductance_z' 'phasic' 'phasic_z' 'tonic' 'tonic_z' 'bvp' 'heartrate' 'temperature' 'lat' 'long' 'altitude' 'distance' 'speed'};
cfg.savelocation = [pdir,'\2.ProcessedData'];
export2csv(cfg, scr_data);
disp('Saved data to .csv file')