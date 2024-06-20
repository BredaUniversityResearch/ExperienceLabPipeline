function project = update_project_bookkeeping(cfg, project)
%% UPDATE_PROJECT_BOOKKEEPING
%  function update_project_bookkeeping(project)
% 
% *DESCRIPTION*
%   Updates the project bookkeeping:
%   Sets one of the processing steps to true (completed) or false (not
%   completed), for the specified participant, for the specified segment
%
% *INPUT*
%   a project struct with (among others) the fields:
%       project.project_name
%       project.project_directory
%       project.participant_labels
%       project.nof_segments
%       project.segment(cfg.segment_nr).segmented
%       project.segment(cfg.segment_nr).artifact_corrected
%       project.segment(cfg.segment_nr).deconvolved
%   a config struct with fields
%       cfg.processing_part = 'segmented' or 'artifact_corrected' or 'deconvolved'
%       cfg.pp_label = pp_label
%       cfg.segment_nr = segment_nr
%       cfg.processing_complete = true or false
%
% *OUTPUT*
%   The updated project struct is returned
%   The update is written to the bookkeeping file <project_name>.belt
%   and saved at <project_directory>
%

%% Check input
%
if ~isfield(project, 'project_name')
    error('The project struct has no project_name field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'project_directory')
    error('The project struct has no project_directory field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'nof_segments')
    error('The project struct is incomplete. It has no nof_segments field.');
end
if ~isfield(project, 'pp_labels')
    error('The project struct is incomplete. It has no pp_labels field.');
end
if ~isfield(project, 'segment')
    error('The project struct is incomplete. It has no segment field.');
end
if length(project.segment) < project.nof_segments
    error('The project struct is incomplete. There are fewer segments than indicated by project.nof_segments.');
end

if ~isfield(cfg, 'processing_part')
    error('The cfg struct is incomplete. It has no processing_part field.');
end
if ~isfield(cfg, 'pp_label')
    error('The cfg struct is incomplete. It has no pp_label field.');
end
if ~isfield(cfg, 'segment_nr')
    error('The cfg struct is incomplete. It has no segment_nr field.');
end
if ~isfield(cfg, 'processing_complete')
    error('The cfg struct is incomplete. It has no processing_complete field.');
end

if cfg.segment_nr > project.nof_segments
    error('The cfg.segment_nr is higher then the number of segments in the project.');
end


%% update the bookkeeping of the project

% find the row index for the participant label
pp_i_array = strcmp(project.pp_labels, cfg.pp_label); % creates a logical array. Apparently this is faster then using find().

project.segment(cfg.segment_nr).(cfg.processing_part)(pp_i_array) = cfg.processing_complete;

%% Create a text file
%  the tab (\t) is a separator, it moves the cursor to the next cell
%  the newline character (\n) moves the cursor to the next line/row

% note how many variables are stored for each condition
nof_vars_per_segment =  length(fieldnames(project.segment(1)));

% open the file
file_dir = fullfile(project.project_directory, [project.project_name '.belt']);
[fileID, errmsg] = fopen(file_dir,'w');

% check for errors related to opening the file
if ~isempty(errmsg)
    error(errmsg);
end

% Write some information about this bookkeeping file on the first line
fprintf(fileID,'This is a BELT project file. Settings and status of a project are stored here. This file is maintained automatically by the BELT app.\n');

% Make a list of the project properties (project name and data directories)
fprintf(fileID,'Project_name\t');
fprintf(fileID,'%s\n',project.project_name); 

fprintf(fileID,'Project_directory\t');
fprintf(fileID,'%s\n',project.project_directory); 

fprintf(fileID,'Raw_data_directory\t');
fprintf(fileID,'%s\n',project.raw_data_directory); 

fprintf(fileID,'Processed_data_directory\t');
fprintf(fileID,'%s\n',project.processed_data_directory); 

fprintf(fileID,'Output_directory\t');
fprintf(fileID,'%s\n',project.output_directory); 

fprintf(fileID,'Number_of_segments\t');
fprintf(fileID,'%i\n',project.nof_segments); 

fprintf(fileID,'Segment_names\t');
for segment_i = 1:project.nof_segments
    fprintf(fileID,'%s\t',project.segment(segment_i).name);
end
fprintf(fileID,'\n');


% Create a table of data processing progress (the bookkeeping part)
fprintf(fileID,'\n'); % empty row to visually divide this from previous part

% Add a header to this part
fprintf(fileID,'Data bookkeeping\t');
% also show the condition names
for segment_i = 1:project.nof_segments
    fprintf(fileID,'%s\t',project.segment(segment_i).name);
    % skip some cells to fit all variables per condition
    for variable_i = 1:(nof_vars_per_segment-1) % create an empty cell for each variable that we keep track of minus 1, before entering the next condition header
        fprintf(fileID,'\t'); % empty cell
    end
end
fprintf(fileID,'\n');

% add the table headers
fprintf(fileID,'Participants\t');
for segment_i = 1:project.nof_segments
    fprintf(fileID,'StartTime\t');
    fprintf(fileID,'EndTime\t');
    fprintf(fileID,'Segmented\t');
    fprintf(fileID,'Artifact_corrected\t');
    fprintf(fileID,'Deconvolved\t');
    fprintf(fileID,'Include_in_analysis\t');
end
fprintf(fileID,'\n');


% create a row for each participant
for pp_i=1:length(project.pp_labels)
    fprintf(fileID,'%s\t',string(project.pp_labels(pp_i)));
    for segment_i = 1:project.nof_segments
        fprintf(fileID, string(project.segment(segment_i).starttime(pp_i)));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.segment(segment_i).endtime(pp_i)));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.segment(segment_i).segmented(pp_i)));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.segment(segment_i).artifact_corrected(pp_i)));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.segment(segment_i).deconvolved(pp_i)));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.segment(segment_i).include(pp_i)));
        fprintf(fileID,'\t');
    end
    fprintf(fileID,'\n');
end

% close the bookkeeping file
fclose(fileID);



% Provide some feedback
fprintf('Project bookkeeping file "%s" has been updated.\n', fullfile(project.project_directory, [project.project_name '.belt']));


end