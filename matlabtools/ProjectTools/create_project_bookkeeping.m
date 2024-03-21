function project = create_project_bookkeeping(project)
%% CREATE_PROJECT_BOOKKEEPING
%  function create_project_bookkeeping(project)
% 
% *DESCRIPTION*
% Creates a .csv file to store the project properties
%   project.project_name
%   project.project_directory
%   project.rawdata_directory
%   project.segmented_data_directory
%   project.artifact_corrected_data_directory
%   project.deconvolved_data_directory
%   project.output_directory
%   project.ask_create_directory
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
if ~isfield(project, 'nof_ws_conditions')
    project.nof_ws_conditions = 1;
    project.condition_names(1) = "Condition1";
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FOR TESTING, REMOVE WHEN DONE
project.nof_ws_conditions = 2;
project.condition_names(2) = "Condition2";
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END FOR TESTING

%% Create the bookkeeping struct

% read the participant labels from the raw data directory
dinfo = dir(project.raw_data_directory);
dinfo(ismember({dinfo.name}, {'.', '..'})) = []; % Skip the system entries "." and ".."
folder_names = {dinfo([dinfo.isdir]).name}'; % get the names of folders only

% Perhaps we should do some more checks here, like whether there is an
% actual datafile in each folder, but for now we will asume each folder
% holds data of a participant
participant_labels = folder_names;

% add the bookkeeping struct to the project
for participant_i=1:length(participant_labels)
    project.bookkeeping(participant_i).participant_labels = participant_labels(participant_i); % participant labels
    for condition_i = 1:project.nof_ws_conditions
        project.bookkeeping(participant_i).condition(condition_i).starttime = 0;
        project.bookkeeping(participant_i).condition(condition_i).endtime = 0;
        project.bookkeeping(participant_i).condition(condition_i).segmented = 0;
        project.bookkeeping(participant_i).condition(condition_i).artifact_corrected = 0;
        project.bookkeeping(participant_i).condition(condition_i).deconvolved = 0;
        project.bookkeeping(participant_i).condition(condition_i).include = 1;
    end
end

% note how many variables are stored for each condition
nof_vars_per_condition =  length(fieldnames(project.bookkeeping(1).condition(1, 1)));

%% Create a text file
%  the tab (\t) is a separator, it moves the cursor to the next cell
%  the newline character (\n) moves the cursor to the next line/row

% open the file
file_dir = fullfile(project.project_directory, [project.project_name '.belt']);
[fileID, errmsg] = fopen(file_dir,'w');

% check for errors related to opening the file
if length(errmsg)
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

fprintf(fileID,'Segmented_data_directory\t');
fprintf(fileID,'%s\n',project.segmented_data_directory); 

fprintf(fileID,'Artifact_corrected_data_directory\t');
fprintf(fileID,'%s\n',project.artifact_corrected_data_directory); 

fprintf(fileID,'Deconvolved_data_directory\t');
fprintf(fileID,'%s\n',project.deconvolved_data_directory); 

fprintf(fileID,'Output_directory\t');
fprintf(fileID,'%s\n',project.output_directory); 

fprintf(fileID,'Number_of_within_subjects_conditions\t');
fprintf(fileID,'%i\n',project.nof_ws_conditions); 

fprintf(fileID,'Condition_names\t');
for condition_i = 1:project.nof_ws_conditions
    fprintf(fileID,'%s\t',project.condition_names(condition_i));
end
fprintf(fileID,'\n');


% Create a table of data processing progress (the bookkeeping part)
fprintf(fileID,'\n'); % empty row to visually divide this from previous part

% Add a header to this part
fprintf(fileID,'Data bookkeeping\t');
% also show the condition names
for condition_i = 1:project.nof_ws_conditions
    fprintf(fileID,'%s\t',project.condition_names(condition_i));
    % skip some cells to fit all variables per condition
    for variable_i = 1:(nof_vars_per_condition-1) % create an empty cell for each variable that we keep track of minus 1, before entering the next condition header
        fprintf(fileID,'\t'); % empty cell
    end
end
fprintf(fileID,'\n');

% add the table headers
fprintf(fileID,'Participants\t');
for condition_i = 1:project.nof_ws_conditions
    fprintf(fileID,'StartTime\t');
    fprintf(fileID,'EndTime\t');
    fprintf(fileID,'Segmented\t');
    fprintf(fileID,'Artifact_corrected\t');
    fprintf(fileID,'Deconvolved\t');
    fprintf(fileID,'Include_in_analysis\t');
end
fprintf(fileID,'\n');


% create a row for each participant
for participant_i=1:length(participant_labels)
    fprintf(fileID,'%s\t',string(project.bookkeeping(participant_i).participant_labels));
    for condition_i = 1:project.nof_ws_conditions
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).starttime));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).endtime));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).segmented));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).artifact_corrected));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).deconvolved));
        fprintf(fileID,'\t');
        fprintf(fileID, string(project.bookkeeping(participant_i).condition(condition_i).include));
        fprintf(fileID,'\t');
    end
    fprintf(fileID,'\n');
end

% close the bookkeeping file
fclose(fileID);



% Provide some feedback
fprintf('Project bookkeeping file "%s.belt" created at "%s".\n', project.project_name, project.project_directory);


end