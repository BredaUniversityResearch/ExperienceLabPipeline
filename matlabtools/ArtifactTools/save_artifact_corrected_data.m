function [project, msg] = save_artifact_corrected_data(cfg, project, data_artifact_corrected)
%% SAVE_ARTIFACT_CORRECTED_DATA
%  function project = save_artifact_corrected_data(cfg, project)
% 
% *DESCRIPTION*
% saves the artifact corrected data
% removes superfluous field conductance_raw, as that is already stored in the segmented data file.
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.processed_data_directory
% A configuration struct (cfg) with
%   cfg.segment_nr
%   cfg.pp_nr
% The artifact corrected data:
%   segment_artifact_corrected
%
% *OUTPUT*
% returns a message that can be displayed for feedback

% check input
if ~isfield(project, 'project_name')
    error('The project struct does not have the proper format. It has no project_name field. ');
end
if ~isfield(project, 'nof_segments')
    error('The project struct does not have the proper format. It has no nof_segments field. ');
end
if ~isfield(project, 'segment')
    error('The project struct does not have the proper format. It has no segment field. ');
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

%%

pp_nr = cfg.pp_nr;
pp_label = cell2mat(project.pp_labels(pp_nr));
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;


% remove the raw data (that is already stored in segment_raw)
data_artifact_corrected = rmfield(data_artifact_corrected, 'conductance_raw');

% save the artifact corrected data
path_filename_data = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' segment_name '_' pp_label '.mat']);
save(path_filename_data, 'data_artifact_corrected');

% update the bookkeeping of the project
project.segment(segment_nr).artifact_corrected(pp_nr) = true;
path_filename_project = fullfile(project.project_directory, ['project_' project.project_name '.belt']);
save(path_filename_project, 'project');

% Provide some feedback
msg = sprintf('Data of participant %s is artifact corrected and saved as %s', pp_label, path_filename_data);


end % save_artifact_corrected_data



