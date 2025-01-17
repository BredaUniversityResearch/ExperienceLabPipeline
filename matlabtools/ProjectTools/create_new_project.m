function newproject = create_new_project(cfg, project)
%% CREATE_NEW_PROJECT
%  function newproject = create_new_project(project)
% 
% *DESCRIPTION*
% Opens a window that let's you specify a new project
% - project name
% - project directory
%
% it also let's you specify the directorie where the raw data is stored
% and the diretories where the results of each processing step will be
% stored: the segmented, artifact corrected, deconvolved data, and the
% output (a data file for statistical analysis, and graphs).
% A standardized structure of directories is recommended and is filled
% in automatically as such:
%
%    <project dir>
%        0.RawData
%        1.Scripts&Tools (recommended dir, not created by function)
%        2.ProcessedData
%        3.Output
%        4.Documentation (recommended dir, not created by function)
%
% These directory can be changed, if necessary.
%
% You can specify whether directories that do not exist, are created
% automatically, or whether you want to be prompted what to do in such cases


% *INPUT*
% A project struct can be provided to the create_new_project function.
% Provide whatever should already be filled in.
% For instance: if you provide a project_name and project_directory, these
% will be filled in in the appropriate input field.
% Additionally, since the project_directory is now known, the other
% directories will be fill in according to the recommended structure.
% For a completely blank project, use 
% project = [];
%
% A cfg struct is used to pass along config settings
% cfg.ask_create_directory = 'ask' or 'create'  % (default = 'create')
%    Whether directories should just be created if they do not exist,
%    or the user should be asked to decide for each directory that does not
%    exist.

% *OUTPUT*
% A project struct will be returned.
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.processed_data_directory
%   project.output_directory

%% check input
if ~isfield(cfg, 'show_input_window')
    cfg.show_input_window = false;
end

%% check and create directories

if cfg.show_input_window % Open the app to create a new project

    NewProjectApp = CreateNewProjectApp(cfg, project); % open the app
    waitfor(NewProjectApp,'closeapplication',1) % wait until the app closes
    if NewProjectApp.save_project % if the [Create] button was pressed
        newproject = NewProjectApp.project; % store the project struct
        cfg = NewProjectApp.cfg; % update the config struct
        delete(NewProjectApp); % delete the app from workspace
        newproject = check_project_directories(cfg, newproject); % check directories and create if needed
    else
        newproject = [];
        delete(NewProjectApp); % delete the app from workspace
        return;
    end

else % check and create directories without dialog window

    newproject = check_project_directories(cfg, project); 

end



