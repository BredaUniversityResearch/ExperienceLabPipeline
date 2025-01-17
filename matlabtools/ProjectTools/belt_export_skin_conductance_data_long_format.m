function belt_export_skin_conductance_data_long_format(cfg, project)
%% BELT_EXPORT_SKIN_CONDUCTANCE_DATA_LONG_FORMAT
% function belt_export_skin_conductance_data_long_format(cfg, project);
%
% *DESCRIPTION*
% reads processed skin conductance data
% formats it into a table
% and saves it as a csv file,
%
% *INPUT*
% Configuration Options
% cfg.   = 
%
% *OUTPUT*
% function saves the data as csv file
%
% *NOTES*
% NA
%
% *BY*
% Hans Revers, 08-11-2024

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




% for readability of the code
nof_segments = project.nof_segments;
nof_pps = length(project.pp_labels);

% start with an empty table
export_table = [];

for pp_nr = 1:nof_pps
    for segment_nr = 1:nof_segments

        pp_label = project.pp_labels{pp_nr};
        segment_name = project.segment(segment_nr).name;


        % % get the raw data
        % if project.segment(segment_nr).segmented(pp_nr)
        %     % get the raw data
        %     path_filename = fullfile(app.project.processed_data_directory, ['segment_raw_' segment_name '_' pp_label '.mat']);
        %     load(path_filename);
        %     % segment_raw struct is now loaded with fields time and conductance_raw
        % else
        %     % nothing to see here
        %     return;
        % end
        %
        % % get the artifact corrected data
        % if app.project.segment(segment_nr).artifact_corrected(pp_nr)
        %     path_filename = fullfile(app.project.processed_data_directory, ['segment_artifact_corrected_' segment_name '_' pp_label '.mat']);
        %     load(path_filename);
        %     % segment_artifact_corrected struct is now loaded with field conductance_artifact_corrected
        % end

        % get the deconvolved data
        if project.segment(segment_nr).deconvolved(pp_nr) && project.segment(segment_nr).include(pp_nr)
            path_filename = fullfile(app.project.processed_data_directory, ['segment_deconvolved_' segment_name '_' pp_label '.mat']);
            load(path_filename);
            % segment_deconvolved struct is now loaded with field conductance_phasic and conductance_tonic

            % % downsample the raw data  and artifact corrected data to match the deconvolved sampling rate
            % cfg_resample = [];
            % cfg_resample.resample = 'yes';
            % cfg_resample.fsample = 1 / (segment_deconvolved.time(2) - segment_deconvolved.time(1));
            % cfg_resample.valueList = ["conductance_raw"];
            % segment_raw = resample_generic(cfg_resample,  segment_raw);
            % cfg_resample.valueList = ["conductance_artifact_corrected"];
            % segment_artifact_corrected = resample_generic(cfg_resample,  segment_artifact_corrected);


            %  set elapsed time
            time = segment_deconvolved.time;
            nof_timepoints = length(time);
            % set start time
            starttime(1:nof_timepoints, 1) = project.segment(segment_nr).starttime(pp_nr);
            % participant label
            participant(1:nof_timepoints, 1) = {pp_label};
            % segment
            segment(1:nof_timepoints, 1) = {segment_name};
            % get the skin conductance data
            phasicDriver = segment_deconvolved.conductance_phasicDriver;
            phasicDriver_z = segment_deconvolved.conductance_phasicDriver_z;
            phasic = segment_deconvolved.conductance_phasic;
            phasic_z = segment_deconvolved.conductance_phasic_z;
            tonic = segment_deconvolved.conductance_tonic;
            tonic_z = segment_deconvolved.conductance_tonic_z;
    
            % combine data in a table
            temp_table = table(participant, segment, starttime, time, phasicDriver, phasic, tonic, phasicDriver_z, phasic_z, tonic_z);
            % add this table to the overall table
            export_table = [export_table; temp_table];
        end
    end
end

% save the table as a csv file
filter = {'*.csv'};
path_filename = fullfile(project.output_directory, [project.project_name '_processed_skin_conductance.csv']);
[filename,location] = uiputfile(filter, 'Save processed skin conductance data as', path_filename);
if ~isequal(filename,0) && ~isequal(location,0)
    exportgraphics(app.SkinConductanceAxes,[location filename]);
end



end