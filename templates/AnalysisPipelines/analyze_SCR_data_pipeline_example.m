%% This script runs an analysis pipeline for skin conductance data 
%
%  This loads raw skin conductance data.
%  Selects the relevant time interval of that data.
%  Shows the raw data of all participants in a single graph, for a quick
%    visual inspection of the data.
%  Lets you remove artifacts in a graphical interface.
%  Splits the cleaned up data in its tonic and phasic parts.
%
%  The script expects to find the raw data and an excel file that holds
%  time information for each participant in certain folders. Results of the
%  artifact cleaning, and the phasic and tonic components are saved.
%  The folder structure is specified below. It can be changed however it
%  fits tour needs. Ideally you would only adjust the project location.
%
%  If you encounter any problems, or have ideas for improving the pipeline,
%    let me know.
% 
%  Created 15-12-2023, Hans Revers



%% SETUP
% Remove all data currently in the workspace
clearvars;

%% Specify where to find and save data

% set a path to the project
projectfolder = 'C:\Hans\2023_05_22_MarcelWorkshop';

% where to find the raw data
datafolder = [projectfolder '\0.RawData'];

% the excel file that holds starttime and duration per pp
participantDataFile = [projectfolder '\0.RawData\ParticipantData.xlsx'];

% where to save the clean data after artifact correction
cleandatafolder = [projectfolder '\2.ProcessedData\0.CleanData'];

% where to save the phasic data
deconvolveddatafolder = [projectfolder '\2.ProcessedData\1.DeconvolvedData'];

% define temporary directory for datafiles
tempfolder = [projectfolder  '\Temp'];


%% Check whether these folders exist. Ask to create, if needed.

% project folder
if ~exist(projectfolder, "dir")
    % the folder does not exist, ask whether it should be created
    dlgtitle = 'Project folder does not exist';
    question = sprintf('The specified project folder cannot be found.\nWould you like me to create it?');
    opts.Default = 'No';
    answer = questdlg(question, dlgtitle, 'Yes','No', opts.Default);

    % Handle response
    switch answer
        case 'Yes'
            % create the folder
            [status, msg, msgID] = mkdir(projectfolder); % create the folder
        case 'No'
            % abort the program and show an error message
            error("The project folder was not found at the specified location. Please check.");
    end
end

% data folder
if ~exist(datafolder, "dir")
    % the folder does not exist, ask whether it should be created
    dlgtitle = 'Data folder does not exist';
    question = sprintf('The raw data folder cannot be found.\nWould you like me to create it?');
    opts.Default = 'No';
    answer = questdlg(question, dlgtitle, 'Yes','No', opts.Default);

    % Handle response
    switch answer
        case 'Yes'
            % create the folder
            [status, msg, msgID] = mkdir(datafolder); % create the folder
        case 'No'
            % abort the program and show an error message
            error("The raw data folder was not found at the specified location. Please check.");
    end
end

% clean data folder
if ~exist(cleandatafolder, "dir")
    % the folder does not exist, ask whether it should be created
    dlgtitle = 'Clean data folder does not exist';
    question = sprintf('The clean data folder cannot be found.\nWould you like me to create it?');
    opts.Default = 'No';
    answer = questdlg(question, dlgtitle, 'Yes','No', opts.Default);

    % Handle response
    switch answer
        case 'Yes'
            % create the folder
            [status, msg, msgID] = mkdir(cleandatafolder); % create the folder
        case 'No'
            % abort the program and show an error message
            error("The clean data folder was not found at the specified location. Please check.");
    end
end

% deconvolved data folder
if ~exist(deconvolveddatafolder, "dir")
    % the folder does not exist, ask whether it should be created
    dlgtitle = 'Deconvolved data folder does not exist';
    question = sprintf('The deconvolved data folder cannot be found.\nWould you like me to create it?');
    opts.Default = 'No';
    answer = questdlg(question, dlgtitle, 'Yes','No', opts.Default);

    % Handle response
    switch answer
        case 'Yes'
            % create the folder
            [status, msg, msgID] = mkdir(deconvolveddatafolder); % create the folder
        case 'No'
            % abort the program and show an error message
            error("The deconvolved data folder was not found at the specified location. Please check.");
    end
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
%  as numbers. However, the corresponding folders al start with P, so we
%  will have to fix that further down.
pp_nrs = [
    126, 127, 128, 129, 130, 131, 132, 133, 134, 135, ...
    136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, ...
    ];

