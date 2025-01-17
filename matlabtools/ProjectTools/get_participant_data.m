function participantData = get_participant_data(path_filename)
%% GET_PARTICIPANT_DATA
%  function participantData = get_participant_data(cfg, path_filename)
% 
% *DESCRIPTION*
%   reads the participant data excel file that is specified in the path_filename
%   and returns it as a table
%
% *INPUT*
% A path_filename that points to the participant data file
%
% *Example*
%    participant_data_file = fullfile(project.raw_data_directory, 'Participant1Data.xlsx');
%    participantData = get_participant_data(participant_data_file);
%

%% Get the participant data from
% the excel file that holds starttime and duration per pp
 
% participant Datafile
if ~exist(path_filename, "file")
    % the datafile is not in the specified location
    error(['The participant datafile cannot be found. ' ...
        ['This is an Excel file that contains the starttime and duration per participant. ' ...
        'Please check. I expected it here: '] path_filename]);
else
    % read the Excel file 
    participantData = readtable( path_filename );
end

end % get_participant_data