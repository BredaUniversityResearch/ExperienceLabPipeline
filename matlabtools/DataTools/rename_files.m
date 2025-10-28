function rename_files(cfg)
% RENAME_FILES scans the particiapnt data folders for data files of a specific format 
% creates a copy, and renames that to the povided name (e.g. physiodata.csv or strava.tcx'
%
% Use as
%   rename_files(cfg)
%
% The following configuration options are supported:
%   cfg.project_folder        = the full path to the folder that contains 0.RawData 
%   cfg.file_prefix           = string that the target file should start with 
%   cfg.file_postfix          = string that the target file should end with 
%   cfg.file_newname          = string, the target will be copied and renamed to this string (e.g. 'physiodata.csv' or 'strava.tcx')
%   cfg.participant_numbers   = [lowest highest], {'P001', P002', etc}, 'all' (default = 'all') 
%
% Output:
%   copy of the target files, renamed as the provided string. Original files
%   are unchanged.
%   A log file of this operation is stored in Logs folder in the project folder
%
% Created by Hans Revers, 30 jan 2025
% updated on 19 June 2025


%% VARIABLE CHECK

%  If not specified, set the defaults
if ~isfield(cfg, 'project_folder')
    error('No project folder was provided.');
end
if ~isfield(cfg, 'file_prefix')
    cfg.file_prefix = '';
end
if ~isfield(cfg, 'file_postfix')
    cfg.shimmerfile_postfix = '';
end
if ~isfield(cfg, 'file_newname')
    error('You forgot to provide a new filename. please specify cfg.file_newname.');
end
if ~isfield(cfg, 'participant_numbers')
    cfg.participant_numbers = 'all';
else
    if ischar(cfg.participant_numbers) 
        if ~strcmp(cfg.participant_numbers, 'all')
            % error participant numbers 
            error('Could not understand cfg.participant_numbers = %s, please check.', cfg.participant_numbers);
        end
    elseif iscell(cfg.participant_numbers)
        % TODO: should we check the format? Or leave that to the user?
        % We use 'P001', but should we restrict it?
    elseif ~(size(cfg.participant_numbers, 2) == 2 && ...
            isnumeric(cfg.participant_numbers(1)) && ...
            isnumeric(cfg.participant_numbers(2)) && ...
            (cfg.participant_numbers(2) > cfg.participant_numbers(1)))
            error('Could not understand cfg.participant_numbers. Use [lowest highest], where lowest and highest are integers.');
    end
end

% start a log file
log = [];

% retrieve participant numbers
if ischar(cfg.participant_numbers) && strcmp(cfg.participant_numbers, 'all')
    % read all participant numbers 
    raw_data_folder = fullfile(cfg.project_folder, '0.RawData');
    participant_labels = dir(raw_data_folder);
    participant_labels = {participant_labels(3:end).name}; % remove the '.' and '..', keep only the filenames
elseif iscell(cfg.participant_numbers)
    participant_labels = cfg.participant_numbers;
else
    % turn the lowest/highest participant numbers into an array
    unformatted_participant_labels = cfg.participant_numbers(1):cfg.participant_numbers(2);
    % then format them into participant labels, e.g. P001
    participant_labels = formatParticipantlist(unformatted_participant_labels);
end




% read raw Shimmer data
% The Sabina forts participants have numbers ranging from 101 tot 181. 
% Not all numbers are used, so check existence.

for pp_i = 1:size(participant_labels, 2)
    % get the folder of this participant, e.g. 0.RawData\P001
    pp_label = participant_labels{pp_i};
    pp_folder = fullfile(cfg.project_folder, '0.RawData', pp_label);
    % check whether the folder exists
    if not(isfolder(pp_folder))
        % there is no folder for this participant, move on to the next
        msg = sprintf('Data folder not found for participant %s.\n',pp_label);
        fprintf(msg);
        log = [log, msg];
        continue;
    end
    % Make a list of all files in the participant folder
    listing = dir(pp_folder);
    if size(listing, 1) < 3
        % The folder is empty. The first 2 listings are not files ('.' and '..')
        % Move to the next participant
        msg = sprintf('Data folder is empty for participant %s.\n',pp_label);
        fprintf(msg);
        log = [log, msg];
        continue;
    end
    % Detect the files that might target files
    listing_files = []; % keep notes
    goto_next_pp = false; % if a properly named Shimmer files is present, we want to skip the rest
    expression_start = cfg.file_prefix; % file names that start with this
    expression_end   = cfg.file_postfix; % file names that end with this
    for file_i = 3:size(listing, 1) % skip the first 2 ('.' and '..')
        if strcmp(listing(file_i).name, cfg.file_newname)
            % file with correct name is already present. Nothing to do here.
            % Continue with the next participant
            msg = sprintf('A properly named file was already present for participant %s.\n',pp_label);
            fprintf(msg);
            log = [log, msg];
            goto_next_pp = true;
            break;
        else
            % check the name for known parts
            isTargetfile = and(startsWith(listing(file_i).name, expression_start), endsWith(listing(file_i).name, expression_end));
            if isTargetfile
                listing_files = [listing_files, file_i];
            end
        end
    end
    if goto_next_pp
        % A file with the new name was already present, so skip to the next participant
        continue;
    end
        
    if isempty(listing_files) % found no Shimmer files
        msg = sprintf('No file that matches your pre/postfix was found in the data folder of participant %s.\n',pp_label);
        warning('off','backtrace')
        warning(msg);
        warning('on','backtrace')
        log = [log, 'WARNING: ', msg];
    else % one or more possible Shimmer files
        if size(listing_files, 2) > 1 % found multiple possible Shimmer files
            msg = sprintf('Multiple files match your pre/postfix for participant %s. Please check manually!!!\n', pp_label);
            warning('off','backtrace')
            warning(msg)
            warning('on','backtrace')
            log = [log, 'WARNING: ', msg];
        else % found exactly one possisble Shimmer file
            % create a copy and rename
            original_file = fullfile(pp_folder, listing(listing_files).name);
            copy_and_rename_file = fullfile(pp_folder, cfg.file_newname);
            copyfile(original_file, copy_and_rename_file);
            msg = sprintf('A copy of a the target file was created as ''%s'' for participant %s.\n', cfg.file_newname, pp_label);
            fprintf(msg);
            log = [log, msg];
        end
        
    end
end

% save the log file
t = datetime('now','Format','d-MMM-y_(HH-mm-ss)'); % current date and time
log_filename = fullfile(cfg.project_folder, 'Logs', ['rename_files_log_', char(t) , '.txt']);
[status, msg] = mkdir(fullfile(cfg.project_folder, 'Logs')); % create the Logs directory if needed
file_ID = fopen(log_filename, "wt");
fwrite(file_ID, log, "char");
fclose(file_ID);

end % function rename_files(cfg)


%% helper functions

    function [formattedParticipantlist] = formatParticipantlist(unformattedParticipantlist)

        nof_pps = size(unformattedParticipantlist, 2);
        formatSpec = 'P%03s';

        formattedParticipantlist=cell(1, nof_pps);
        formattedParticipantlistrlist{1, nof_pps} = [];
        for pp_id = 1:nof_pps
            formattedParticipantlist{1, pp_id} = sprintf(formatSpec, num2str(unformattedParticipantlist(pp_id)));
        end
    end
