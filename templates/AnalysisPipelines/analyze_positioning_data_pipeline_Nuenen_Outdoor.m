%% This script runs an analysis pipeline for positioning data 
%
%  This loads the beacon data per participant
%  determines the closest beacon for each timepoint.
%  and adds this to the datafile containing the processed skin conductance
% 
%  Created 26-04-2024, Hans Revers



%% SETUP
% Remove all data currently in the workspace
clearvars;

%% Specify where to find and save data

% set a path to the project
projectfolder = 'C:\Hans\Nuenen';

% where to find the raw data
datafolder = fullfile(projectfolder, '0.RawData');

% the excel file that holds starttime and duration per pp
participantDataFile = fullfile(projectfolder, '\0.RawData\ParticipantData.xlsx');

% where to save the clean data after artifact correction
cleandatafolder = fullfile(projectfolder, '\2.ProcessedData\0.CleanData');

% where to save the phasic data
deconvolveddatafolder = fullfile(projectfolder, '\2.ProcessedData\1.DeconvolvedData\2.OutdoorData');

% define temporary directory for datafiles
tempfolder = fullfile(projectfolder, '\Temp');


%% Skin conductance processing has already been done, so these folders should be good.

% project folder
if ~exist(projectfolder, "dir")
    error("The project folder was not found at the specified location. Please check.");
end

% data folder
if ~exist(datafolder, "dir")
    error("The data folder was not found at the specified location. Please check.");
end

% clean data folder
if ~exist(cleandatafolder, "dir")
    error("The clean data folder was not found at the specified location. Please check.");
end

% deconvolved data folder
if ~exist(deconvolveddatafolder, "dir")
    error("The deconvolved data folder was not found at the specified location. Please check.");
end

% participant Datafile
if ~exist(participantDataFile, "file")
    % the datafile is not in the specified location
    error(['The participant datafile cannot be found. ' ...
        ['This is an Excel file that contains the starttime and duration per participant. ' ...
        'Please check. I expected it here: '] deconvolveddatafolder]);
else
    % read the Excel file 
    participantData = readtable( participantDataFile );
end


%% Participant numbers
%  Here listed as numbers because the participant data Excel file has them
%  as numbers. However, the corresponding folders al start with P and have leading zeros, 
%  so we will have to fix that further down.
%  Example: pp_nrs = [1:8, 12:15, 123];

% ISSUES WITH POSITIONING DATA
% P005 :: unixtime is off (2020)
% P008 10 13 14 21 22 28 30 31 34 35 :: no beacon data file 

pp_nrs = [1:43];
pp_unsynched_unixtime = []; % unix timestamp is off
pp_nrs_missing_strava_data = [5, 13, 29]; % no strava file
pp_nrs_rejected_eda = [22, 28, 30, 31, 34, 38, 42]; % pp rejected in the skin conductance processing
pp_nrs_exclude = [pp_unsynched_unixtime pp_nrs_missing_strava_data pp_nrs_rejected_eda]; % combine
pp_nrs(pp_nrs_exclude) = []; % then remove

% the number of participants
nof_pps = length(pp_nrs);  



%%  Find all positioning data, combine with skin conductance data in a table

participant = [];
initial_time = [];
time = [];
lat = [];
long = [];
poi = [];
phasic = [];
phasic_z = [];


