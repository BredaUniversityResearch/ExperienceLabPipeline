function [project, msg] = update_participant_data(cfg, project)
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
% path to the participant data file = project.raw_data_directory
% ParticipantData.xlsx = <filename of particiapnt data> (default = 'ParticipantData.xlsx');
% Participant = <name of the column that holds the participant labels> (default = 'Participant');
% TimeFormat = <name of the column that holds the timeformat (unix or datetime)> (default = 'TimeFormat');
% Timezone   = <name of the column that holds the timezone> (default = 'TimeZone');

%
% The config struct is only a placeholder for now
% cfg = [];


%% Check the project struct
if ~isfield(project, 'raw_data_directory')
    error('The project does not have the correct format. It has no raw_data_directory field. Type help check_project_directories for info on the project struct.');
end
% === TODO: we should check the rest of the project struct too

%% Get the participant data from the excel file
path_filename = fullfile(project.raw_data_directory, 'ParticipantData.xlsx');
if ~exist(path_filename, "file")
    % the datafile is not in the specified location
    error(['The participant datafile cannot be found. ' ...
        ['This is an Excel file that contains the start and endtimes of each segment per participant. ' ...
        'Please check. I expected it here: '] path_filename]);
else
    % read the Excel file 
    try
        options = detectImportOptions(path_filename);
    catch exception
        msg = 'I was not able to open ParticipantData.xlsx. Make sure that it is in the 0.RawData folder and that it is not open in Excel.';
        return;
        
    end
end
try
    participantData_new = readtable(path_filename, options); % without these opts, readtable returns NaNs for empty columns, which cause issues on updating the ParticipantData
catch exception
    msg = 'I was not able to open ParticipantData.xlsx. Make sure that it is in the 0.RawData folder and that it is not open in Excel.';
    return;
end
clear options;
% === TODO: we should check the column names 


%% initialize

% keep track of change
data_changed = false;
% initiate return message
msg = '';


%% store pp_labels and segment_names for easy use
%  but keep these up to date when adding/removing stuff

% get the pp labels from both the project and the excel file
pp_labels_project = project.pp_labels;% get the participant labels from the project 
nof_pps_project = size(pp_labels_project, 1);% note the number of pps
pp_labels_excel   = participantData_new.Participant;% the same for the participants in the excel file
nof_pps_excel   = size(pp_labels_excel, 1);

% get the project segment names
project_segment_names = {};
for segment_i = 1:project.nof_segments
    project_segment_names(segment_i, 1) = {project.segment(segment_i).name};
end
% get the excel segment names
fields_new = fieldnames(participantData_new); % get all columns headers
fields_new_starttimes_idx = startsWith(fields_new, 'StartTime', 'IgnoreCase',true); % find the indices of headers starting with 'StartTime'
fields_new_endtimes_idx   = startsWith(fields_new, 'EndTime', 'IgnoreCase',true); % find the indices of headers starting with 'EndTime'
starttime_fieldnames      = fields_new(fields_new_starttimes_idx); % make an array of those header names
endtime_fieldnames        = fields_new(fields_new_endtimes_idx);
starttime_segmentnames    = extractAfter(starttime_fieldnames, length('StartTime')); % remove the 'StartTime' part so that the segment/condition names remain
endtime_segmentnames      = extractAfter(endtime_fieldnames, length('EndTime'));
segment_names_new         = intersect(starttime_segmentnames, endtime_segmentnames); % get the segment names that have bot a start and an end time
if isempty(segment_names_new) % no segments were found
    msg = [msg, 'The participant datafile has no (proper) start/end times columns. Please add a column containing the start and end-times of each condition in columns with header ''StartTime<name of the condition>'' and  ''EndTime<name of the condition>'' for each condition (e.g. StartTimeCondition1).'];
    return;
end



%% Participants removed

%  check whether any pps were removed
[removed_pps, removed_pp_idx] = setdiff(pp_labels_project, pp_labels_excel);

