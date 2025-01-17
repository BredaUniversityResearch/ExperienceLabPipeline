function plot_segmented_data (cfg, project)
%% SEGMENT GENERIC
% function out = segment_generic (cfg,data)
%
% *DESCRIPTION*
%  plots data of all participants in a projects in a single figure for data
%  inspection. Use it to check for outliers and non-responders.
%
% * INPUT*
% A project struct with at least
%  project.pp_labels :: (participant labels are used to load the data)
%  project.processed_data_directory :: (for loading the data)
%  project.segment(cfg.segment_nr).name :: (for loading the data)
%  project.segment(cfg.segment_nr).segmented(pp_i) :: 
%  processed_segment.time
%  processed_segment.(cfg.data_type)
% A cfg struct with
%  cfg.segment_nr :: 
%  cfg.data_type :: e.g. 'conductance_raw',  
%                        'conductance_raw_z', 
%                        'conductance_artifact_corrected',  
%                        'conductance_artifact_corrected_z',  
%                        'conductance_phasic',  
%                        'conductance_phasic_z'  
%                        'conductance_tonic',  
%                        'conductance_tonic_z'  
%  cfg.pp_labels = 'all' or a cell array of participant labels, e.g.{'P001', 'P002'}; (default = 'all')

%  
% === TODO:
%     check input
%     write description

%% check input
if ~isfield(cfg, 'pp_labels')
    cfg.pp_labels = 'all';
end
if ~isfield(cfg, 'data_type')
    cfg.data_type = 'conductance_raw';
end

%%

% keep track of the segment number
segment_nr = cfg.segment_nr;
segment_name = project.segment(segment_nr).name;


% determine which files to load
switch cfg.data_type
    case 'conductance_raw'
        data_struct_name = 'segment_raw';
    case 'conductance_raw_z'
        data_struct_name = 'segment_raw';
    case 'conductance_artifact_corrected'
        data_struct_name = 'segment_artifact_corrected';
    case 'conductance_artifact_corrected_z'
        data_struct_name = 'segment_artifact_corrected';
    case 'conductance_phasic'
        data_struct_name = 'segment_deconvolved';
    case 'conductance_phasic_z'  
        data_struct_name = 'segment_deconvolved';
    case 'conductance_tonic'
        data_struct_name = 'segment_deconvolved';
    case 'conductance_tonic_z'  
        data_struct_name = 'segment_deconvolved';
end

figure; % create a new figure
hold on; % indicate that we want to plot multiple lines in the same graph
legend_labels = [];

if strcmp(cfg.pp_labels, 'all'); % show all participants
    pp_i_list = 1:length(project.pp_labels);
else % show only the provided participants
    pp_i_list = find(ismember(project.pp_labels', cfg.pp_labels));
end
    
for pp_i = pp_i_list % for all participants the list
    % check if segmentation is completed
    if project.segment(segment_nr).segmented(pp_i)
        % load the data
        pp_label = cell2mat(project.pp_labels(pp_i));
        path_filename = fullfile(project.processed_data_directory, [data_struct_name '_' segment_name '_' pp_label '.mat']);
        data = load(path_filename, data_struct_name);
        data_fieldnames = fieldnames(data);
        data = data.(data_fieldnames{1});

        % check whether normalization (zscoring) needs to happen
        if strcmp(cfg.data_type, 'conductance_raw_z')
            data.conductance_raw_z = normalize(data.conductance_raw);
        elseif strcmp(cfg.data_type, 'conductance_artifact_corrected_z')
            data.conductance_artifact_corrected_z = normalize(data.conductance_artifact_corrected);
        end

        % draw the data, x=time, y=conductance
        plot(data.time, data.(cfg.data_type));

        % add the pp_label to the list for the legend
        legend_labels = [legend_labels; pp_label];
    end
end

xlabel('Time (s)');
ylabel('Conductance (\muS)')
title([cfg.data_type ' (' project.segment(segment_nr).name ' segment)'], 'Interpreter', 'none');
legend(legend_labels, 'Location', 'eastoutside');
hold off;

% call the displayCoordinates function to show the pp_label at the mouse
% tip
dcm = datacursormode;
dcm.Enable = 'on';
dcm.DisplayStyle = 'window';
dcm.UpdateFcn = @customdatatip;

end

function output_txt = customdatatip(obj,event_obj,str)
output_txt = {event_obj.Target.DisplayName};
end
