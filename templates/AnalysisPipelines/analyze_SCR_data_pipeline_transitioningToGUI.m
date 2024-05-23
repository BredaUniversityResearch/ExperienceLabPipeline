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

%% Open the project   
% 
%  Open an existing project or create a new one if non exists 

project = [];
project.project_name       = 'PSV';
project.project_directory  = 'c:\projects\PSV';
% === Optional settings ===
% === the defaults directory structure is recommended. An alternative structure can be set via 
    % project.raw_data_directory       = fullfile(project.project_directory, '0.RawData');       % (default = '<project_directory>\0.RawData')
    % project.processed_data_directory = fullfile(project.project_directory, '2.ProcessedData'); % (default = '<project_directory>\2.ProcessedData')
    % project.output_directory         = fullfile(project.project_directory, '3.Output');        % (default = '<project_directory>\3.Output')
% === or ask for an input window via cfg.show_input_window = true

cfg = [];
cfg.ask_create_directory    =  'create'; % 'create" directories that do not exist, or 'ask' (default = 'create')
cfg.show_input_window       = false; %  show an input window to check and edit the directories

% Get project details from the ParticipantData file and add to the project struct
cfg.segment_names      = {'AR', 'FirstHalf', 'SecondHalf'};

% === optional settings === 
% === the defaults should be fine if the ParticipantData.xlsx template was used
    % cfg.participant_data_dir      = project.raw_data_directory;          % the folder that has the participant data
    % cfg.participant_data_filename = 'ParticipantData.xlsx';              % the filename of the participant data 
    % cfg.participants          = 'Participant';                           % the column that has the participant labels 
    % cfg.timeformat            = 'TimeFormat';                            % the column that has the time format ('unixtime' or 'datetime') 
    % cfg.timezone              = 'TimeZone';                              % the column that has the timezone ('Europe/Amsterdam') 
    % cfg.number_of_segments    =  3;                                      % the number of segments that each eda datafile contains (if omitted, this is determined from the segment names) 
    % cfg.segment(1).starttimes = 'StartTimeAR';                           % the column that has the starttimes of the first segment 
    % cfg.segment(1).endtimes   = 'EndTimeAR';                             % the column that has the endtimes of the first segment 
    % cfg.segment(2).starttimes = 'StartTimeFirstHalf';                    % the column that has the starttimes of the second segment 
    % cfg.segment(2).endtimes   = 'EndTimeFirstHalf';                      % the column that has the endtimes of the second segment 
    % cfg.segment(3).starttimes = 'StartTimeSecondHalf';                   % the column that has the starttimes of the third segment 
    % cfg.segment(3).endtimes   = 'EndTimeSecondHalf';                     % the column that has the endtimes of the third segment 

% === note that the match number and condition are not included ===
% === those can be added to the processed data through a script, if needed ===

project = belt_open_project(cfg, project);


%% Store the number of participants

nof_pps = length(project.pp_labels);  % number of participants


%%  SEGMENTATION
% Find all data, cut out the proper segments, store in a variable
% 'processed_segment, and save that as
% <pp_label>_processed_segment_<segment_name>.mat
% The project bookkeeping is updated to note for which segment/pp the
% segmenting is complete.


% for each participant, do ...
% (note that pp_i is the index in the participant list, not the participant number)
for segment_i = 1:project.nof_segments
    for pp_i = 1:nof_pps

        cfg = [];
        cfg.segment_nr = segment_i;
        cfg.pp_nr = pp_i;
        cfg.handle_already_segmented_data = 'redo'; % 'skip|ask|redo'
        
        [processed_segment, project] = belt_get_data_segment(cfg, project);

    end
end

%% Inspect the raw data
% plot the raw data per segment 
% for all participants in one graph

% === to plot the data of all participants, use
% cfg.pp_labels = 'all'; (default)
% === to plot data of a few spefic participants, use e.g.
% cfg.pp_labels = {'P005', 'P007'};

