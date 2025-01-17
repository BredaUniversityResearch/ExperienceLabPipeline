function save_project(project)
%% SAVE_PROJECT
%  function save_project(cfg, project)
% 
% *DESCRIPTION*
% saves the project bookkeeping file.
%

% check input
if ~isfield(project, 'project_directory')
    error('The project struct does not have the proper format. It has no project_directory field. ');
end
if ~isfield(project, 'project_name')
    error('The project struct does not have the proper format. It has no project_name field. ');
end


% save the bookkeeping of the project
path_filename_project = fullfile(project.project_directory, ['project_' project.project_name '.belt']);
save(path_filename_project, 'project');



end % save_project



