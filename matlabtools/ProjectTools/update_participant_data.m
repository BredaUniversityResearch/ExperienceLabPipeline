function project = update_participant_data(cfg, project)
%% UPDATE_PARTICIPANT_DATA
%  function project = get_participant_data(cfg, project)
% 
% *DESCRIPTION*
%   compares the participant data to the project struct and if there are
%   diffrences, it ask the user how to handle these
%   1)  participants are added, i.e. the participant data file has participant 
%       labels that are not in the project:
%       = Ask whether to add these to the project
%   2)  participants are removed, i.e. the project has participant labels 
%       that are not in the participant data file:
%       = Ask whether to remove these to the project
%   3)  start/end times have changed, i.e. for a participant the start 
%       and/or endtimes of a segment in the participant data file are 
%       different from those in the project:
%       = Ask whether to update the times in the project
%         Note that if times change, the bookkeeping of that participant of
%         that segment will be set to false for segmentation, artifact
%         correction, and deconvolution
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
    participantData_new = readtable(path_filename);
end

%% Add the relevant participant data to the project struct

% === TODO: we should check whether these column names exist before using
%           them. And provide clear feedback. ===


% keep track of change
data_changed = false;

% Participant labels
% check whether there are changes in the participant labels
pp_labels_project = project.pp_labels;% get the participant labels from the project 
nof_pps_project = size(pp_labels_project, 1);% note the number of pps
pp_labels_excel   = participantData_new.(cfg.participants);% the same for the participants in the excel file
nof_pps_excel   = size(pp_labels_excel, 1);


% 1) First see if any pps were removed
% for all participant labels, check whether they are also in the excel file 
removed_pp_idx = []; % store the indices of the removed pps
for pp_i = 1:nof_pps_project
    pp_label = pp_labels_project(pp_i);
    idx = find(strcmp(pp_label, pp_labels_excel), 1);
    if isempty(idx)
        % this pp_label was not in the excel file, add its index to the list
        removed_pp_idx = [removed_pp_idx, pp_i];
    end
end
if ~isempty(removed_pp_idx)
    % some pps were removed, ask what to do with those
    dlgtitle = 'Delete participant data?';
    question = ['Participants '];
    for removed_i = 1:length(removed_pp_idx)
        if removed_i>1
        question = [question, ', '];
        end
        question = [question, pp_labels_project{removed_pp_idx(removed_i)}];
    end
    question = [question, ' are not in the participant data excel file "' path_filename '".'];
    question2 = '\nWould you like me to remove those from the project too?\n';
    opts.Default = 'No';
    answer = questdlg({question, sprintf(question2)}, dlgtitle, 'Yes','No', opts.Default);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to remove the participants from the project
            % remove the participant data
            project.pp_labels(removed_pp_idx)  = []; % remove pp_labels
            project.timeformat(removed_pp_idx) = []; % remove timeformat
            project.timezone(removed_pp_idx)   = []; % remove timezone
            for segment_i = 1:project.nof_segments % for each segment, remove the bookkeeping of that pp
                project.segment(segment_i).starttime(removed_pp_idx)          = [];
                project.segment(segment_i).endtime(removed_pp_idx)            = [];
                project.segment(segment_i).segmented(removed_pp_idx)          = [];
                project.segment(segment_i).artifact_corrected(removed_pp_idx) = [];
                project.segment(segment_i).deconvolved(removed_pp_idx)        = [];
                project.segment(segment_i).include(removed_pp_idx)            = [];
            end
            % provide feedback
            fprintf('Participants ');
            for removed_i = 1:length(removed_pp_idx)
                if removed_i>1
                    fprintf(', ');
                end
                fprintf(pp_labels_project{removed_pp_idx(removed_i)});
            end
            fprintf(' have been removed from the project\n');
            data_changed = true;
        case 'No' % User chose 'No' to keep the participants in the project
            % abort the program and show an error message
            warning(['Participants are missing in the participant data excel file  "', path_filename, '". Please check the excel file.']);
    end
end



% 2) Then see if any pps were added
% for all participant labels in the excel file, check whether they are also in the project 
% the numerb of participants in the project may have changed
pp_labels_project = project.pp_labels;
nof_pps_project = size(pp_labels_project, 1);

added_pp_idx = []; % store the indices of the added pps
for pp_i = 1:nof_pps_excel
    pp_label = pp_labels_excel(pp_i);
    idx = find(strcmp(pp_label, pp_labels_project), 1);
    if isempty(idx)
        % this pp_label was not in the excel file, add its index to the list
        added_pp_idx = [added_pp_idx, pp_i];
    end
