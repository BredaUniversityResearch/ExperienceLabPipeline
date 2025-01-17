function project = belt_artifact_correction(cfg, project)
%% BELT_ARTIFACT_CORRECTION
%  function project = belt_artifact_correction(cfg, project)
% 
% *DESCRIPTION*
% Loads the segmented data, marks potential artifacts, and opens a window
% to manually check and change these artifacts.
% Saves the artifact corrected data. Updates the bookkeeping. Provides feedback.
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.processed_data_directory
% cfg.handle_already_cleaned_data = 'skip|ask|redo' (default = 'skip')
%   'skip' :: if artifact correction has already been done, then skip
%   'ask'  :: if artifact correction has already been done, then ask the user what to do
%   'redo' :: artifact correction the data, even if it has already been done
%

% *OUTPUT*
% creates directories that do not exist, if specified

% check input
if ~isfield(project, 'project_name')
    error('The project struct has no project_name field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'project_directory')
    error('The project struct has no project_directory field. I cannot create a project bookkeeping file without it.');
end
if ~isfield(project, 'raw_data_directory')
    error('The project struct has no raw_data_directory field. Run create_new_project() first.');
end
if ~isfield(project, 'processed_data_directory')
    error('The project struct has no processed_data_directory field. Run create_new_project() first.');
end
if ~isfield(cfg, 'segment_nr')
    error('Provide a cfg.segment_nr');
end
if ~isfield(cfg, 'pp_nr')
    error('Provide a cfg.pp_nr');
end
if ~isfield(cfg, 'handle_already_cleaned_segments')
    cfg.handle_already_cleaned_segments = 'skip';
end

% set the parameters for the artifact detection algorithm
if ~isfield(cfg, 'timwin')
    cfg.timwin = 20;
end
if ~isfield(cfg, 'threshold')
    cfg.threshold = 5;
end
if ~isfield(cfg, 'default_solution')
    cfg.default_solution = 'linear';
end

 % for readability of the code
 pp_nr = cfg.pp_nr;
pp_label = cell2mat(project.pp_labels(pp_nr));
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;

if ~isfield(cfg, 'segment_identifier')
    cfg.segment_identifier = ['Segment: ', segment_name, ', participant: ', pp_label];
end


%  check whether artifact correction is even possible and needed
[answer, msg] = artifact_correction_is_possible(cfg, project);
fprintf(msg);
if ~answer % artifact correction is not possible or not needed
    return; % skip the rest of the function
end


% load the segmented raw data
path_filename = fullfile(project.processed_data_directory, ['segment_raw_' project.segment(segment_nr).name  '_' pp_label '.mat']);
load(path_filename, 'segment_raw');

% get potential artifacts
cfg.artifacts = get_potential_artifacts(cfg, segment_raw);

% open the artifact correction window to get the artifact corrected data
corrected_data = open_artifact_correction_window(cfg, segment_raw);

% check whether cleaned data has been returned
if ~isempty(corrected_data)
    % save the artifact corrected segment
    segment_raw.conductance_artifact_corrected = corrected_data;
    [project, msg] = save_artifact_corrected_data(cfg, project, segment_raw);
    fprintf('%s', msg);
end


end %belt_get_data_segment