if ~isempty(removed_pp_idx)
    % some pps were removed, ask what to do with those
    dlgtitle = 'Delete participant data?';
    question = ['Participants '];
    for removed_i = 1:length(removed_pp_idx)
        if removed_i>1
        question = [question, ', '];
        end
        question = [question, removed_pps{removed_i}];
    end
    question = [question, ' are not in the participant data excel file "' path_filename '".'];
    question2 = '\nWould you like me to remove those from the project too?\n';
    options.Default = 'No';
    answer = questdlg({question, sprintf(question2)}, dlgtitle, 'Yes','No', options.Default);
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
            msg = [msg, 'Participants '];
            for removed_i = 1:length(removed_pp_idx)
                if removed_i>1
                    msg = [msg, ', '];
                end
                msg = [msg, removed_pps{removed_i}];
            end
            msg = [msg, ' have been removed from the project\n'];
            data_changed = true;
            % the number of participants in the project has changed, so update
            pp_labels_project = project.pp_labels;
            nof_pps_project = size(pp_labels_project, 1);
        case 'No' % User chose 'No' to keep the participants in the project
            % continue the update, but do send a warning to the user
            msg = [msg, 'WARNING: Participants are missing in the participant data excel file. Please check ', path_filename];
    end
end

%% Segments removed
%  check whether any segments were removed

% compare the new segment names with the existing ones
[segments_removed, segments_removed_idx] = setdiff(project_segment_names, segment_names_new);

