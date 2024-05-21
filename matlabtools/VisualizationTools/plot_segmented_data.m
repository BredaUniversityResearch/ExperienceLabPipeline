function plot_segmented_data (cfg, project)
%% SEGMENT GENERIC
% function out = segment_generic (cfg,data)
%
% *DESCRIPTION*
%  plots data of all participants in a projects in a single figure for data
%  inspection. Use it to check for outliers and non-responders.
%  IMPORTANT: currently it can only plot the segmented raw data. The
%  function will be expanded to als o be able to plot the artifact
%  corrected data, phasic data, and phasic_z data
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
%  cfg.data_type :: currently only 'conductance' is supported
%  
% === TODO:
%     check input
%     write description


segment_i = cfg.segment_nr;

fig = figure; % create a new figure
hold on; % indicate that we want to plot multiple lines in the same graph
pp_labels = [];
nof_pps = length(project.pp_labels);

for pp_i = 1:nof_pps % for all participants
    % check if segmentation is completed
    if project.segment(segment_i).segmented(pp_i)
        % load the data
        pp_label = cell2mat(project.pp_labels(pp_i));
        path_filename = fullfile(project.processed_data_directory, [pp_label '_processed_segment_' project.segment(segment_i).name '.mat']);
        load(path_filename, 'processed_segment');
   
        % draw the data, x=time, y=conductance
        plot(processed_segment.time, processed_segment.(cfg.data_type));

        % add the pp_label to the list for the legend
        pp_labels = [pp_labels; pp_label];
    end
end
xlabel('Time (s)');
ylabel('Conductance (\muS)')
title(['Raw skin conductance data (' project.segment(segment_i).name ' segment)']);
legend(pp_labels, 'Location', 'eastoutside');
hold off;

% call the displayCoordinates function to show the pp_label at the mouse
% tip
dcm = datacursormode;
dcm.Enable = 'on';
dcm.DisplayStyle = 'window';
dcm.UpdateFcn = @displayCoordinates;

end


function txt = displayCoordinates(~,info)
    x = info.Position(1);
    y = info.Position(2);
    %pp_i = find(myarray(:,x)== y);
    txt = ['pp = TODO (' num2str(x) ', ' num2str(y) ')'];
end