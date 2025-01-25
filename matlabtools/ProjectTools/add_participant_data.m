function project = add_participant_data(cfg, project)
%% ADD_PARTICIPANT_DATA
%  function project = get_participant_data(cfg, project)
% 
% *DESCRIPTION*
%   adds the participant data to the project struct
%
% *INPUT*
% A project struct containing the name and path of the project and data
% A config struct indicating where to find the participant data file
% and which columns of that file contain relevant dat
%
% cfg.participant_data_dir = <path to the participant data file> (default = project.raw_data_directory);
% cfg.participant_data_filename = <filename of particiapnt data> (default = 'ParticipantData.xlsx');
% cfg.participants = <name of the column that holds the participant labels> (default = 'Participant');
% cfg.timeformat = <name of the column that holds the timeformat (unix or datetime)> (default = 'TimeFormat');
% cfg.timezone   = <name of the column that holds the timezone> (default = 'TimeZone');
% cfg.segment_names      = {'Segment1_Name', 'Segment2_name', ...}; a name for each segment (default = {'Segment1'})
% cfg.number_of_segments = integer value (default = the length of cfg.segment_names);
% cfg.segment(1).starttimes = <name of the column that holds the start times of segment 1> (default = [StartTime cfg.segment_names(1)]);
% cfg.segment(1).endtimes   = <name of the column that holds the end times of segment 1> (default = [EndTime cfg.segment_names(1)]);
% cfg.segment(2).starttimes = ... ;
% cfg.segment(2).endtimes   = ... ;

%
% *Example*
% cfg = [];
% cfg.participant_data_dir = project.raw_data_directory;
% cfg.participant_data_filename = 'ParticipantData.xlsx';
% cfg.participants = 'Participant';
% cfg.timeformat = 'TimeFormat';
% cfg.timezone   = 'TimeZone';
% cfg.number_of_segments = 3;
% cfg.segment_names      = {'AR', 'FirstHalf', 'SecondHalf'};
% cfg.segment(1).starttimes = 'StartTimeAR';
% cfg.segment(1).endtimes   = 'EndTimeAR';
% cfg.segment(2).starttimes = 'StartTimeFirstHalf';
% cfg.segment(2).endtimes   = 'EndTimeFirstHalf';
% cfg.segment(3).starttimes = 'StartTimeSecondHalf';
% cfg.segment(3).endtimes   = 'EndTimeSecondHalf';
%


%% Check input
% project
if ~isfield(project, 'raw_data_directory')
    error('The project does not have the correct format. For instance, it has no raw_data_directory field. Type help check_project_directories for info on the project struct.');
end


%% Get the participant data from the excel file
 
% path to participant data file
if ~isfield(cfg, 'participant_data_dir')
    cfg.participant_data_dir = project.raw_data_directory;
end
% participant data filename
if ~isfield(cfg, 'participant_data_filename')
    cfg.participant_data_filename = 'ParticipantData.xlsx';
end
% participant Datafile
path_filename = fullfile(cfg.participant_data_dir, cfg.participant_data_filename);
if ~exist(path_filename, "file")
    % the datafile is not in the specified location
    error(['The participant datafile cannot be found. ' ...
        ['This is an Excel file that contains the starttime and duration per participant. ' ...
        'Please check. I expected it here: '] path_filename]);
else
    % read the Excel file 
    opts = detectImportOptions(path_filename);
    participantData = readtable(path_filename, opts); % without these opts, readtable returns NaNs for empty columns, which cause issues on updating the ParticipantData
end


%% Add the relevant participant data to the project struct

% check whether column names are provide, use defaults if not
% column name of the participant labels
if ~isfield(cfg, 'participants')
    cfg.participants = 'Participant';
end
% column name of the timeformat
if ~isfield(cfg, 'timeformat')
    cfg.timeformat = 'TimeFormat';
end
% column name of the timezone
if ~isfield(cfg, 'timezone')
    cfg.timezone = 'TimeZone';
end

%  check whether these column names exist before using them
if ~any(cfg.participants == string(participantData.Properties.VariableNames))
    error('The participant datafile does not have a participants column ''%s'', please check ''%s''.', cfg.participants, path_filename);
end
if ~any(cfg.timeformat == string(participantData.Properties.VariableNames))
    error('The participant datafile does not have a timeformat column ''%s'', please check ''%s''.', cfg.timeformat, path_filename);
end
if ~any(cfg.timezone == string(participantData.Properties.VariableNames))
    error('The participant datafile does not have a timezone column ''%s'', please check ''%s''.', cfg.timezone, path_filename);
end

% Participant labels
project.pp_labels = participantData.(cfg.participants);
% time properties
project.timeformat  = participantData.(cfg.timeformat);
project.timezone    = participantData.(cfg.timezone);


%% Add the segment data (the conditions)

% array of segment names
if ~isfield(cfg, 'segment_names') % segment names have not been provided
    % let's extract them from the columns in the participant data
    
    fields = fieldnames(participantData); % get all columns headers
    field_starttimes_idx = startsWith(fields, 'StartTime', 'IgnoreCase',true); % find the indices of headers starting with 'StartTime'
    field_endtimes_idx = startsWith(fields, 'EndTime', 'IgnoreCase',true); % find the indices of headers starting with 'EndTime'
    if sum(field_starttimes_idx) == 0 || sum(field_endtimes_idx) == 0 % no start or no end times were found
        % TODO: perhaps we should use the whole segment if no start/end
        % times are provided. For now, trigger an error.
        error('The participant datafile has no start or end times. Please add a column containing the start and end-times of each condition in columns with header ''StartTime<name of the condition>'' and  ''EndTime<name of the condition>'' for each condition (e.g. StartTimeCondition1).');
    end
    starttime_fieldnames = fields(field_starttimes_idx); % make an array of those header names
    endtime_fieldnames = fields(field_endtimes_idx);
    starttime_segmentnames = extractAfter(starttime_fieldnames, length('StartTime')); % remove the 'StartTime' part so that the segment/condition names remain
    endtime_segmentnames = extractAfter(endtime_fieldnames, length('EndTime'));
    cfg.segment_names = intersect(starttime_segmentnames, endtime_segmentnames); % get the segment names that have bot a start and an end time
end

% get the number of segments
project.nof_segments = length(cfg.segment_names);

% names of the columns that hold the start and end times of each segment
for segment_i = 1:project.nof_segments
    if ~isfield(cfg, ['segment(' num2str(segment_i) ')'])
        cfg.segment(segment_i).starttimes = ['StartTime' cfg.segment_names{segment_i}];
    else    
        if ~isfield(cfg.segment(segment_i), 'starttimes')
            cfg.segment(segment_i).starttimes = ['StartTime' cfg.segment_names{segment_i}];
        end
    end
    if ( ~isfield(cfg.segment(segment_i), 'endtimes') || isempty(cfg.segment(segment_i).endtimes) )
        cfg.segment(segment_i).endtimes = ['EndTime' cfg.segment_names{segment_i}];
    end
end



% segment names, start and end times
for segment_i = 1:project.nof_segments
    project.segment(segment_i).name     = cfg.segment_names{segment_i};       % name of this segment
    project.segment(segment_i).starttime = participantData.(cfg.segment(segment_i).starttimes); % start times of this segment
    project.segment(segment_i).endtime   = participantData.(cfg.segment(segment_i).endtimes);   % end times of this segment
end

end % add_participant_data