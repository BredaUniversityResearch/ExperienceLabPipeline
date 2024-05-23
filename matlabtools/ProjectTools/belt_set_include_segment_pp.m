function project = belt_set_include_segment_pp(cfg, project)
%% BELT_SET_INCLUDE_SEGMENT_PP
%  function project = belt_set_include_segment_pp(cfg, project)
% 
% *DESCRIPTION*
% Sets 'include' to true or false for a given segment, participant.
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%
% Configuration options
%  cfg.segment_nr = 1;
%  cfg.pp_labels = {'P001', 'P007', 'P012'};
%  cfg.include = true|false (default = false)


% *OUTPUT*
% returns the updated project struct
% saves the project bookkeeping file

% check input
if ~isfield(project, 'project_name')
    error('The project struct has no project_name field.');
end
if ~isfield(project, 'project_directory')
    error('The project struct has no project_directory field.');
end
if ~isfield(project, 'pp_labels')
    error('The project struct has no participant labels (pp_labels).');
end
if ~isfield(cfg, 'segment_nr')
    error('cfg.segment_nr is not provided.');
end
if ~isfield(cfg, 'pp_labels')
    error('cfg.pp_labels is not provided.');
end
if ~isfield(cfg, 'include')
    cfg.include = false;
end


%% update include

pp_nrs = ismember(project.pp_labels, cfg.pp_labels);
project.segment(cfg.segment_nr).include(pp_nrs) = cfg.include;

% save the project struct as a matlab datafile
path_filename = fullfile(project.project_directory, ['project_' project.project_name '.mat']);
save(path_filename, 'project');

% provide feedback
pp_string = '';
for i=1:length(cfg.pp_labels)
    pp_string = [pp_string, cell2mat(cfg.pp_labels(i)), ', '];
end

fprintf('Parameter ''include'' updated for segment %s for participant(s) %s.\n', project.segment(cfg.segment_nr).name, pp_string);


end % belt_open_project



