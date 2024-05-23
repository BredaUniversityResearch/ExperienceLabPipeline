function [processed_segment, project] = belt_deconvolve_eda(cfg, project)
%% BELT_DECONVOLVE_EDA
%  function segment = belt_deconvolve_eda(cfg, project)
% 
% *DESCRIPTION*
% Loads the artifact corrected data and deconvolves it into a tonic and phasic part.
% Saves the deconvolved data. Updates the bookkeeping. Provides feedback.
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
    cfg.conductance = 'conductance_clean';
end
if ~isfield(cfg, 'conductance_z')
    cfg.conductance_z = 'conductance_clean_z';
end
if ~isfield(cfg, 'handle_already_deconvolved_segments')
    cfg.handle_already_deconvolved_segments = 'skip';
end
if ~isfield(cfg, 'tempdir')
    cfg.tempdir = fullfile(project.project_directory, '\Temp'); % temporary directory for datafiles
end


%% DECONVOLVE and split into phasic and tonic components
%  run LedaLab over the corrected data to deconvolve it, and
%  split into phasic and tonic components


pp_nr = cfg.pp_nr;
pp_label = cell2mat(project.pp_labels(pp_nr));
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;

% create the temp folder, if needed
if ~exist(cfg.tempdir, "dir")
    % the folder does not exist
    [status, msg, msgID] = mkdir(cfg.tempdir); % create it
    tempfoldercreated = true; % take note that we created the folder. Remove it when we are done
else
    tempfoldercreated = false;% folder was already there, so leave it.
end


% check whether the segment of this participant should be included
if project.segment(segment_nr).include(pp_nr)

    % check if artifact correction has been done
    if project.segment(segment_nr).artifact_corrected(pp_nr)

        % check whether artifact correction has already been done
        if project.segment(segment_nr).deconvolved(pp_nr)

            switch cfg.handle_already_deconvolved_segments
                case 'skip'
                    % return the existing deconvolved data
                    % load the data
                    path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' segment_name '.mat']);
                    processed_segment = load(path_filename, 'processed_segment');
                    % Provide some feedback
                    fprintf('Data of participant %s was already deconvolved and saved as %s\n', pp_label, path_filename);
                    return;
                case 'redo'
                    % process the data again
                case 'ask'
                    % ask whether it should be done again
                    dlgtitle = 'Redo deconvolution?';
                    question = sprintf('Deconvolution has already been done for this participant.\nWould you like me to redo it?');
                    opts.Default = 'Skip';
                    answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
                    % Handle response
                    switch answer
                        case 'Skip'
                            % return the existing segmented data
                            % load the data
                            path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' segment_name '.mat']);
                            processed_segment = load(path_filename, 'processed_segment');
                            % Provide some feedback
                            fprintf('Data of participant %s was already deconvolved and saved as %s\n', pp_label, path_filename);
                            return;
                        case 'Redo'
                            % process the data again
                    end
            end
        end

        % load the data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_nr).name '.mat']);
        load(path_filename, 'processed_segment');
    
        % do the deconvolution thing
        processed_segment = deconvolve_eda(cfg, processed_segment);
    
        % do some reorganizing and renaming
        [processed_segment.conductance_phasic] = processed_segment.phasic;
        [processed_segment.conductance_phasic_z] = processed_segment.phasic_z;
        [processed_segment.conductance_tonic] = processed_segment.tonic;
        [processed_segment.conductance_tonic_z] = processed_segment.tonic_z;
        processed_segment = rmfield(processed_segment,'phasic');
        processed_segment = rmfield(processed_segment,'phasic_z');
        processed_segment = rmfield(processed_segment,'tonic');
        processed_segment = rmfield(processed_segment,'tonic_z');
        processed_segment = rmfield(processed_segment,'conductance');
        processed_segment = rmfield(processed_segment,'conductance_z');
        processed_segment = orderfields(processed_segment,...
            {'pp_label', ...
            'segment_name', ...
            'datatype',...
            'orig', ...
            'initial_time_stamp', ...
            'initial_time_stamp_mat', ...
            'fsample', ...
            'timeoff', ...
            'event', ...
            'analysis', ...
            'time', ...
            'eventchan', ...
            'conductance_raw', ...
            'conductance_raw_z', ...
            'conductance_clean', ...
            'conductance_clean_z', ...
            'conductance_phasic', ...
            'conductance_phasic_z', ...
            'conductance_tonic', ...
            'conductance_tonic_z' ...
            });




        % save the deconvolved data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' segment_name '.mat']);
        save(path_filename, 'processed_segment');
    
        % Provide some feedback
        fprintf('Data of participant %s is deconvolved and saved as %s\n', pp_label, path_filename);

        % update bookkeeping
        % cfg = [];
        % cfg.processing_part = 'deconvolved';
        % cfg.pp_label = pp_label;
        % cfg.segment_nr = segment_nr;
        % cfg.processing_complete = true;
        % project = update_project_bookkeeping(cfg, project);

        % update the bookkeeping of the project
        project.segment(segment_nr).deconvolved(pp_nr) = true;
        path_filename = fullfile(project.project_directory, ['project_' project.project_name '.mat']);
        save(path_filename, 'project');
    
    else
        processed_segment = [];
        % Provide some feedback
        fprintf('Data of segment %s for participant %s has not aerifact corrected, so could not be deconvolved.\n', segment_name, pp_label);
    end
else % this segment should not be included in analysis

    processed_segment = [];
    % Provide some feedback
    fprintf('Data of segment %s for participant %s is indicated to not include. Therefor the data was not deconvolved, nor saved.\n', segment_name, pp_label);
end

if tempfoldercreated
    % we created a temporary folder, now remove it
    rmdir(cfg.tempdir, 's'); % this fails sometimes, don't know why
end

end % belt_deconvolve_eda



