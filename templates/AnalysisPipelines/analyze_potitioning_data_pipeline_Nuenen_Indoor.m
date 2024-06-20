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
deconvolveddatafolder = fullfile(projectfolder, '\2.ProcessedData\1.DeconvolvedData\1.IndoorData');

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
pp_unsynched_unixtime = [5 29]; % unix timestamp in 2020
pp_nrs_missing_beacon_data = [8 10 13 14 21 22 28 30 31 34 35]; % no beacon file
pp_nrs_rejected_eda = [38]; % pp rejected in the skin conductance processing
pp_nrs_exclude = [pp_unsynched_unixtime pp_nrs_missing_beacon_data pp_nrs_rejected_eda]; % combine
pp_nrs(pp_nrs_exclude) = []; % then remove

% the number of participants
nof_pps = length(pp_nrs);  



%%  Find all positioning data, combine with skin conductance data in a table

participant = [];
time = [];
beaconID = [];
beaconMajorMinor = [];
phasic = [];
phasic_z = [];
% Weight = [176;163;131;133;119];




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
    cfg.beaconDataFolder = datafolder;
    cfg.beaconPositions  = 'BeaconPositions.xlsx';
    cfg.beaconmeta       = 'BeaconMeta.xlsx';
    cfg.datafolder       = pp_datafolder; % String value specifying the lcoation of the beaconFile.
    cfg.beaconfile       = 'Beacon.csv';
    cfg.timezone         = timezone; 
    cfg.nullvalue        = 10; % strength lower than this should be discarded
    % Other config options
    % cfg.smoothen =     boolean (true/false) (default = true);
    % cfg.smoothingFactor = amount of smoothing (default = 0.2)
    % cfg.smoothingMethod = method for smoothing. 
    % cfg.movemean =     use a moving mean to get smoother data (default = true)
    % cfg.movemeanduration = duration of the moving mean factor (default = 60);
    raw_beacon_data = beacon2matlab(cfg);




    % Provide some feedback
    fprintf('Raw beacon data read for participant %s\n', pp_label);

    % raw_beacon_data.beaconmeta = raw_beacon_data.beaconMeta; % the nearest_beacon function expects beaconmeta (small letter m)
    
    % Determine nearest beacon
    cfg = [];
    cfg.strengthmin = 40; % minimum strength required to include a beacon
    cfg.strengthmax = 90; % maximum strength of a beacon
    cfg.txpower = -62; % general txpower of a beacon, for Exp Lab, this is considered -62
    cfg.usegeodata = false; % calculate lat/lon position of the data
    nearest_beacon_data = nearest_beacon(cfg,raw_beacon_data); % calculate the nearest beacon from the raw beacon data


    % Provide some feedback
    fprintf('Nearest beacon data calculated for participant %s\n', pp_label);

    % load the deconvolved data for this participant
    deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);
    load(deconvolved_data_path_filename);

    % to connect the beacon data to the skin conductance data, we need to
    % upsample the beacon data and align the timelines.
    % skin conductance is sampled at 4Hz, beacon data at 1Hz
    cfg = []; % use defaults 
    cfg.fsample = deconvolved_data.fsample; % upsample to 4 Hz
    nearest_beacon_data_resampled = resample_beacon(cfg, nearest_beacon_data);

    % determine the starttime and endtime for the segment
    % use the overlap in time of the deconvolved data and the nearest
    % beacon data. This assumes both are in unix time format with the same
    % timezone
    % add a unix timestamp array for both datasets
    deconvolved_data.unix_time              = deconvolved_data.initial_time_stamp    + deconvolved_data.time;
    nearest_beacon_data_resampled.unix_time = nearest_beacon_data_resampled.initial_time_stamp + nearest_beacon_data_resampled.time;
    % determine the latest starttime
    starttime = max( deconvolved_data.unix_time(1),   nearest_beacon_data_resampled.unix_time(1)  ); 
    % determine the earliest endttime
    endtime   = min( deconvolved_data.unix_time(end), nearest_beacon_data_resampled.unix_time(end)); 

    % extract the [starttime - endtime] segment of both datasets
    cfg = []; 
    cfg.starttime  = starttime; 
    cfg.endtime    = endtime; 
    cfg.timeformat = 'unixtime'; 
    nearest_beacon_data_resampled_segmented = segment_generic(cfg, nearest_beacon_data_resampled);
    deconvolved_data_segmented              = segment_generic(cfg, deconvolved_data);

    % add data of this pp to the table
    participant = [participant; pp_nr*ones(size(nearest_beacon_data_resampled_segmented.time))];
    time = [time; nearest_beacon_data_resampled_segmented.time];
    beaconID = [beaconID; str2double(nearest_beacon_data_resampled_segmented.nearestBeaconID) ];
    beaconMajorMinor = [beaconMajorMinor; nearest_beacon_data_resampled_segmented.nearestBeacon ];    
    phasic = [phasic; deconvolved_data_segmented.phasic];
    phasic_z = [phasic_z; deconvolved_data_segmented.phasic_z];


    show_data = false;
    if show_data
        figure;
        % create two panels above each other
        tiledlayout(2, 1);
        % top panel
        nexttile;
        hold on;
        legend_labels = [];
        for beacon_i = 1:length(raw_beacon_data.beaconnames)
            raw = plot(raw_beacon_data.beaconvalues.(raw_beacon_data.beaconmeta.cBeacon(beacon_i)));
            legend_labels = [legend_labels, raw_beacon_data.beaconmeta.Name(beacon_i)];
        end
        hold off;
        legend(legend_labels, 'Location','eastoutside');
        title (['Participant ' pp_label]);

        dt_raw = datatip(raw);    

        % bottom panel
        nexttile;
        beacon = plot(nearest_beacon_data_resampled_segmented.nearestBeaconID);
        title (['Participant ' pp_label]);
        ax = gca;
        % sort the beaconIDs in ascending order
        beaconMetaOrdered = sortrows(nearest_beacon_data_resampled_segmented.beaconmeta, 'BeaconID');
        % show the beacon names at the y-axis
        ax.YTick = beaconMetaOrdered.BeaconID;
        ax.YTickLabel = strcat(num2str(beaconMetaOrdered.BeaconID), beaconMetaOrdered.Name );
        % show the beacon name at the cursur tip
        
        dt_beacon = datatip(beacon);    
        filename = ['beacon_values_' pp_label]; 
        savefig(filename);
        close;
    end

end

% add the beacon location names
beaconLocation = {};
for row_i = 1:length(beaconID)
    if isnan(beaconID(row_i))
        beaconLocation{row_i, 1} = 'NaN';
    else
        beaconLocation{row_i, 1} = nearest_beacon_data_resampled_segmented.beaconmeta.Name{find(nearest_beacon_data_resampled_segmented.beaconmeta.BeaconID == beaconID(row_i))};
    end
end


% set the unusable beacons (42, 45, 46, 47) to NaNs
unusabale_beacons = [42, 45, 46, 47];
unusable_idx = find(ismember(beaconID, unusabale_beacons));
nans_idx = find(isnan(beaconID));
unusable_percentage = length(unusable_idx)/length(beaconID)*100;
nans_percentage = length(nans_idx)/length(beaconID)*100;



%% combine all data in a table
skinconductance_beacon_table = table(participant,time,beaconID,beaconMajorMinor, beaconLocation,phasic,phasic_z);

% save the table
writetable(skinconductance_beacon_table, 'skinconductance_beacon_table_40_90_limits_12.32_percent_NaNs.csv');

% Provide some feedback
fprintf('A csv file with the skinconductance beacon data has been saved as "skinconductance_beacon_table.csv" in %s\n', pwd);



