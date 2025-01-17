function check_directory(cfg, directory)
%% CHECK_DIRECTORY
%  function check_directory(directory, directory_name, create_directory)
% 
% *DESCRIPTION*
% Checks whether a directory exists, creates it when it does not exist,
% ask user to create if specified by create_directory = false
%
% *INPUT*
% directory = <full path to a folder>
% cfg.directory_name = <any string>, helps to identify the folder, is used for
% feedback purposes only
% cfg.create_directory = true or false (default = true)
%   <true> if the directory does not exist, it is created
%   <false> if the directory does not exist, the user is asked whether to
%   create or not
%

% *OUTPUT*
% The directory is created, if specified

% check input
if ~isfield(cfg, 'directory_name')
    cfg.directory_name = directory;
end
if ~isfield(cfg, 'create_directory')
    cfg.create_directory = true;
end


% provide some feedback
fprintf('Checking %s "%s". ', cfg.directory_name, directory);

if ~exist(directory, "dir")
    % the folder does not exist, check whether we should ask or create
    if cfg.create_directory
        % create the folder
        [status, msg, msgID] = mkdir(directory); % create the folder
        fprintf('Directory created.\n');
    else
        % ask whether it should be created
        dlgtitle = [cfg.directory_name ' does not exist'];
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

end % check_directory(cfg, directory)

