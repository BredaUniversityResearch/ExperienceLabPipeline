function [processed_segment, project] = belt_get_data_segment(cfg, project)
%% BELT_GET_DATA_SEGMENT
%  function segment = belt_get_data_segment(cfg, project)
% 
% *DESCRIPTION*
% Loads the raw data and extracts the segment as specified by the segment
% start and end times.
% Adds the participant label and segment name to the data.
% Reorders the data struct.
% Saves the segmented data. Updates the bookkeeping. Provides feedback.
%
% *INPUT*
% A project struct:
%   project.project_name
%   project.project_directory
%   project.raw_data_directory
%   project.processed_data_directory
% cfg.handle_already_segmented_data = 'skip|ask|redo' (default = 'skip')
%   'skip' :: if segmenting has already been done, then skip
%   'ask'  :: if segmenting has already been done, then ask the user what to do
%   'redo' :: segment the data, even if it has already been done
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
if ~isfield(cfg, 'handle_already_segmented_data')
    cfg.handle_already_segmented_data = 'skip';
end


%%

pp_nr = cfg.pp_nr;
pp_label = cell2mat(project.pp_labels(pp_nr));
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;

% check whether the segment of this participant should be included
if project.segment(segment_nr).include(pp_nr)

    % check if segmentation is already done
    if project.segment(segment_nr).segmented(pp_nr)
        switch cfg.handle_already_segmented_data
            case 'skip'
                % return the existing segmented data
                % load the data
                path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' segment_name '.mat']);
                processed_segment = load(path_filename, 'processed_segment');
                % Provide some feedback
                fprintf('Data of participant %s was already segmented and saved as %s\n', pp_label, path_filename);
                return;
            case 'redo'
                % process the data again
            case 'ask'
                % ask whether it should be done again
                dlgtitle = 'Redo artifact correction?';
                question = sprintf('Segmentation has already been done for this participant.\nWould you like me to redo it?');
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
                        fprintf('Data of participant %s was already segmented and saved as %s\n', pp_label, path_filename);
                        return;
                    case 'Redo'
                        % process the data again
                end
        end
    end

    %  check starttime and endtime are provided
    starttime  = project.segment(segment_nr).starttime(pp_nr);
    endtime    = project.segment(segment_nr).endtime(pp_nr);

    % If not both the start and end times are present, abort processing
    % with a warning
    if isempty(cell2mat(starttime)) || isempty(cell2mat(endtime))
        warning('Start or endtime for participant %s, segment %s was not provided. Could not process this segment.', pp_label, segment_name);
        processed_segment = [];
        return;
    end

    % get the raw data
    cfg = [];
    cfg.datafolder = fullfile(project.raw_data_directory, pp_label);
    cfg.timezone = cell2mat(project.timezone(pp_nr)); % e.g. 'Europe/Amsterdam'
    % check data source: Empatica or Shimmer
    if isfile(fullfile(cfg.datafolder, 'EDA.csv')) % Empatica
        raw_data = e4eda2matlab(cfg); % get the raw data
    elseif isfile(fullfile(cfg.datafolder, 'physiodata.csv')) % Shimmer
        cfg.shimmerfile = 'physiodata.csv';
        cfg.fsample = 128; % TODO: get this from the data
        cfg.allowedsampledifference = 1; % TODO: make configurable
        raw_data = shimmer2matlab(cfg); % get the raw data
        raw_data = rmfield(raw_data,'temperature'); % remove data that we do not need
        raw_data = rmfield(raw_data,'acceleration');
        raw_data = rmfield(raw_data,'directionalforce');

% checking resampling effects
conductance_P104_128Hz = raw_data;
cfg_resample = [];
cfg_resample.fsample = 32;
cfg_resample.valueList = ["time"; "conductance"; "conductance_z"];
conductance_P104_32Hz = resample_generic(cfg_resample, raw_data); % downsample to 32 hz
cfg_resample.fsample = 4;
conductance_P104_4Hz = resample_generic(cfg_resample, raw_data); % downsample to 4 hz
figure;
plot(conductance_P104_128Hz.time, conductance_P104_128Hz.conductance);
hold on;
plot(conductance_P104_32Hz.time, conductance_P104_32Hz.conductance+0.02);
plot(conductance_P104_4Hz.time, conductance_P104_4Hz.conductance+0.04);


        raw_data = resample_generic(cfg_resample, raw_data); % downsample to 32 hz
    else % Neither a Shimmer nor an Empatica datafile was found
        warning('No datafile found for %s, segment %s. Please check! There should either be a ''EDA.csv'' or ''physiodata.csv'' file.', pp_label, segment_name);
        processed_segment = [];
        return;
    end

    % extract the [starttime - endtime] segment of the data
    cfg = [];
    cfg.starttime  = project.segment(segment_nr).starttime(pp_nr);
    cfg.endtime    = project.segment(segment_nr).endtime(pp_nr);
    cfg.timezone   = project.timezone(pp_nr); % e.g. 'Europe/Amsterdam'
    cfg.timeformat = project.timeformat(pp_nr); % e.g. 'unixtime' or 'datetime'
    processed_segment = segment_generic(cfg, raw_data);

    % add the participant label and segment name to the processed data struct
    processed_segment.pp_label = pp_label;
    processed_segment.segment_name = segment_name;

    % do some reorganizing and rename the conductance field to
    % conductance_raw === TODO: move this outside the pipiline into a
    % function
    [processed_segment.conductance_raw] = processed_segment.conductance;
    [processed_segment.conductance_raw_z] = processed_segment.conductance_z;
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
        'time', ...
        'conductance_raw', ...
        'conductance_raw_z' });

    % save the segmented data
    path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' segment_name '.mat']);
    save(path_filename, 'processed_segment');

    % Provide some feedback
    fprintf('Data of participant %s is segmented and saved as %s\n', pp_label, path_filename);

    % update bookkeeping
    % cfg = [];
    % cfg.processing_part = 'segmented';
    % cfg.pp_label = pp_label;
    % cfg.segment_nr = segment_nr;
    % cfg.processing_complete = true;
    % project = update_project_bookkeeping(cfg, project);

    % update the bookkeeping of the project
    project.segment(segment_nr).segmented(pp_nr) = true;
    path_filename = fullfile(project.project_directory, ['project_' project.project_name '.mat']);
    save(path_filename, 'project');



else % this segment should not be included in analysis

    processed_segment = [];
    % Provide some feedback
    fprintf('Data of segment %s for participant %s is indicated to not include. Therefor the data was not segmented, nor saved.\n', segment_name, pp_label);
    return;
end



end %belt_get_data_segment



