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
% path to participant data file
if ~isfield(cfg, 'participant_data_dir')
    cfg.participant_data_dir = project.raw_data_directory;
end
% participant data filename
if ~isfield(cfg, 'participant_data_filename')
    cfg.participant_data_filename = 'ParticipantData.xlsx';
end
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
% array of segment names
if ~isfield(cfg, 'segment_names')
    cfg.segment_names = {'Segment1'};
end
% the number of segments
if ~isfield(cfg, 'number_of_segments')
    cfg.number_of_segments = length(cfg.segment_names);
end
% names of the columns that hold the start and end times of each segment
for segment_i = 1:cfg.number_of_segments
    if ~isfield(cfg, ['segment(' segment_i ')'])
        cfg.segment(segment_i).starttimes = ['StartTime' cell2mat(cfg.segment_names(segment_i))];
    else    
        if ~isfield(cfg.segment(segment_i), 'starttimes')
            cfg.segment(segment_i).starttimes = ['StartTime' cell2mat(cfg.segment_names(segment_i))];
        end
    end
    if ( ~isfield(cfg.segment(segment_i), 'endtimes') || isempty(cfg.segment(segment_i).endtimes) )
        cfg.segment(segment_i).endtimes = ['EndTime' cell2mat(cfg.segment_names(segment_i))];
    end
end

%% Get the participant data from the excel file
 
% participant Datafile
path_filename = fullfile(cfg.participant_data_dir, cfg.participant_data_filename);
if ~exist(path_filename, "file")
    % the datafile is not in the specified location
    error(['The participant datafile cannot be found. ' ...
        ['This is an Excel file that contains the starttime and duration per participant. ' ...
        'Please check. I expected it here: '] path_filename]);
else
    % read the Excel file 
    participantData = readtable(path_filename);
end

%% Add the relevant participant data to the project struct

% === TODO: we should check whether these column names exist before using
%           them. And provide clear feedback. ===

% Participant labels
% pp_nrs = [1:5];
project.pp_labels = participantData.(cfg.participants);
% time properties
project.timeformat  = participantData.(cfg.timeformat);
project.timezone    = participantData.(cfg.timezone);

% data segments
project.nof_segments = cfg.number_of_segments; % the number of data segments to analyze per participant

% segment names, start and end times
for segment_i = 1:project.nof_segments
    project.segment(segment_i).name     = cfg.segment_names{segment_i};       % name of this segment
    project.segment(segment_i).starttime = participantData.(cfg.segment(segment_i).starttimes); % start times of this segment
    project.segment(segment_i).endtime   = participantData.(cfg.segment(segment_i).endtimes);   % end times of this segment
end

end % add_participant_data