% the number of participants
nof_pps = size(pp_nrs,2); % 21



%%  Find all data, cut out the proper segments, and store in a variable

% for each participant, do ...
% (note that pp_i is the index in the participant list, not the participant number)
for pp_i = 1:nof_pps 
    
    % we get the participant number here
    pp_nr = pp_nrs(pp_i); 
    % The folders with data have a P before the number, so paste a 'P' before the participant number
    pp_label = ['P', num2str(pp_nr, '%03d')]; 

    % create the full path to the data folder of this participant
    pp_datafolder = fullfile(datafolder, pp_label);

    % extract the start and duration from the participantData file
    % find the row that has the current participant number
    participantData_index = find(participantData.Participant==pp_nr);
    % read the starttime, duration, and timezone from that row
    starttime = participantData.StartTime(participantData_index); 
    duration = participantData.Duration(participantData_index); 
    timezone = string(participantData.TimeZone(participantData_index)); 

    % get the data
    cfg = []; 
    cfg.datafolder = pp_datafolder; 
    cfg.timezone = timezone;
    raw_data = e4eda2matlab(cfg);

    % extract the [starttime - starttime+duration] segment of the data
    cfg = []; 
    cfg.starttime = starttime; 
    cfg.duration = duration; 
    segmented_data(pp_i) = segment_generic(cfg, raw_data);
end


%% Inspect the raw data
% plot the segments of all participants in one graph

figure; % create a new figure
hold on; % indicate that we want to plot multiple lines in the same graph

for pp_i = 1:nof_pps % for all participants
    % draw the data, x=time, y=conductance
    plot(segmented_data(pp_i).time, segmented_data(pp_i).conductance);
end

% get the first and last time value to set the x range
min_t = segmented_data(1).time(1);
max_t = segmented_data(1).time(end);

xlabel('Time (s)');
xlim([min_t max_t]);
ylabel('Conductance (\muS)')
title('Raw skin conductance data');
legend(string(pp_nrs), 'Location', 'eastoutside');

hold off;


%% ARTIFACT CORRECTION
%  Check the EDA data for artifacts and select a solution

cfg = [];
cfg.timwin    = 20; % define the timewindow for artifact detection (default = 20)
cfg.threshold  = 3; % define the threshold for artifact detection (default = 5)
cfg.interp_method = 'spline'; % set the default solution of all artifacts (default = 'linear')
cfg.confirm = 'no'; % state that we do not want to see a figure with the solution for each participant (default = 'yes')

for pp_i = 1:nof_pps % for all participants
    % specify where to save the clean data, with what filename
    clean_data_path_filename = [cleandatafolder '\P' num2str(pp_nrs(pp_i)) '_cleandata.mat'];
    % check whether this file alreay exists
    if exist(clean_data_path_filename, 'file')
        % the file already exist, ask whether user wants to process again
        % or skip this file
        dlgtitle = 'Cleaned data file already exists';
        question = sprintf('A cleaned datafile already exists for participant %d.\nWould you like to redo the artifact correction? (This deletes the previous file)\nOr skip this one?', pp_nrs(pp_i));
        opts.Default = 'Skip';
        answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);

        % Handle response
        switch answer
            case 'Skip'
                % continue to the next participant
                continue;
            case 'Redo'
                % process the data again
        end
    end

    % define the raw skin conductance data
    cfg.validationdata = segmented_data(pp_i).conductance;
    cfg.participant = num2str(pp_nrs(pp_i));
    % open the artifact correction window
    clean_data = artifact_eda(cfg, segmented_data(pp_i)); 
    % save the cleaned up skin conductance data
    save(clean_data_path_filename, 'clean_data');

end


