function [answer, msg] = cleaning_GPS_data_is_possible(cfg, project)
%% cleaning_GPS_data_is_possible
%  function [answer, msg] = cleaning_GPS_data_is_possible(cfg, project)
% 
% *DESCRIPTION*
% Checks whether cleaning is possible:
% - is include set to true?
% - has segementation been done?
% Return true or false
%
% *INPUT*
% A project struct:
%   project.segment(segment_nr).segmented(pp_nr)
%   project.segment(segment_nr).cleaned(pp_nr)
%   project.segment(segment_nr).include(pp_nr)
% A configuration struct (cfg) with
%   cfg.segment_nr
%   cfg.pp_nr
%
% *OUTPUT*
% returns the answer to the ultimate question of whether
% cleaning_GPS_data_is_possible (true|false)
% and a feedback message

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
if ~isfield(cfg, 'segment_nr')
    error('Provide a cfg.segment_nr');
end
if ~isfield(cfg, 'pp_nr')
    error('Provide a cfg.pp_nr');
end


%%

answer = false;
msg = '';
pp_nr = cfg.pp_nr;
pp_label = project.pp_labels{pp_nr};
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;

% check whether the segment of this participant should be included
if project.segment(segment_nr).include(pp_nr)
    % check if segmentation is already done
    if project.segment(segment_nr).segmented(pp_nr)
             answer = true;
    else % this data is not yet segmented. Provide some feedback
        msg = sprintf('Data of segment %s for participant %s has not yet been segmented, cleaning is not possible.', segment_name, pp_label);
    end
else % include is set to false. Provide some feedback
    msg = sprintf('Data of segment %s for participant %s is indicated to not include. Cleaning is not needed.', segment_name, pp_label);
end



end % cleaning_GPS_data_is_possible



