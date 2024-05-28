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
if ~isfield(cfg, 'show_result_for_each')
    cfg.show_result_for_each = 'no';
end


%%

pp_nr = cfg.pp_nr;
pp_label = cell2mat(project.pp_labels(pp_nr));
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;
cfg.segment_identifier = ['Segment ', segment_name, ', participant ', pp_label];

% check whether the segment of this participant should be included
if project.segment(segment_nr).include(pp_nr)

    % check if segmentation is already done
    if project.segment(segment_nr).segmented(pp_nr)

        % check whether artifact correction has already been done
        if project.segment(segment_nr).artifact_corrected(pp_nr)

            switch cfg.handle_already_cleaned_segments
                case 'skip'
                    % Provide some feedback
                    path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                    fprintf('Data of participant %s was already artifact corrected and saved as %s\n', pp_label, path_filename);
                    return;
                case 'redo'
                    % process the data again
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo artifact correction?';
                    question = sprintf('Artifact correction has already been done for this participant.\nWould you like me to redo it?');
                    opts.Default = 'Skip';
                    answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
                    % Handle response
                    switch answer
                        case 'Skip'
                            % Provide some feedback
                            path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                            fprintf('Data of participant %s was already segmented and saved as %s\n', pp_label, path_filename);
                            return;
                        case 'Redo'
                            % process the data again
                    end
            end
        end

        % load the segmented raw data
        path_filename = fullfile(project.processed_data_directory, ['segment_raw_' project.segment(segment_nr).name  '_' pp_label '.mat']);
        load(path_filename, 'segment_raw');
    
        
        % open the artifact correction window
        segment_artifact_corrected = artifact_eda_belt(cfg, segment_raw); 

        % remove the raw data (that is already stored in segment_raw)
        segment_artifact_corrected = rmfield(segment_artifact_corrected, 'conductance_raw');
    
        % save the artifact corrected data
        path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name '_' pp_label '.mat']);
        save(path_filename, 'segment_artifact_corrected');
        
        % Provide some feedback
        fprintf('Data of participant %s is artifact corrected and saved as %s\n', pp_label, path_filename);
    
        % update bookkeeping
        % cfg = [];
        % cfg.processing_part = 'artifact_corrected';
        % cfg.pp_label = pp_label;
        % cfg.segment_nr = segment_nr;
        % cfg.processing_complete = true;
        % project = update_project_bookkeeping(cfg, project);
    
        % update the bookkeeping of the project
        project.segment(segment_nr).artifact_corrected(pp_nr) = true;
        path_filename = fullfile(project.project_directory, ['project_' project.project_name '.mat']);
        save(path_filename, 'project');
    else
        % Provide some feedback
        fprintf('Data of segment %s for participant %s has not been segmented, so could not be artifact corrected.\n', segment_name, pp_label);
    end
else % this segment should not be included in analysis

    % Provide some feedback
    fprintf('Data of segment %s for participant %s is indicated to not include. Therefor the data was not artifact corrected, nor saved.\n', segment_name, pp_label);
end



end %belt_get_data_segment



