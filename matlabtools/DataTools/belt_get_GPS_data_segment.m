function [project, msg] = belt_get_GPS_data_segment(cfg, project)
%% BELT_GET_GPS_DATA_SEGMENT
%  function project = belt_get_GPS_data_segment(cfg, project)
% 
% *DESCRIPTION*
% Loads the raw GPS data and extracts the segment as specified by the segment
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
msg = '';
pp_nr = cfg.pp_nr;
pp_label = project.pp_labels{pp_nr};
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;

% check whether the segment of this participant should be included
if project.segment(segment_nr).include(pp_nr)

    % check if segmentation is already done
    if project.segment(segment_nr).segmented(pp_nr)
        switch cfg.handle_already_segmented_data
            case 'skip'
                % Provide some feedback
                % path_filename = fullfile(project.processed_data_directory, ['segment_raw_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                % msg = sprintf('Data of participant %s was already segmented and saved as %s', pp_label, path_filename);
                return;
            case 'redo'
                % process the data again
            case 'ask'
                % ask whether it should be done again
                dlgtitle = 'Redo segmentation?';
                question = sprintf('Segmentation has already been done for this participant.\nWould you like me to redo it?');
                opts.Default = 'Skip';
                answer = questdlg(question, dlgtitle, 'Redo','Skip', opts.Default);
                % Handle response
                switch answer
                    case 'Skip'
                        % Provide some feedback
                        % path_filename = fullfile(project.processed_data_directory, ['segment_raw_' project.segment(segment_nr).name  '_' pp_label '.mat']);
                        % msg = sprintf('Data of participant %s was already segmented and saved as %s', pp_label, path_filename);
                        return;
                    case 'Redo'
                        % process the data again
                end
        end
    end

    %  check starttime and endtime are provided
    starttime  = project.segment(segment_nr).starttime{pp_nr};
    endtime    = project.segment(segment_nr).endtime{pp_nr};

    % If not both the start and end times are present, abort processing
    % with a warning
    if isempty(starttime) || isempty(endtime)
        msg = sprintf('Warning: Start or endtime for participant %s, segment %s was not provided.', pp_label, segment_name);
        return;
    end

    % get the raw data
    cfg = [];
    cfg.datafolder = fullfile(project.raw_data_directory, pp_label);
    cfg.timezone = cell2mat(project.timezone(pp_nr)); % e.g. 'Europe/Amsterdam'
    
    % check data source: Strava or the BUas GPS app
    filename = [pp_label '_gps.csv'];
    if  isfile(fullfile(cfg.datafolder, filename)) % BUas GPS app data
        % TODO write a read data procedure
        % read in the GPS data.
        cfg = [];
        cfg.gpsfile = filename;
        cfg.datafolder = fullfile(project.project_directory, '0.RawData', project.pp_labels{pp_nr});
        raw_data = buasgps2matlab(cfg);

        if isempty(raw_data)
            msg = sprintf('%s BUas GPS data for %s, segment %s could not be read.', msg, pp_label, segment_name);
            return;
        end

    elseif  isfile(fullfile(cfg.datafolder, 'strava.tcx')) % Strava data
    
        % read in the GPS data.
        cfg = [];
        cfg.stravafile = 'strava.tcx';
        cfg.datafolder = fullfile(project.project_directory, '0.RawData', project.pp_labels{pp_nr});
        cfg.newtimezone = 'Europe/Amsterdam';
        raw_data = stravatcx2matlab(cfg);

        if isempty(raw_data)
            msg = sprintf('%s Strava data for %s, segment %s could not be read.', msg, pp_label, segment_name);
            return;
        end
    else % No GPS datafile was found
        msg = sprintf('Warning: No GPS datafile found for %s, segment %s.', pp_label, segment_name);
        return;
    end

    % extract the [starttime - endtime] segment of the data
    cfg = [];
    cfg.starttime  = starttime;
    cfg.endtime    = endtime;
    cfg.timezone   = project.timezone(pp_nr); % e.g. 'Europe/Amsterdam'
    cfg.timeformat = project.timeformat(pp_nr); % e.g. 'unixtime' or 'datetime'

    try
        segment_raw_GPS = segment_generic(cfg, raw_data);
    catch ME
        % segmentation caused an error, provide feedback and move on to the next
        msg = sprintf('Warning: Segmentation caused an error for segment %s, participant %s.', segment_name, pp_label);
        warning(ME.message);
        return;
    end

    % add the participant label and segment name to the processed data struct
    segment_raw_GPS.pp_label = pp_label;
    segment_raw_GPS.segment_name = segment_name;

    % save the segmented data
    path_filename = fullfile(project.processed_data_directory, ['segment_raw_GPS_' project.segment(segment_nr).name  '_' pp_label '.mat']);
    save(path_filename, 'segment_raw_GPS');

    % Provide some feedback
    msg = sprintf('%s Data of participant %s is segmented and saved as %s', msg, pp_label, path_filename);

    % update the bookkeeping of the project
    project.segment(segment_nr).segmented(pp_nr) = true;
    save_project(project);



else % this segment should not be included in analysis

    % Provide some feedback
    msg = sprintf('Segment %s for participant %s is set to not include.', segment_name, pp_label);
    return;
end



end %belt_get_data_segment



