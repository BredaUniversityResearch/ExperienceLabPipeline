function project = belt_deconvolve_eda(cfg, project)
%% BELT_DECONVOLVE_EDA
%  function project = belt_deconvolve_eda(cfg, project)
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
    cfg.conductance = 'conductance_artifact_corrected';
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
pp_label = project.pp_labels{pp_nr};
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;


% check whether artifact correction is even possible and needed
[answer, msg] = deconvolution_is_possible(cfg, app.project);
app.AppendLog(msg);
if ~answer % artifact correction is not possible or not needed
    return; % skip the rest of the function
end

% create the temp folder, if needed
if ~exist(cfg.tempdir, "dir")
    % the folder does not exist
    [status, msg, msgID] = mkdir(cfg.tempdir); % create it
    tempfoldercreated = true; % take note that we created the folder. Remove it when we are done
else
    tempfoldercreated = false;% folder was already there, so leave it.
end

% load the data
path_filename = fullfile(project.processed_data_directory, ['segment_artifact_corrected_' project.segment(segment_nr).name '_' pp_label '.mat']);
load(path_filename, 'segment_artifact_corrected');

if isfield(cfg, 'resample') && strcmp(cfg.resample, 'yes') && isfield(cfg, 'fsample')
    % resample the data before deconvolution
    cfg_resample = [];
    cfg_resample.fsample = cfg.fsample;
    segment_artifact_corrected = resample_generic(cfg_resample,  segment_artifact_corrected);
end

% add the zscored conductance
segment_artifact_corrected.conductance_artifact_corrected_z = normalize(segment_artifact_corrected.conductance_artifact_corrected);
cfg.conductance_z   = 'conductance_artifact_corrected_z';

% do the deconvolution thing
segment_deconvolved = deconvolve_eda(cfg, segment_artifact_corrected);

% do some reorganizing and renaming
[segment_deconvolved.conductance_phasicDriver] = segment_deconvolved.phasicDriver;
[segment_deconvolved.conductance_phasicDriver_z] = segment_deconvolved.phasicDriver_z;
[segment_deconvolved.conductance_phasic] = segment_deconvolved.phasic;
[segment_deconvolved.conductance_phasic_z] = segment_deconvolved.phasic_z;
[segment_deconvolved.conductance_tonic] = segment_deconvolved.tonic;
[segment_deconvolved.conductance_tonic_z] = segment_deconvolved.tonic_z;
segment_deconvolved = rmfield(segment_deconvolved,'phasic');
segment_deconvolved = rmfield(segment_deconvolved,'phasic_z');
segment_deconvolved = rmfield(segment_deconvolved,'tonic');
segment_deconvolved = rmfield(segment_deconvolved,'tonic_z');
segment_deconvolved = rmfield(segment_deconvolved,'conductance_artifact_corrected');
segment_deconvolved = rmfield(segment_deconvolved,'conductance_artifact_corrected_z');
segment_deconvolved = orderfields(segment_deconvolved,...
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
    'conductance_phasicDriver', ...
    'conductance_phasicDriver_z', ...
    'conductance_phasic', ...
    'conductance_phasic_z', ...
    'conductance_tonic', ...
    'conductance_tonic_z' ...
    });

% save the deconvolved data
path_filename = fullfile(project.processed_data_directory, ['segment_deconvolved_' project.segment(segment_nr).name '_' pp_label '.mat']);
save(path_filename, 'segment_deconvolved');

% Provide some feedback
fprintf('Data of participant %s is deconvolved and saved as %s\n', pp_label, path_filename);

% update the bookkeeping of the project
project.segment(segment_nr).deconvolved(pp_nr) = true;

% save the project bookkeeping
save_project(project);

% if we created a temporary folder, clean up
if tempfoldercreated
    rmdir(cfg.tempdir, 's'); % this fails sometimes, don't know why
end

end % belt_deconvolve_eda