%% DECONVOLVE and split into phasic and tonic components
%  Next step is to run LedaLab over the corrected data to deconvolve it, and
%  split into phasic and tonic components

cfg = []; % empty any existing configuration settings.
cfg.tempdir = tempfolder; % temporary directory for datafiles, this directory is defined above (one of the first things in this pipeline)

% create the temp folder, if needed
if ~exist(tempfolder, "dir")
    % the folder does not exist, ask whether it should be created
    [status, msg, msgID] = mkdir(tempfolder); % create the folder
    tempfoldercreated = true;
else
    tempfoldercreated = false;
end


for pp_i=1:nof_pps
    % check whether the deconvolved data already exists
    deconvolved_data_path_filename = [deconvolveddatafolder '\P' num2str(pp_nrs(pp_i)) '_deconvolved_data.mat'];
    if exist(deconvolved_data_path_filename, 'file')
        % the file already exist, ask whether user wants to process again
        % or skip this file
        dlgtitle = 'Devonvolved data file already exists';
        question = sprintf('A deconvolved datafile already exists for participant %d.\nWould you like to redo the deconvolution? (This deletes the previous file)\nOr skip this one?', pp_nrs(pp_i));
        opts.Default = 'Skip';
        answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
        % Handle response
        switch answer
            case 'Skip'
                % continue to the next participant
                continue;
            case 'Redo'
                % process the data again
        end
    end

    % get the cleaned up data of this participant
    clean_data_path_filename = [cleandatafolder '\P' num2str(pp_nrs(pp_i)) '_cleandata.mat'];
    load(clean_data_path_filename);

    % do the deconvolution thing
    deconvolved_data = deconvolve_eda(cfg, clean_data);

    % show the results in a graph
    figure; plot(deconvolved_data.time, deconvolved_data.conductance_z, deconvolved_data.time, deconvolved_data.tonic_z, deconvolved_data.time, deconvolved_data.phasic_z, 'k');

    % save the deconvolved data
    save(deconvolved_data_path_filename, 'deconvolved_data');

end

clear deconvolved_data;

if tempfoldercreated
    % we created a temporary folder, now remove it
    rmdir(tempfolder, 's'); % this fails sometimes, don't know why
end


%% Inspect the phasic components of all participants


figure;
hold on;


for pp_i=1: nof_pps
    deconvolved_data_path_filename = [deconvolveddatafolder '\P' num2str(pp_nrs(pp_i)) '_deconvolved_data.mat'];
    load(deconvolved_data_path_filename);

    plot(deconvolved_data.time, deconvolved_data.phasic);
end


% get the first and last time value to set the x range
min_t = deconvolved_data.time(1);
max_t = deconvolved_data.time(end);

xlabel('Time (s)');
xlim([min_t max_t]);
ylabel('Conductance (\muS)')
title('Skin conductance data - phasic component');
legend(string(pp_nrs), 'Location', 'eastoutside');


hold off;


%% GRAND AVERAGING MULTIPLE PARTICIPANTS
%  Creating grand average of the deconvolved data over all participants. 

% combine the deonvolved data of all participants in one struct
for pp_i=1:nof_pps
    deconvolved_data_path_filename = [deconvolveddatafolder '\P' num2str(pp_nrs(pp_i)) '_deconvolved_data.mat'];
    load(deconvolved_data_path_filename);

    all_deconvolved_data(pp_i) = deconvolved_data;
end

% calculate the grand averages over participants
cfg = [];
cfg.fields = ["time" "fsample" "conductance" "phasic" "tonic" "conductance_z" "phasic_z" "tonic_z"];
% The field have to begin with time (or a variable with the same length) to make it work. 
% fsample has length 1, and causes issues
% TODO Change getgrandaverages code to prevent dependence of field order
GA_deconvolved_data = getgrandaverages(cfg, all_deconvolved_data); % TODO: inspect the getgrandaverages function


% show the grand average phasic signal
figure;
plot(GA_deconvolved_data.time, GA_deconvolved_data.phasic);

% again, but with some smoothing
figure;
plot(GA_deconvolved_data.time, movmean(GA_deconvolved_data.phasic, 40));


