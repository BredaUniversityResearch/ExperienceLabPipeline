function project = belt_open_project(cfg, project)
%% BELT_OPEN_PROJECT
%  function segment = belt_open_project(cfg, project)
% 
% *DESCRIPTION*
% Checks whether a project file already exists for the give project_name
% and project_directory. If not, it creates a new project file, reads the
% participant data, and returns the project struct.
% If a project file already exists, it opens the project file, constructs
% the project struct out of that.
% Then reads the participant file and compares the participant list to the 
% one in the project. New participants will be added.
%
% *INPUT*
% A project struct:
%   === required ===
%   project.project_name
%   project.project_directory
%   === optional ===
%       the defaults directory structure is recommended 
%       If you wish an alternative structure, you can either do that via the
%       following project fields
%   project.raw_data_directory       = fullfile(project.project_directory, '0.RawData');       % (default = '<project_directory>\0.RawData')
%   project.processed_data_directory = fullfile(project.project_directory, '2.ProcessedData'); % (default = '<project_directory>\2.ProcessedData')
%   project.output_directory         = fullfile(project.project_directory, '3.Output');        % (default = '<project_directory>\3.Output')
%   === or ask for an input window via cfg.show_input_window = true
%
% Configuration options
%   === required ===
%   cfg.segment_names      = {'AR', 'FirstHalf', 'SecondHalf'}; % provide a  name for each segment
%   === optional for directory creation ===
%   cfg.ask_create_directory    = 'ask|create";  % Create directories that do not exist? (default = 'create')
%   cfg.show_input_window       = true|false;  % whether to show an input window to check and edit the directories (default = false)
%   === optional for reading participant data === 
%       the defaults should be fine if the ParticipantData.xlsx template was used
%   cfg.participant_data_dir      = project.raw_data_directory;          % the folder that has the participant data
%   cfg.participant_data_filename = 'ParticipantData.xlsx';              % the filename of the participant data 
%   cfg.participants          = 'Participant';                           % the column that has the participant labels 
%   cfg.timeformat            = 'TimeFormat';                            % the column that has the time format ('unixtime' or 'datetime') 
%   cfg.timezone              = 'TimeZone';                              % the column that has the timezone ('Europe/Amsterdam') 
%   cfg.number_of_segments    =  3;                                      % the number of segments that each eda datafile contains (if omitted, this is determined from the segment names) 
%   cfg.segment(1).starttimes = 'StartTimeAR';                           % the column that has the starttimes of the first segment 
%   cfg.segment(1).endtimes   = 'EndTimeAR';                             % the column that has the endtimes of the first segment 
%   cfg.segment(2).starttimes = 'StartTimeFirstHalf';                    % the column that has the starttimes of the second segment 
%   cfg.segment(2).endtimes   = 'EndTimeFirstHalf';                      % the column that has the endtimes of the second segment 
%   cfg.segment(3).starttimes = 'StartTimeSecondHalf';                   % the column that has the starttimes of the third segment 
%   cfg.segment(3).endtimes   = 'EndTimeSecondHalf';                     % the column that has the endtimes of the third segment 


% *OUTPUT*
% creates directories that do not exist, if specified

% check input
% input is checked in the specific functions


%
if isfield(project, 'project_directory') && isfield(project, 'project_name')
    % the full path to the location of the project bookkeeping file
    path_filename = fullfile(project.project_directory, ['project_' project.project_name '.belt']);
    
    % temp fix for ongoing projects, to be removed later
    old_path_filename = fullfile(project.project_directory, ['project_' project.project_name '.mat']); 
    if ~isfile(path_filename) && isfile(old_path_filename)
        path_filename = old_path_filename;
    end
else
    path_filename = ''; % no project data has been provided, show the create project window
end

% First check whether a project bookkeeping file already exists
if isfile(path_filename) % file already exists

    % first construct the project directories that were asked before loading the existing one
    project_provided = create_new_project(cfg, project); 

    % get the existing project struct
    load(path_filename, 'project');

    % Provide some feedback
    fprintf('Existing project bookkeeping file "%s" loaded.\n', path_filename);

    % If multiple people are working on a project via Teams/OneDrive
    % the directories need to change to the ones of the current user
    if ~strcmp(project.project_directory, project_provided.project_directory)
        fprintf('Requested directories differ from those in the existing project.\n');
        fprintf('project_directory changed from "%s" to  "%s".\n', project.project_directory, project_provided.project_directory);
        project.project_directory        = project_provided.project_directory;
        fprintf('raw_data_directory changed from "%s" to  "%s".\n', project.raw_data_directory, project_provided.raw_data_directory);
        project.raw_data_directory       = project_provided.raw_data_directory;
        fprintf('processed_data_directory changed from "%s" to  "%s".\n', project.processed_data_directory, project_provided.processed_data_directory);
        project.processed_data_directory = project_provided.processed_data_directory;
        fprintf('output_directory changed from "%s" to  "%s".\n', project.output_directory, project_provided.output_directory);
        project.output_directory         = project_provided.output_directory;
    end

    % Compare the project data to the participantdata excel file
    % check for removed or added participants, and for changed start/end times
    fprintf('Checking for changes in the ParticipantData ...\n');
    project = update_participant_data(cfg, project);


else % no project bookkeeping file found at location, create a new one

    % check and create directories, and create the project struct
    project = create_new_project(cfg, project); 
    
    % Add the relevant participant data to the project struct
    project = add_participant_data(cfg, project);
    
    % add the bookkeeping part to the project
    for segment_i = 1:project.nof_segments
        project.segment(segment_i).segmented          = zeros(size(project.pp_labels));
        project.segment(segment_i).artifact_corrected = zeros(size(project.pp_labels));
        project.segment(segment_i).deconvolved        = zeros(size(project.pp_labels));
        project.segment(segment_i).include            = ones(size(project.pp_labels));
    end
    
end

% save the project struct as a matlab datafile
save(path_filename, 'project');

end % belt_open_project