end
if ~isempty(added_pp_idx)
    % some pps were added to the excel file, ask what to do with those
    dlgtitle = 'Add participant data?';
    question = ['The participant data excel file "' path_filename '" has participants that are not in the project: '];
    for added_i = 1:length(added_pp_idx)
        if added_i>1
        question = [question, ', '];
        end
        question = [question, pp_labels_excel{added_pp_idx(added_i)}];
    end
    question2 = '\nWould you like me to add those to the project too?\n';
    opts.Default = 'No';
    answer = questdlg({question, sprintf(question2)}, dlgtitle, 'Yes','No', opts.Default);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to add the participants to the project
            % add the participant data
            for added_i=1:length(added_pp_idx)
                new_pp_index = length(project.pp_labels) + 1; % the index of the new participant
                project.pp_labels(new_pp_index)  = pp_labels_excel(added_pp_idx(added_i)); % add pp_label
                project.timeformat(new_pp_index) = participantData_new.(cfg.timeformat)(added_pp_idx(added_i)); % add timeformat
                project.timezone(new_pp_index)   = participantData_new.(cfg.timezone)(added_pp_idx(added_i)); % add timezone
                for segment_i = 1:project.nof_segments % for each segment, add the bookkeeping of that pp
                    starttimes_column = cfg.segment(segment_i).starttimes; % the name of the column in excel
                    endtimes_column   = cfg.segment(segment_i).endtimes; % the name of the column in excel
                    project.segment(segment_i).starttime(new_pp_index) = participantData_new.(starttimes_column)(added_pp_idx(added_i));
                    project.segment(segment_i).endtime(new_pp_index)   = participantData_new.(endtimes_column)(added_pp_idx(added_i));
                    project.segment(segment_i).segmented(new_pp_index)          = 0;
                    project.segment(segment_i).artifact_corrected(new_pp_index) = 0;
                    project.segment(segment_i).deconvolved(new_pp_index)        = 0;
                    project.segment(segment_i).include(new_pp_index)            = 1;
                end
            end
            % provide feedback
            fprintf('Participants ');
            for added_i = 1:length(added_pp_idx)
                if added_i>1
                    fprintf(', ');
                end
                fprintf(pp_labels_excel{added_pp_idx(added_i)});
            end
            fprintf(' have been added to the project\n');
            data_changed = true;
        case 'No' % User chose 'No' to keep the participants in the project
            % abort the program and show an error message
            warning(['There are participants in the participant data excel file  "' path_filename '" that are not in the project. Please check the excel file.']);
    end
end




% 3) Check differences in start and end times
% for all participant labels in the project, find the label in the excel file 
% and compare start and end times
% the numerb of participants in the project may have changed
pp_labels_project = project.pp_labels;
nof_pps_project = size(pp_labels_project, 1);

changed_pp = []; % store the indices of the pps with changes start/end times
changed_i = 0;
for segment_i = 1:project.nof_segments
    for pp_i = 1:nof_pps_project
        % get the label in the project bookkeeping
        pp_label = pp_labels_project(pp_i);
        % find that same label in the participant data excel file
        pp_i_excel = find(strcmp(pp_label, pp_labels_excel), 1);
        % if a corresponding pp label was found
        if ~isempty(pp_i_excel)
            % check the start/end times for each segment
            starttimes_column = cfg.segment(segment_i).starttimes; % the name of the column in excel
            endtimes_column = cfg.segment(segment_i).endtimes; % the name of the column in excel
            starttime_project = project.segment(segment_i).starttime(pp_i);
            starttime_excel = participantData_new.(starttimes_column)(pp_i_excel);
            endtime_project = project.segment(segment_i).endtime(pp_i);
            endtime_excel = participantData_new.(endtimes_column)(pp_i_excel);
            if ~(strcmp(starttime_project, starttime_excel) && strcmp(endtime_project, endtime_excel))
                changed_i = changed_i + 1;
                % the times, they are a-changin'
                changed_pp(changed_i).pp_i = pp_i;
                changed_pp(changed_i).segment_i = segment_i;
                changed_pp(changed_i).starttime_excel = starttime_excel;
                changed_pp(changed_i).endtime_excel = endtime_excel;
            end
        end
    end
end
if ~isempty(changed_pp)
    % times of some pps were changed, ask what to do with those
    dlgtitle = 'Update start/end times?';
    question0 = ['Some start/end times in the excel file "' path_filename '" are different from those in the project. '];
    question = [];
    segment_i = 0;
    for changed_i = 1:size(changed_pp, 2)
        if changed_pp(changed_i).segment_i > segment_i
            pp_count = 0;
            segment_i = changed_pp(changed_i).segment_i;
            question = [question, '\nSegment ', project.segment(segment_i).name, ': '];
        end
        if pp_count == 0
            question = [question, project.pp_labels{changed_pp(changed_i).pp_i}];
        elseif pp_count < 5
            question = [question, ', ', project.pp_labels{changed_pp(changed_i).pp_i}];
        elseif pp_count == 5
            question = [question, ', ...'];
        end
        pp_count = pp_count + 1;
    end
    question = [question, '\n\nWould you like me to update the start/end times for these participants?'];
    opts.Default = 'No';
    answer = questdlg({question0, sprintf(question)}, dlgtitle, 'Yes','No', opts.Default);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to update the start/end times of the project
            for changed_i = 1:size(changed_pp, 2) % for each changed times, remove the bookkeeping of that pp
                segment_i = changed_pp(changed_i).segment_i;
                pp_i      = changed_pp(changed_i).pp_i;
                project.segment(segment_i).starttime(pp_i) = changed_pp(changed_i).starttime_excel;
                project.segment(segment_i).endtime(pp_i)   = changed_pp(changed_i).endtime_excel;
            end
            % provide feedback
            fprintf('Start and endtimes have been updated to the values in the excel file  "%s" for:', path_filename);
            segment_i = 0;
            for changed_i = 1:size(changed_pp, 2)
                if changed_pp(changed_i).segment_i > segment_i
                    pp_count = 0;
                    segment_i = changed_pp(changed_i).segment_i;
                    fprintf('\nSegment %s: ', project.segment(segment_i).name);
                end
                if pp_count == 0
                    fprintf(project.pp_labels{changed_pp(changed_i).pp_i});
                elseif pp_count < 5
                    fprintf(', %s', project.pp_labels{changed_pp(changed_i).pp_i});
                elseif pp_count == 5
                    fprintf(', ...');
                end
                pp_count = pp_count + 1;
            end
            data_changed = true;
        case 'No' % User chose 'No' to keep the participants in the project
            % abort the program and show an error message
            warning(['Start/end times have been changed in the participant data excel file  "' path_filename '". Please check the excel file.']);
    end
end

if ~data_changed
    fprintf('No changes found\n');
end



% === TODO :: we should also check the number and names of the segments ===


end % update_participant_data