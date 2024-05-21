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
%  The folder structure is specified below. It can be changed to fit your needs,
%  however, Ideally you would only adjust the project location.
%
%  If you encounter any problems, or have ideas for improving the pipeline,
%    let me know.
% 
%  Created 15-12-2023, Hans Revers



%% Start with a clean workspace
%  Remove all data currently in the workspace
clearvars;

%% Specify a project name and directory 
%  optionally specify where to find and save data
%  if omitted, this is filled in with defaults

project = [];
project.project_name       = 'PSV';
project.project_directory  = 'c:\projects\PSV';
% === Optional settings ===
% === the defaults should be fine if the recommended structure is used ===
    % project.raw_data_directory       = fullfile(project.project_directory, '0.RawData');       % (default = '<project_directory>\0.RawData')
    % project.processed_data_directory = fullfile(project.project_directory, '2.ProcessedData'); % (default = '<project_directory>\2.ProcessedData')
    % project.output_directory         = fullfile(project.project_directory, '3.Output');        % (default = '<project_directory>\3.Output')

cfg = [];
cfg.ask_create_directory         =  'create'; % 'ask' or 'create"  % (default = 'create')

% check and create directories, and create the project struct
% Would you like a dialog window with that?
I_want_a_dialog_window_to_check_or_change_directories = false; % true or false
if I_want_a_dialog_window_to_check_or_change_directories
    project = create_new_project(cfg, project); % opens the input dialog window
else
    project = check_project_directories(cfg, project); % checks and creates without dialog window
end
clear I_want_a_dialog_window_to_check_or_change_directories cfg; % clean up



%% Get project details form the ParticipantData file and add to the project struct

cfg = [];
cfg.segment_names      = {'AR', 'FirstHalf', 'SecondHalf'};

% === optional settings === 
% the defaults should be fine if the ParticipantData.xlsx template was used
    % cfg.participant_data_dir = project.raw_data_directory;               % the folder that has the participant data
    % cfg.participant_data_filename = 'ParticipantData.xlsx';              % the filename of the participant data 
    % cfg.participants = 'Participant';                                    % the column that has the participant labels 
    % cfg.timeformat = 'TimeFormat';                                       % the column that has the time format ('unixtime' or 'datetime') 
    % cfg.timezone   = 'TimeZone';                                         % the column that has the timezone ('Europe/Amsterdam') 
    % cfg.number_of_segments = 3;                                          % the number of segments that each eda datafile contains (if omitted, this is determined from the segment names) 
    % cfg.segment(1).starttimes = 'StartTimeAR';                           % the column that has the starttimes of the first segment 
    % cfg.segment(1).endtimes   = 'EndTimeAR';                             % the column that has the endtimes of the first segment 
    % cfg.segment(2).starttimes = 'StartTimeFirstHalf';                    % the column that has the starttimes of the second segment 
    % cfg.segment(2).endtimes   = 'EndTimeFirstHalf';                      % the column that has the endtimes of the second segment 
    % cfg.segment(3).starttimes = 'StartTimeSecondHalf';                   % the column that has the starttimes of the third segment 
    % cfg.segment(3).endtimes   = 'EndTimeSecondHalf';                     % the column that has the endtimes of the third segment 

% === note that the match number and condition are not included ===
% === those can be added to the processed data through a script, if needed ===

% Add the relevant participant data to the project struct
project = add_participant_data(cfg, project);




%% write the bookkeeping file
%
%  creates a .csv file with
%  - filename = projectname
%  - file extension = .belt
%  The file is saved in the project root (project.project_directory)
%  Through this file we keep track of wich part of the processing has been
%  done for each participant

cfg = []; % === TODO: add options for rewriting an existing file
project = create_project_bookkeeping(cfg, project);

% === TODO: check whether file already exists, check for differences and
%           report.
%           pps may be added after processing has started


%% Store the number of participants

nof_pps = length(project.pp_labels);  % number of participants
nof_pps = 16;  % === for testing ===


%%  Find all data, cut out the proper segments, and store in a variable

% for each participant, do ...
% (note that pp_i is the index in the participant list, not the participant number)


