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

%%%%%%%%%%% New GUI version %%%%%%%%%%%%
% opens a window to set and check the directories
% it also creates a bookkeeping file (project_name.belt)

% Optionally, you can fill in the input fields here
project = [];
project.project_name = "test_project";
project.project_directory = "c:\projects\test_project";
% project.raw_data_directory = "raw";
% project.segmented_data_directory = "segm";
% project.artifact_corrected_data_directory = "art";
% project.deconvolved_data_directory = "decon";
% project.output_directory = "out";
project.ask_create_directory = "create"; % "ask" or "create"


% create the new project
project = create_new_project(project);


%%


% define temporary directory for datafiles
tempfolder = fullfile(projectfolder, '\Temp');


%% 
 

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
pp_nrs = [1:5];

% the number of participants
nof_pps = length(pp_nrs);  



%%  Find all data, cut out the proper segments, and store in a variable

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
    % participantData_index = find(participantData.Participant==pp_nr); % use this if the excel file contains participant numbers (3)
    
    % read the starttime, duration, and timezone from that row
    timeformat = participantData.TimeFormat(participantData_index); % e.g. 'UnixTime'
    starttimeIndoor = participantData.StartTimeIndoor(participantData_index); 
    durationIndoor = participantData.DurationIndoor(participantData_index); 
    timezone = string(participantData.TimeZone(participantData_index)); % e.g. 'Europe/Amsterdam'

    % get the data
    cfg = []; 
    cfg.datafolder = pp_datafolder; 
    cfg.timezone = timezone; 
    raw_data = e4eda2matlab(cfg);

    % extract the [starttime - starttime+duration] segment of the data
    cfg = []; 
    cfg.starttime = starttimeIndoor; 
    cfg.duration = durationIndoor; 
    cfg.timeformat = timeformat; 
    segmented_data(pp_i) = segment_generic(cfg, raw_data);

    % Provide some feedback
    fprintf('Data of participant %s loaded and segmented\n', pp_label);
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

    % get the participant number
    pp_nr = pp_nrs(pp_i); 
    % Paste a P and leading zeros before the number, 
    pp_label = ['P', num2str(pp_nr, '%03d')]; 
    % specify where to save the clean data, with what filename 
    % (add the '_cleadata' suffix and the '.mat' extension)
    clean_data_path_filename = fullfile(cleandatafolder, [pp_label, '_cleandata.mat']);

    % check whether this file alreay exists
    if exist(clean_data_path_filename, 'file')
        % the file already exist, ask whether user wants to process again
        % or skip this file
        dlgtitle = 'Cleaned data file already exists';
        question = sprintf('A cleaned datafile already exists for participant P%03d.\nWould you like to redo the artifact correction? (This deletes the previous file)\nOr skip this one?', pp_nrs(pp_i));
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
    cfg.participant = pp_label;
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

    % get the participant number
    pp_nr = pp_nrs(pp_i); 
    % Paste a P and leading zeros before the number, 
    pp_label = ['P', num2str(pp_nr, '%03d')]; 
    % specify where to save the clean data, with what filename 
    % (add the '_deconvolved_data' suffix and the '.mat' extension)
    deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);
    
    % check whether the deconvolved data already exists
    if exist(deconvolved_data_path_filename, 'file')
        % the file already exist, ask whether user wants to process again
        % or skip this file
        dlgtitle = 'Devonvolved data file already exists';
        question = sprintf('A deconvolved datafile already exists for participant P%03d.\nWould you like to redo the deconvolution? (This deletes the previous file)\nOr skip this one?', pp_nrs(pp_i));
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
    clean_data_path_filename = fullfile(cleandatafolder, [pp_label, '_cleandata.mat']);
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
    % get the participant number
    pp_nr = pp_nrs(pp_i); 
    % Paste a P and leading zeros before the number, 
    pp_label = ['P', num2str(pp_nr, '%03d')]; 
    % specify where to save the clean data, with what filename 
    % (add the '_deconvolved_data' suffix and the '.mat' extension)
    deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);
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

% combine the deconvolved data of all participants in one struct
for pp_i=1:nof_pps
    % get the participant number
    pp_nr = pp_nrs(pp_i); 
    % Paste a P and leading zeros before the number, 
    pp_label = ['P', num2str(pp_nr, '%03d')]; 
    % specify where to save the clean data, with what filename 
    % (add the '_deconvolved_data' suffix and the '.mat' extension)
    deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);

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


%% INSPECT THE RESULTS PER PARTICIPANT
%  This lets you inspect the results of artefact correction and
%  deconvolution per participant. It can be usefull to check whether your
%  choices in artefact rejection did not cause strange behaviour in the
%  deconvolution process.

% NOTE TO JOEL: 
% ===============
% apparently, the raw data is not stored in the deconvoluted data. 
% I will fix that, so loading seprate data files will not be necessary. 
% But for now, since your data has already been processed, you will need to work around that issue:
%  - This script assumes you have the raw segmented data in working memory.
%  - This is called segmented_data en is constructed in your pipeline

% First indicate which participant you would like to inspect
% Either use the index of the participant list ...
pp_i = 5;
pp_nr = pp_nrs(pp_i);
% or set the participant number directly
% pp_nr = 1;

% load the data of this participant
pp_label = ['P', num2str(pp_nr, '%03d')];
deconvolved_data_path_filename = fullfile(deconvolveddatafolder, [pp_label, '_deconvolved_data.mat']);
load(deconvolved_data_path_filename);

% Let's show the original conductance and the artefact corrected
% conductance in one graph
% Add the phasic part in the same graph.

% Start by opening a new figure
figure;

% specify what is on the x-axis
x = deconvolved_data.time;

% Draw the original raw conductance in red
y = segmented_data(pp_i).conductance;
plot(x, y, 'LineWidth', 1, 'Color', 'r');

% let matlab know that you want the next plots to appear in the same figure
hold on;

% Draw the cleaned conductance in green over the raw conductance
% Only the removed artifacts will be visible in red
y = deconvolved_data.conductance;
plot(x, y, 'LineWidth', 1, 'Color', 'g');

% Draw the phasic data in the same figure
y = deconvolved_data.phasic;
plot(x, y, 'LineWidth', 1, 'Color', 'b');

% Set the labels at the x- and y-axes, the title, and the legend
xlabel('Time (s)');
ylabel('Skin Conductace (\muS)');
title(['Participant ', pp_label]);
legend('raw', 'clean', 'phasic');

% Set the range of the graph
xlim([0 max(x)]); % x corresponds exactly to the data
ylim([0 30]); % <================= The y-axis has a fixed range of 0-30 ...
% so that the data is easy to compare between participants. 
% Change the number if your graphs do not fit, 
% or just remove this line so that the limits are adjusted to the data. 
% That makes it more difficult to compare though. 




