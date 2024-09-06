function msg = save_deconvolved_data(cfg, project, segment_deconvolved)
%% SAVE_DECONVOLVED_DATA
%  function msg = save_deconvolved_data(cfg, project, segment_deconvolved)
% 
% *DESCRIPTION*
% saves the deconvolved data
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.processed_data_directory
% A configuration struct (cfg) with
%   cfg.segment_nr
%   cfg.pp_nr
% The deconvolved data:
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

% save the deconvolved data
path_filename = fullfile(project.processed_data_directory, ['segment_deconvolved_' segment_name '_' pp_label '.mat']);
save(path_filename, 'segment_deconvolved');

% Provide some feedback
msg = sprintf('Data of participant %s is deconvolved and saved as %s', pp_label, path_filename);

end % save_deconvolved_data