if ~isempty(segments_removed)
    % some segments were removed
    % ask the user what to do
    dlgtitle = 'Remove segments?';
    question = ['Segments '];
    for removed_segment_i = 1:length(segments_removed)
        if removed_segment_i>1
            question = [question, ', '];
        end
        question = [question, '''', segments_removed{removed_segment_i}, ''''];
    end
    question = [question, ' are no longer in the ParticipantData excel file.\n'];
    question2 = 'Would you like me to remove those from the project?\n';
    options.Default = 'No';
    answer = questdlg({question, question2}, dlgtitle, 'Yes','No', options.Default);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to remove the segments from the project
            % add the segments from the project
            project.segment(segments_removed_idx) = [];
            % provide feedback
            msg = [msg, 'Segments '];
            for removed_segment_i = 1:length(segments_removed)
                if removed_segment_i>1
                    msg = [msg, ', '];
                end
                msg = [msg, segments_removed{removed_segment_i}];
            end
            msg = [msg, ' have been removed from the project\n'];
            data_changed = true;
            % update number of segments in project
            project_segment_names(segments_removed_idx) = [];
            project.nof_segments = size(project.segment, 2);
        case 'No' % User chose 'No' to keep the participants in the project
            % continue the update, but do send a warning to the user
            warning('WARNING: Some segments are missing from the participant data excel file but user chose to keep them in the project.');
    end

end



%% Participants added
%  check whether any pps were added

[added_pps, added_pp_idx] = setdiff(pp_labels_excel, pp_labels_project);
if ~isempty(added_pp_idx)
    % some pps were added to the excel file, ask what to do with those
    dlgtitle = 'Add participant data?';
    question = ['Participant(s) '];
    for added_i = 1:length(added_pp_idx)
        if added_i>1
        question = [question, ', '];
        end
        question = [question, added_pps{added_i}];
    end
    question = [question, ' are in the excel file but not in the project. See ', path_filename];
    question2 = '\nWould you like me to add those to the project too?\n';
    default_answer = 'No';
    answer = questdlg({question, sprintf(question2)}, dlgtitle, 'Yes','No', default_answer);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to add the participants to the project
            % add the participant data
            for added_i=1:length(added_pp_idx)
                new_pp_index = length(project.pp_labels) + 1; % the index of the new participant
                project.pp_labels(new_pp_index)  = pp_labels_excel(added_pp_idx(added_i)); % add pp_label
                project.timeformat(new_pp_index) = participantData_new.TimeFormat(added_pp_idx(added_i)); % add timeformat
                project.timezone(new_pp_index)   = participantData_new.TimeZone(added_pp_idx(added_i)); % add timezone
                for segment_i = 1:project.nof_segments % for each segment, add the bookkeeping of that pp
                    starttimes_column = ['StartTime' project.segment(segment_i).name]; % the name of the column in excel
                    endtimes_column   = ['EndTime' project.segment(segment_i).name]; % the name of the column in excel
                    project.segment(segment_i).starttime(new_pp_index) = participantData_new.(starttimes_column)(added_pp_idx(added_i));
                    project.segment(segment_i).endtime(new_pp_index)   = participantData_new.(endtimes_column)(added_pp_idx(added_i));
                    project.segment(segment_i).segmented(new_pp_index)          = 0;
                    project.segment(segment_i).artifact_corrected(new_pp_index) = 0;
                    project.segment(segment_i).deconvolved(new_pp_index)        = 0;
                    project.segment(segment_i).include(new_pp_index)            = 1;
                end
            end
            % provide feedback
            msg = [msg, 'Participants '];
            for added_i = 1:length(added_pp_idx)
                if added_i>1
                    msg = [msg, ', '];
                end
                msg = [msg, added_pps{added_i}];
            end
            msg = [msg, ' have been added to the project\n'];
            data_changed = true;
            % the number of participants in the project has changed, so update
            pp_labels_project = project.pp_labels;
            nof_pps_project = size(pp_labels_project, 1);
        case 'No' % User chose 'No' to keep the participants in the project
            % abort the program and show an error message
            msg = [msg, 'There are participants in the participant data excel file that are not in the project. Please check ', path_filename];
    end
end


%% Segments added
%  check whether any segments were added

    % compare the new segment names with the existing ones
    [segments_added, segments_added_idx]   = setdiff(segment_names_new, project_segment_names);

    if ~isempty(segments_added)
        % some segments were added
        % ask the user what to do
        dlgtitle = 'Add segments?';
        question = ['Segments '];
        for added_segment_i = 1:length(segments_added)
            if added_segment_i>1
                question = [question, ', '];
            end
            question = [question, '''', segments_added{added_segment_i}, ''''];
        end
        question = [question, ' are in the ParticipantData excel file but not in the project.'];
        question2 = 'Would you like me to add those to the project?';
        options.Default = 'No';
        answer = questdlg({question, question2}, dlgtitle, 'Yes','No', options.Default);
        % Handle response
        switch answer
            case 'Yes' % User chose 'Yes' to remove the segments from the project
                % add the participant data
                for added_segment_i = 1:length(segments_added)
                    project.segment(project.nof_segments + 1).name      = segments_added{added_segment_i};
                    for pp_i = 1:length(project.pp_labels) % for each pp, add the start/endtimes of the new segment
                        segment_i = project.nof_segments + 1;
                        % Since participants may have been added or removed, we cannot rely on the indices
                        excel_pp_index = find(strcmp(participantData_new.Participant, project.pp_labels(pp_i)));
                        project.segment(segment_i).starttime(pp_i, 1) = participantData_new.(['StartTime', segments_added{added_segment_i}])(excel_pp_index);
                        project.segment(segment_i).endtime(pp_i, 1)   = participantData_new.(['EndTime', segments_added{added_segment_i}])(excel_pp_index);
                        project.segment(segment_i).segmented(pp_i, 1)          = 0;
                        project.segment(segment_i).artifact_corrected(pp_i, 1) = 0;
                        project.segment(segment_i).deconvolved(pp_i, 1)        = 0;
                        project.segment(segment_i).include(pp_i, 1)            = 1;
                    end
                end
                
                % provide feedback
                msg = [msg, 'Segments '];
                for added_segment_i = 1:length(segments_added)
                    if added_segment_i>1
                        msg = [msg, ', '];
                    end
                    msg = [msg, segments_added{added_segment_i}];
                end
                msg = [msg, ' have been added to the project.'];
                data_changed = true;
                % update number of segments in project
                project.nof_segments = size(project.segment, 2);
            case 'No' % User chose 'No' to keep the participants in the project
                % abort the program and show an error message
                msg = [msg, 'WARNING: Some segments in the participant data excel file are not in the project. Please check ', path_filename];
        end

    end


%% Start and end times
%  Check for differences start and end times
% the number of participants in the project may have changed
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
            starttimes_column = ['StartTime' project.segment(segment_i).name]; % the name of the column in excel
            endtimes_column   = ['EndTime' project.segment(segment_i).name]; % the name of the column in excel
            starttime_project = project.segment(segment_i).starttime{pp_i}; % note (4 July 2025) changed (pp_i) to {pp_i} for the ArtExp project, having a deja vu. If this causes issues again, investigate further
            starttime_excel   = participantData_new.(starttimes_column)(pp_i_excel);
            endtime_project   = project.segment(segment_i).endtime{pp_i};
            endtime_excel   = participantData_new.(endtimes_column)(pp_i_excel);
            if ~(strcmp(starttime_project, starttime_excel) && strcmp(endtime_project, endtime_excel))
                changed_i = changed_i + 1;
                % the times, they are a-changin'
                changed_pp(changed_i).pp_i            = pp_i;
                changed_pp(changed_i).segment_i       = segment_i;
                changed_pp(changed_i).starttime_excel = starttime_excel;
                changed_pp(changed_i).endtime_excel   = endtime_excel;
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
    options.Default = 'No';
    answer = questdlg({question0, sprintf(question)}, dlgtitle, 'Yes','No', options.Default);
    % Handle response
    switch answer
        case 'Yes' % User chose 'Yes' to update the start/end times of the project
            for changed_i = 1:size(changed_pp, 2) % for each changed times, remove the bookkeeping of that pp
                segment_i = changed_pp(changed_i).segment_i;
                pp_i      = changed_pp(changed_i).pp_i;
                project.segment(segment_i).starttime(pp_i) = changed_pp(changed_i).starttime_excel;
                project.segment(segment_i).endtime(pp_i)   = changed_pp(changed_i).endtime_excel;
                project.segment(segment_i).segmented(pp_i)          = false;
                project.segment(segment_i).artifact_corrected(pp_i) = false;
                project.segment(segment_i).deconvolved(pp_i)        = false;
            end
            % provide feedback
            msg = [msg, 'Start and endtimes have been updated to the values in the excel file ', path_filename, ' for'];
            segment_i = 0;
            segment_count = 0;
            for changed_i = 1:size(changed_pp, 2)
                if changed_pp(changed_i).segment_i > segment_i
                    pp_count = 0;
                    if segment_count > 0
                        msg = [msg, '),'];
                    end
                    segment_count = segment_count + 1;
                    segment_i = changed_pp(changed_i).segment_i;
                    msg = [msg, ' segment ', project.segment(segment_i).name, ' ('];
                end
                if pp_count == 0
                    msg = [msg, project.pp_labels{changed_pp(changed_i).pp_i}];
                elseif pp_count < 5
                    msg = [msg, ', ', project.pp_labels{changed_pp(changed_i).pp_i}];
                elseif pp_count == 5
                    msg = [msg, ', ...'];
                end
                pp_count = pp_count + 1;
            end
            msg = [msg, ')'];
            data_changed = true;
        case 'No' % User chose 'No' to keep the participants in the project
            % continue the program but send a warning
            msg = [msg, 'WARNING: Start/end times have been changed in the participant data excel file. Please check ' path_filename];
    end
end

if ~data_changed
    msg = [msg, 'no changes were made to the participant data.\n'];
end


end % update_participant_data