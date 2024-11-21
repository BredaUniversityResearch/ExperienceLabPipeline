function [answer, msg] = deconvolution_is_possible(cfg, project)
%% DECONVOLUTION_IS_POSSIBLE
%  function project = deconvolution_is_possible(cfg, project)
% 
% *DESCRIPTION*
% Checks whether deconvolution is possible:
% - is include set to true?
% - has segementation been done?
% - has artifact correction been done?
% - if deconvolution has been done ...
%     check handle_already_deconvolved_data = 'skip|redo|ask'
% Return true or false
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.processed_data_directory
% cfg.handle_already_deconvolved_data = 'skip|ask|redo' (default = 'skip')
%   'skip' :: if artifact correction has already been done, then skip
%   'ask'  :: if artifact correction has already been done, then ask the user what to do
%   'redo' :: artifact correction the data, even if it has already been done
% cfg.tempdir = fullfile(project.project_directory, '\Temp'); % temporary directory for datafiles
% cfg.conductance   = 'conductance_clean'; % LEDALAB expects a conductance field
% cfg.conductance_z = 'conductance_clean_z';


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
if ~isfield(cfg, 'conductance')
    cfg.conductance = 'conductance_artifact_corrected';
end
if ~isfield(cfg, 'handle_already_deconvolved_segments')
    cfg.handle_already_deconvolved_segments = 'skip';
end
if ~isfield(cfg, 'tempdir')
    cfg.tempdir = fullfile(project.project_directory, '\Temp'); % temporary directory for datafiles
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

    % check if artifact correction has been done
    if project.segment(segment_nr).artifact_corrected(pp_nr)

        % check whether artifact correction has already been done
        if project.segment(segment_nr).deconvolved(pp_nr)

            switch cfg.handle_already_deconvolved_segments
                case 'skip'
                    % Provide some feedback
                    path_filename = fullfile(project.processed_data_directory, ['segment_deconvolved_' project.segment(segment_nr).name '_' pp_label '.mat']);
                    msg = sprintf('Data of participant %s was already deconvolved and saved as %s', pp_label, path_filename);
                    return;
                case 'redo'
                    % process the data again
                    answer = true;
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo deconvolution?';
                    question = sprintf('Deconvolution has already been done for this participant.\nWould you like me to redo it?');
                    opts.Default = 'Skip';
                    question_answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
                    % Handle response
                    switch question_answer
                        case 'Skip'
                            % Provide some feedback
                            path_filename = fullfile(project.processed_data_directory, ['segment_deconvolved_' project.segment(segment_nr).name '_' pp_label '.mat']);
                            msg = sprintf('Data of participant %s was already deconvolved and saved as %s', pp_label, path_filename);
                            return;
                        case 'Redo'
                            % process the data again
                            answer = true;
                    end
            end
        else
            % segment has not been deconvolved
            answer = true;
        end
    else
        % sement has not been artifact corected
        msg = sprintf('Data of segment %s for participant %s has not been arifact corrected yet, so could not be deconvolved.', segment_name, pp_label);
    end
else % this segment should not be included in analysis
    msg = sprintf('Data of segment %s for participant %s is indicated to not include. Therefor the data was not deconvolved.', segment_name, pp_label);
end



end % deconvolution_is_possible