% === the data can be any of the processed data field
% cfg.data_type = 'conductance_raw';
% cfg.data_type = 'conductance_raw_z';
% cfg.data_type = 'conductance_artifact_corrected';
% cfg.data_type = 'conductance_artifact_corrected_z';
% cfg.data_type = 'conductance_deconvolved';
% cfg.data_type = 'conductance_deconvolved_z';
% === of course, the artifact corrected and deconvolved data do not
% exist yet, at this point in the pipeline

cfg = [];
cfg.segment_nr = 1; % AR
cfg.data_type = 'conductance_raw';
cfg.pp_labels = 'all';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 2; % First half
cfg.data_type = 'conductance_raw_z';
cfg.pp_labels = {'P005', 'P007'};
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 3; % Second half
plot_segmented_data (cfg, project);


%% Remove data that is not usable from further processing

cfg = [];
cfg.segment_nr = 1;
cfg.pp_labels = {}; % e.g. {'P001', 'P007', 'P012'};

project = belt_set_include_segment_pp(cfg, project);


%% ARTIFACT CORRECTION
%  Check the EDA data for artifacts and select a solution

for segment_i = 1:project.nof_segments
    for pp_i = 1:nof_pps

        cfg = [];
        cfg.segment_nr = segment_i;
        cfg.pp_nr = pp_i;
        cfg.handle_already_cleaned_segments = 'skip'; % 'skip|redo|ask' (what to do with segments that have already been artifact corrected)

        % do the artifact correction
        [processed_segment, project] = belt_artifact_correction(cfg, project);

    end
end

%% Inspect the cleaned data
% plot the artifact corrected data per segment 
% for all participants in one graph

cfg = [];
cfg.segment_nr = 1; % AR
cfg.data_type = 'conductance_clean';
cfg.pp_labels = 'all';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 2; % First half
cfg.data_type = 'conductance_clean_z';
cfg.pp_labels = 'all';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 3; % Second half
cfg.data_type = 'conductance_clean';
plot_segmented_data (cfg, project);


%% Remove data that is not usable from further processing

cfg = [];
cfg.segment_nr = 1;
cfg.pp_labels = {}; % e.g. {'P001', 'P007', 'P012'};

project = belt_set_include_segment_pp(cfg, project);




%% DECONVOLVE and split into phasic and tonic components
%  Next step is to run LedaLab over the corrected data to deconvolve it, and
%  split into phasic and tonic components


for segment_i = 1:project.nof_segments % for all segments
    for pp_i = 1:nof_pps % for all participants

        cfg = []; % empty any existing configuration settings.
        cfg.tempdir = fullfile(project.project_directory, '\Temp'); % temporary directory for datafiles
        cfg.conductance   = 'conductance_clean'; % LEDALAB expects a conductance field
        cfg.conductance_z = 'conductance_clean_z';
        cfg.segment_nr = segment_i;
        cfg.pp_nr = pp_i;
        cfg.handle_already_deconvolved_segments = 'redo';

        % do the deconvolution
        [processed_segment, project] = belt_deconvolve_eda(cfg, project);
        
    end
end


%% Inspect the deconvolved data
% plot the artifact corrected data per segment 
% for all participants in one graph

cfg = [];
cfg.segment_nr = 1; % AR
cfg.data_type = 'conductance_phasic';
cfg.pp_labels = 'all';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 2; % First half
cfg.data_type = 'conductance_phasic';
cfg.pp_labels = 'all';
plot_segmented_data (cfg, project);

cfg = [];
cfg.segment_nr = 3; % Second half
cfg.data_type = 'conductance_phasic';
plot_segmented_data (cfg, project);


%% Remove data that is not usable from further processing

cfg = [];
cfg.segment_nr = 1;
cfg.pp_labels = {}; % e.g. {'P001', 'P007', 'P012'};

project = belt_set_include_segment_pp(cfg, project);


%% ============================= PIPELINE IS UPDATE TO THIS POINT =========
%  TODO:
%  create some more plot options
%  export the data for analysis

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





