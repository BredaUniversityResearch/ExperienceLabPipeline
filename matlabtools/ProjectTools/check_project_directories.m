function project = check_project_directories(cfg, project)
%% CHECK_PROJECT_DIRECTORIES
%  function check_project_directories(project, create_directory)
% 
% *DESCRIPTION*
% Checks whether all directories in a project exist, and creates those that do not exist,
% askes the user to create if specified by create_directory = false
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.processed_data_directory
%   project.output_directory
% cfg.create_directory = true or false (default = true)
%   <true> if the directory does not exist, it is created
%   <false> if the directory does not exist, the user is asked whether to
%   create or not
%

% *OUTPUT*
% creates directories that do not exist, if specified

% check input
if ~isfield(project, 'project_name')
    error('The project struct has no project_name field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'project_directory')
    error('The project struct has no project_directory field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'raw_data_directory')
    project.raw_data_directory       = fullfile(project.project_directory, '0.RawData');
end
if ~isfield(project, 'processed_data_directory')
    project.processed_data_directory       = fullfile(project.project_directory, '2.ProcessedData');
end
if ~isfield(project, 'output_directory')
    project.output_directory       = fullfile(project.project_directory, '3.Output');
end
if ~isfield(cfg, 'ask_create_directory')
    cfg.ask_create_directory = 'create';
end
if ~isfield(cfg, 'create_directory')
    cfg.create_directory = true;
end
if ~isfield(cfg, 'show_input_window')
    cfg.show_input_window = false;
end



%% Check whether these folders exist. Ask to create, if needed.

% if a folder does not exist, should we create it?
if strcmp(cfg.ask_create_directory, 'create')
    create_directory = true;
else
    create_directory = false;
end

% project folder
directory = project.project_directory;
cfg = [];
cfg.directory_name = 'Project folder';
cfg.create_directory = create_directory;
check_directory(cfg, directory); % call function to check and create

% Raw data folder
directory = project.raw_data_directory;
cfg = [];
cfg.directory_name = 'Raw data folder';
cfg.create_directory = create_directory;
check_directory(cfg, directory); % call function to check and create

% Processed data folder
directory = project.processed_data_directory;
cfg = [];
cfg.directory_name = 'Processed data folder';
cfg.create_directory = create_directory;
check_directory(cfg, directory); % call function to check and create

% Output folder
directory = project.output_directory;
cfg = [];
cfg.directory_name = 'Output folder';
cfg.create_directory = create_directory;
check_directory(cfg, directory); % call function to check and create


end



