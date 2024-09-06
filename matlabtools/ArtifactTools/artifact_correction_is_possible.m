function [answer, msg] = artifact_correction_is_possible(cfg, project)
%% artifact_correction_is_possible
%  function answer = artifact_correction_is_possible(cfg, project)
% 
% *DESCRIPTION*
% Checks whether artifact correction is possible:
% - is include set to true?
% - has segementation been done?
% - if artifact correction has already been done, 
%     check handle_already_cleaned_segments = 'skip|redo|ask'
% Return true or false
%
% *INPUT*
% A project struct:
%   project.segment(segment_nr).segmented(pp_nr)
%   project.segment(segment_nr).artifact_corrected(pp_nr)
%   project.segment(segment_nr).include(pp_nr)
% A configuration struct (cfg) with
%   cfg.handle_already_cleaned_data = 'skip|ask|redo' (default = 'skip')
%     'skip' :: if artifact correction has already been done, then skip
%     'ask'  :: if artifact correction has already been done, then ask the user what to do
%     'redo' :: artifact correction the data, even if it has already been done
%   cfg.segment_nr
%   cfg.pp_nr
%
% *OUTPUT*
% returns the answer to the ultimate question of whether
% artifact_correction_is_possible (true|false)
% an a feedback message

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
if ~isfield(cfg, 'handle_already_cleaned_segments')
    cfg.handle_already_cleaned_segments = 'skip';
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

        % check whether artifact correction has already been done
        if project.segment(segment_nr).artifact_corrected(pp_nr)
            % segment has already been artifact corrected, check what to do
            switch cfg.handle_already_cleaned_segments
                case 'skip'
                    % Provide some feedback
                    path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                    msg = sprintf('Data of participant %s was already artifact corrected and saved as %s', pp_label, path_filename);
                    return;
                case 'redo'
                    % process the data again
                    answer = true;
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo artifact correction?';
                    question = sprintf('Artifact correction has already been done for this participant.\nWould you like me to redo it?');
                    opts.Default = 'Skip';
                    question_answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
                    % Handle response
                    switch question_answer
                        case 'Skip'
                            % Provide some feedback
                            path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                            msg = sprintf('Data of participant %s was already segmented and saved as %s', pp_label, path_filename);
                            return;
                        case 'Redo'
                            % process the data again
                            answer = true;
                    end
            end
        else % segment has not yet been artifact corrected
            answer = true;
        end
    else % this data is not yet segmented
        % Provide some feedback
        msg = sprintf('Data of segment %s for participant %s has not been segmented, so could not be artifact corrected.', segment_name, pp_label);
    end
else % include is set to false
    % Provide some feedback
    msg = sprintf('Data of segment %s for participant %s is indicated to not include. So artifact correction is not needed.', segment_name, pp_label);
end



end %belt_get_data_segment



