function [project, msg] = save_cleaned_GPS_data(cfg, project, cleaned_GPS)
%% SAVE_CLEANED_GPS_DATA
%  function project = save_cleaned_GPS_data(cfg, project)
% 
% *DESCRIPTION*
% saves the cleaned GPS data
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.processed_data_directory
% A configuration struct (cfg) with
%   cfg.segment_nr
%   cfg.pp_nr
% The cleaned GPS data:
%   cleaned_GPS
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


% save the artifact corrected data
path_filename_data = fullfile(project.processed_data_directory, ['segment_cleaned_GPS_' segment_name '_' pp_label '.mat']);
save(path_filename_data, 'cleaned_GPS');

% update the bookkeeping of the project
project.segment(segment_nr).cleaned(pp_nr) = true;
% since cleaning, set snapped2model to false
project.segment(segment_nr).snapped2model(pp_nr) = false;

% save the project bookkeeping
save_project(project);

% Provide some feedback
msg = sprintf('Cleaned GPS data of participant %s is saved as %s', pp_label, path_filename_data);


end % save_cleaned_GPS_data



