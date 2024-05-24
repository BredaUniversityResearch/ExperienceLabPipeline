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
%                        'conductance_deconvolved',  
%                        'conductance_deconvolved_z'  
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


segment_nr = cfg.segment_nr;

fig = figure; % create a new figure
hold on; % indicate that we want to plot multiple lines in the same graph
legend_labels = [];

if strcmp(cfg.pp_labels, 'all'); % show all participants
    nof_pps = length(project.pp_labels);
    
    for pp_i = 1:nof_pps % for all participants
        % check if segmentation is completed
        if project.segment(segment_nr).segmented(pp_i)
            % load the data
            pp_label = cell2mat(project.pp_labels(pp_i));
            path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_nr).name '.mat']);
            load(path_filename, 'processed_segment');
       
            % draw the data, x=time, y=conductance
            plot(processed_segment.time, processed_segment.(cfg.data_type));
    
            % add the pp_label to the list for the legend
            legend_labels = [legend_labels; pp_label];
        end
    end
else
    for pp_label_i = 1:length(cfg.pp_labels)
        pp_label = cfg.pp_labels{pp_label_i};
        % load the data
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_nr).name '.mat']);
        if isfile(path_filename) % check if the data file exists
            load(path_filename, 'processed_segment');
       
            % draw the data, x=time, y=conductance
            plot(processed_segment.time, processed_segment.(cfg.data_type));
    
            % add the pp_label to the list for the legend
            legend_labels = [legend_labels; pp_label];
        end
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

function txt = displayCoordinates(~,info)
    x = info.Position(1);
    y = info.Position(2);
    txt = ['t = ' num2str(x) 's, conductance = ', num2str(y) 'uS)'];
end