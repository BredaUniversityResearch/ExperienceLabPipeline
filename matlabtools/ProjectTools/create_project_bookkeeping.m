function project = create_project_bookkeeping(cfg, project)
%% CREATE_PROJECT_BOOKKEEPING
%  function create_project_bookkeeping(project)
% 
% *DESCRIPTION*
% Creates a .csv file to store the project properties
%   project.project_name
%   project.project_directory
%   project.rawdata_directory
%   project.processed_data_directory
%   project.output_directory
%
% The file will be called <project_name>.belt
% and will be saved at <project_directory>

%% Check input
%
if ~isfield(project, 'project_name')
    error('The project struct has no project_name field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'project_directory')
    error('The project struct has no project_directory field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'nof_segments')
    project.nof_segments = 1;
    project.segment(1).name = "Segment1";
end



%% Create the bookkeeping struct

% === One possibility to get the participant labels is to extract them 
%     from the raw data directory. However, that can be a bit of a mess with 
%     other folders. So perhaps not the best approach ===
    % dinfo = dir(project.raw_data_directory);
    % dinfo(ismember({dinfo.name}, {'.', '..'})) = []; % Skip the system entries "." and ".."
    % folder_names = {dinfo([dinfo.isdir]).name}'; % get the names of folders only
    % participant_labels = folder_names;

% add the bookkeeping part to the project
for segment_i = 1:project.nof_segments
    % project.segment(segment_i).starttime        = zeros(size(project.pp_labels));; % already extracted from the ParticipantData file
    % project.segment(segment_i).endtime          = zeros(size(project.pp_labels));; % already extracted from the ParticipantData file
    project.segment(segment_i).segmented          = zeros(size(project.pp_labels));
    project.segment(segment_i).artifact_corrected = zeros(size(project.pp_labels));
    project.segment(segment_i).deconvolved        = zeros(size(project.pp_labels));
    project.segment(segment_i).include            = ones(size(project.pp_labels));
end

% note how many variables are stored for each condition
nof_vars_per_segment =  length(fieldnames(project.segment(1)));

%% Create a text file
%  the tab (\t) is a separator, it moves the cursor to the next cell
%  the newline character (\n) moves the cursor to the next line/row

% open the file
file_dir = fullfile(project.project_directory, [project.project_name '.belt']);
[fileID, errmsg] = fopen(file_dir,'w');

% check for errors related to opening the file
if ~isempty(errmsg)
    error(errmsg);
end

% === TODO: check whether project file already existed
%           if so, compare the project struct to the existing project file
%           and report ===

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
fprintf('Project bookkeeping file "%s.belt" created at "%s".\n', project.project_name, project.project_directory);


end