for segment_i = 1:project.nof_segments
    for pp_i = 1:nof_pps

        % get the participant label (e.g. 'P001')
        pp_label = cell2mat(project.pp_labels(pp_i));

        % get the raw data
        cfg = [];
        cfg.datafolder = fullfile(project.raw_data_directory, pp_label);
        cfg.timezone = cell2mat(project.timezone(pp_i)); % e.g. 'Europe/Amsterdam'
        raw_data = e4eda2matlab(cfg);

        % extract the [starttime - endtime] segment of the data
        cfg = [];
        cfg.starttime  = project.segment(segment_i).starttime(pp_i);
        cfg.endtime    = project.segment(segment_i).endtime(pp_i);
        cfg.timezone   = project.timezone(pp_i); % e.g. 'Europe/Amsterdam'
        cfg.timeformat = project.timeformat(pp_i); % e.g. 'unixtime' or 'datetime'
        % === Not all times appear to be filled in, so check here
        if isempty(cell2mat(cfg.starttime)) || isempty(cell2mat(cfg.endtime))
            warning('Start or endtime for participant %s, segment %s was not provided. Could not process this segment\n', pp_label, project.segment(segment_i).name);
            continue;
        end
        processed_segment = segment_generic(cfg, raw_data);

        % add the participant label and segment name to the processed data struct
        processed_segment.pp_label = pp_label;
        processed_segment.segment_name = project.segment(segment_i).name;        

        % do some reorganizing and rename the conductance field to
        % conductance_raw === TODO: move this outside the pipiline into a
        % function
        [processed_segment.conductance_raw] = processed_segment.conductance; 
        [processed_segment.conductance_raw_z] = processed_segment.conductance_z; 
        processed_segment = rmfield(processed_segment,'conductance');
        processed_segment = rmfield(processed_segment,'conductance_z');
        processed_segment = orderfields(processed_segment,...
            {'pp_label', ...
            'segment_name', ...
            'datatype','orig', ...
            'initial_time_stamp', ...
            'initial_time_stamp_mat', ...
            'fsample', ...
            'timeoff', ...
            'time', ...
            'conductance_raw', ...
            'conductance_raw_z' });

        % save the segmented data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        save(path_filename, 'processed_segment');

        % update bookkeeping
        cfg = [];
        cfg.processing_part = 'segmented';
        cfg.pp_label = pp_label;
        cfg.segment_nr = segment_i;
        cfg.processing_complete = true;
        project = update_project_bookkeeping(cfg, project);

        % Provide some feedback
        fprintf('Data of participant %s is segmented and saved as %s\n', pp_label, path_filename);

    end
end

%% Inspect the raw data
% plot the raw data per segment 
% for all participants in one graph

cfg = [];
cfg.segment_nr = 1; % AR
cfg.data_type = 'conductance_raw';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 2; % First half
cfg.data_type = 'conductance_raw';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 3; % Second half
cfg.data_type = 'conductance_raw';
plot_segmented_data (cfg, project);

%% ARTIFACT CORRECTION
%  Check the EDA data for artifacts and select a solution

clc


segment_i = 1; % AR
for pp_i = 1:nof_pps % for all participants

    % check if segmentation is completed
    if project.segment(segment_i).segmented(pp_i)

        cfg = [];
        cfg.timwin    = 20; % define the timewindow for artifact detection (default = 20)
        cfg.threshold  = 3; % define the threshold for artifact detection (default = 5)
        cfg.default_solution = 'spline'; % set the default solution of all artifacts (default = 'linear')
        cfg.show_result_for_each = 'no'; % state that we do not want to see a figure with the solution for each participant (default = 'yes')
        cfg.handle_already_cleaned_segments = 'skip'; % 'skip|redo|ask' (what to do with segments that have already been artifact corrected)

        % check whether artifact correction has already been done
        if project.segment(segment_i).artifact_corrected(pp_i)

            % === TODO: move this part out of the pipeline into a function
            % artifact correction has already been done, check cfg
            switch cfg.handle_already_cleaned_segments
                case 'skip'
                    % continue to the next participant
                    continue;
                case 'redo'
                    % process the data again
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo artifact correction?';
                    question = sprintf('Artifact correction has already been done for this participant.\nWould you like me to redo it?');
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
        end

        % load the data
        pp_label = cell2mat(project.pp_labels(pp_i));
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        load(path_filename, 'processed_segment');

        % define the raw skin conductance data
        % cfg.validationdata = segmented_data(pp_i).validation_data; % this is currently not implemented, will do upon request
        cfg.participant = pp_label;
        % open the artifact correction window
        processed_segment = artifact_eda_belt(cfg, processed_segment); 
    
        % save the artifact corrected data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        save(path_filename, 'processed_segment');

        % Provide some feedback
        fprintf('Data of participant %s is artifact corrected and saved as %s\n', pp_label, path_filename);

        % update bookkeeping
        cfg = [];
        cfg.processing_part = 'artifact_corrected';
        cfg.pp_label = pp_label;
        cfg.segment_nr = segment_i;
        cfg.processing_complete = true;
        project = update_project_bookkeeping(cfg, project);
    end
