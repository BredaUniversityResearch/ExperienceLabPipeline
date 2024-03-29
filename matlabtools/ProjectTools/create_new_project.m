function newproject = create_new_project(project)
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
%           0.SegmentedData
%            1.CleanData
%            2.DeconvolvedData
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

% *OUTPUT*
% A project struct will be returned.
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.segmented_data_directory
%   project.artifact_corrected_data_directory
%   project.deconvolved_data_directory
%   project.output_directory
%   project.ask_create_directory


%% Open the app to create a new project

NewProjectAppApp = CreateNewProjectApp(project); % open the app

waitfor(NewProjectAppApp,'closeapplication',1) % wait until the app closes

if NewProjectAppApp.save_project % if the [Create] button was pressed
    newproject = NewProjectAppApp.project; % store the project struct
end

delete(NewProjectAppApp); % delete the app from workspace


%% Check whether these folders exist. Ask to create, if needed.

% if a folder does not exist, should we create it?
if strcmp(newproject.ask_create_directory, 'create')
    create_directory = true;
else
    create_directory = false;
end

% project folder
directory = newproject.project_directory;
directory_name = 'Project folder';
check_directory(directory, directory_name, create_directory) % call function to check and create

% Raw data folder
directory = newproject.raw_data_directory;
directory_name = 'Raw data folder';
check_directory(directory, directory_name, create_directory) % call function to check and create

% Segmented data folder
directory = newproject.segmented_data_directory;
directory_name = 'Segmented data folder';
check_directory(directory, directory_name, create_directory) % call function to check and create

% Artifact corrected data folder
directory = newproject.artifact_corrected_data_directory;
directory_name = 'Artifact corrected data folder';
check_directory(directory, directory_name, create_directory) % call function to check and create

% Deconvolved data folder
directory = newproject.deconvolved_data_directory;
directory_name = 'Deconvolved data folder';
check_directory(directory, directory_name, create_directory) % call function to check and create

% Output folder
directory = newproject.output_directory;
directory_name = 'Output folder';
check_directory(directory, directory_name, create_directory) % call function to check and create


end

function check_directory(directory, directory_name, create_directory)

    % provide some feedback
    fprintf('Checking %s "%s". ', directory_name, directory);

    if ~exist(directory, "dir")
        % the folder does not exist, check whether we should ask or create
        if create_directory
            % create the folder
            [status, msg, msgID] = mkdir(directory); % create the folder
            fprintf('Directory created.\n');
        else
            % ask whether it should be created
            dlgtitle = [directory_name ' does not exist'];
            question = ['I cannot find the folder "' directory '". Would you like me to create it?'];
            opts.Default = 'No';
            answer = questdlg(question, dlgtitle, 'Yes','No', opts.Default);
    
            % Handle response
            switch answer
                case 'Yes'
                    % create the folder
                    [status, msg, msgID] = mkdir(directory); % create the folder
                    fprintf('Directory created.\n');
                case 'No'
                    % abort the program and show an error message
                    error(['The folder "' directory '" was not found at the specified location. Please check.']);
            end
        end
    else
        fprintf('Directory already exists.\n');
    end

end % check_directory(directory, directory_name, create_directory)