% for each participant, do ...
% (note that pp_i is the index in the participant list, not the participant number)
for pp_i = 1:nof_pps 
    
    % we get the participant number here
    pp_nr = pp_nrs(pp_i); 
    % The folders with data have a P before the number, and leading zeros
    % to make it a 3 digit number
    pp_label = ['P', num2str(pp_nr, '%03d')]; 
    % create the full path to the data folder of this participant
    pp_datafolder = fullfile(datafolder, pp_label); 

    % find the row in the participantData file that has the current participant number
    participantData_index = find(strcmp(participantData.Participant,pp_label)); % use this if the excel file contains participant labels (P003)
    
    % read the timezone from that row
    timezone = string(participantData.TimeZone(participantData_index)); % e.g. 'Europe/Amsterdam'

    % get the beacon data
    cfg = []; 
    cfg.datafolder       = pp_datafolder; 
    cfg.stravafile       = 'Strava.tcx';
    cfg.originaltimezone = "Europe/London"; % NOTE: I have deduced this timezone difference from the data. We need to check this with Ondrej/Wilco
    cfg.newtimezone      = timezone;
    raw_strava_data      = stravatcx2matlab(cfg);

    % Provide some feedback
    fprintf('Raw stava data read for participant %s\n', pp_label);

    % load the deconvolved data for this participant
    deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);
    load(deconvolved_data_path_filename);

    % to connect the beacon data to the skin conductance data, we need to
    % upsample the beacon data and align the timelines.
    % skin conductance is sampled at 4Hz, beacon data at 1Hz
    cfg = []; % use defaults 
    cfg.fsample = deconvolved_data.fsample; % upsample to 4 Hz
    raw_strava_data_resampled = resample_strava(cfg, raw_strava_data);

    % determine the starttime and endtime for the segment
    % use the overlap in time of the deconvolved data and the nearest
    % beacon data. This assumes both are in unix time format with the same
    % timezone
    % add a unix timestamp array for both datasets
    deconvolved_data.unix_time              = deconvolved_data.initial_time_stamp    + deconvolved_data.time;
    raw_strava_data_resampled.unix_time     = raw_strava_data_resampled.initial_time_stamp + raw_strava_data_resampled.time;
    % determine the latest starttime
    starttime = max( deconvolved_data.unix_time(1),   raw_strava_data_resampled.unix_time(1)  ); 
    % determine the earliest endttime
    endtime   = min( deconvolved_data.unix_time(end), raw_strava_data_resampled.unix_time(end)); 

    % extract the [starttime - endtime] segment of both datasets
    cfg = []; 
    cfg.starttime  = starttime; 
    cfg.endtime    = endtime; 
    cfg.timeformat = 'unixtime'; 
    raw_strava_data_resampled_segmented = segment_generic(cfg, raw_strava_data_resampled);
    deconvolved_data_segmented          = segment_generic(cfg, deconvolved_data);

    % Determine POI for lat/long positions
    cfg=[];
    cfg.datafolder = datafolder;
    cfg.poifile = "NuenenTestPOI.geojson"; %name of the poifile
    raw_strava_data_resampled_segmented_poi = getoutdoorpoi(cfg,raw_strava_data_resampled_segmented); %use the poifile to determine when a position in the stravafile align with a poi

    % Provide some feedback
    fprintf('POI data calculated for participant %s\n', pp_label);


    % add data of this pp to the table
    participant = [participant; pp_nr*ones(size(raw_strava_data_resampled_segmented_poi.time))];
    initial_time = [initial_time; raw_strava_data_resampled_segmented_poi.initial_time_stamp*ones(size(raw_strava_data_resampled_segmented_poi.time))];
    time = [time; raw_strava_data_resampled_segmented_poi.time];
    lat = [lat; raw_strava_data_resampled_segmented_poi.lat ];
    long = [long; raw_strava_data_resampled_segmented_poi.long ];
    poi = [poi; raw_strava_data_resampled_segmented_poi.currentpoi ];
    phasic = [phasic; deconvolved_data_segmented.phasic];
    phasic_z = [phasic_z; deconvolved_data_segmented.phasic_z];

    % plot the location data for each pp
    plot_maps_per_pp = false;
    if plot_maps_per_pp
        % PLOT FULL GEO DATA
        geoscatter(raw_strava_data_resampled_segmented_poi.lat,raw_strava_data_resampled_segmented_poi.long);
        % ADD GEO DATA BASED ON POI
        hold on;
        points = find(raw_strava_data_resampled_segmented_poi.currentpoi == "kerkje");
        geoscatter(raw_strava_data_resampled_segmented_poi.lat(points),raw_strava_data_resampled_segmented_poi.long(points));
    end


end



%% combine all data in a table
skinconductance_strava_table = table(participant, initial_time, time, lat,long, poi,phasic,phasic_z);

% save the table
writetable(skinconductance_strava_table, 'skinconductance_strava_table.csv');

% Provide some feedback
fprintf('A csv file with the skinconductance strava data has been saved as "skinconductance_strava_table.csv" in %s\n', pwd);