end


%% DECONVOLVE and split into phasic and tonic components
%  Next step is to run LedaLab over the corrected data to deconvolve it, and
%  split into phasic and tonic components


cfg = []; % empty any existing configuration settings.
cfg.tempdir = fullfile(project.project_directory, '\Temp'); % temporary directory for datafiles
cfg.conductance   = 'conductance_clean'; % LEDALAB expects a conductance field
cfg.conductance_z = 'conductance_clean_z';

% create the temp folder, if needed
if ~exist(cfg.tempdir, "dir")
    % the folder does not exist
    [status, msg, msgID] = mkdir(cfg.tempdir); % create it
    tempfoldercreated = true; % take note that we created the folder. Remove it when we are done
else
    tempfoldercreated = false;% folder was already there, so leave it.
end


segment_i = 1; % AR
for pp_i = 1:nof_pps % for all participants

    % check if artifact correction is completed
    if project.segment(segment_i).artifact_corrected(pp_i)

        cfg.handle_already_deconvolved_segments = 'ask'; % 'skip|redo|ask' (what to do with segments that have already been artifact corrected)
   
        % check whether the deconvolved data already exists
        if project.segment(segment_i).deconvolved(pp_i)
            % === TODO: move this part out of the pipeline into a function
            % artifact correction has already been done, check cfg
            switch cfg.handle_already_deconvolved_segments
                case 'skip'
                    % continue to the next participant
                    continue;
                case 'redo'
                    % process the data again
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo deconvolution?';
                    question = sprintf('Deconvolution has already been done for this participant.\nWould you like me to redo it?');
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
        end

        % load the data
        pp_label = cell2mat(project.pp_labels(pp_i));
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        load(path_filename, 'processed_segment');

        % do the deconvolution thing
        processed_segment = deconvolve_eda(cfg, processed_segment);

        % save the deconvolved data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        save(path_filename, 'processed_segment');

        % Provide some feedback
        fprintf('Data of participant %s has been deconvolved into a tonic and phasic and saved as %s\n', pp_label, path_filename);

        % update bookkeeping
        cfg = [];
        cfg.processing_part = 'deconvolved';
        cfg.pp_label = pp_label;
        cfg.segment_nr = segment_i;
        cfg.processing_complete = true;
        project = update_project_bookkeeping(cfg, project);
    end
end

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

    plot(processed_segment.time, processed_segment.phasic);
end


% get the first and last time value to set the x range
min_t = processed_segment.time(1);
max_t = processed_segment.time(end);

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

    all_deconvolved_data(pp_i) = processed_segment;
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
x = processed_segment.time;

% Draw the original raw conductance in red
y = segmented_data(pp_i).conductance;
plot(x, y, 'LineWidth', 1, 'Color', 'r');

% let matlab know that you want the next plots to appear in the same figure
hold on;

% Draw the cleaned conductance in green over the raw conductance
% Only the removed artifacts will be visible in red
y = processed_segment.conductance;
plot(x, y, 'LineWidth', 1, 'Color', 'g');

% Draw the phasic data in the same figure
y = processed_segment.phasic;
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





