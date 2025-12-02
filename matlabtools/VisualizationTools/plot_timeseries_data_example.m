%% plot ERPs example
%
%
%  This is an example of using the function plot_timeseries_data(cfg, data)
%  It loads some example (phasic) skin conductance data and shows the mean data per condition
%  and some form of variance as shaded area round the mean.
%  Configuration options are provided and explained
%  For more information type
%  help plot_timeseries_data
%  or
%  doc plot_timeseries_data
%
%  Changelog:
%  Hans Revers: created September 2023




%% Load some example data

%  This is skin conductance data of 10 participants in 2 conditions
%  We will load the project data to retreive the participant numbers and condition names
%  It can also tell us which participants should be included 

% Open the project and intialize some variables.
clear;

project = [];
project.project_name       = 'Demo';
project.project_directory  = fullfile(pwd, '..', 'Demo Project');

cfg = [];
cfg.show_input_window       = false; %  show an input window to check and edit the directories
project = belt_open_project(cfg, project);
project_directory = project.project_directory;
processed_data_directory = project.processed_data_directory;

nof_pps = size(project.pp_labels, 1);
nof_segments = project.nof_segments;

data_counter = 0;
for segment_i = 1 % Flying
    segment_label = project.segment(segment_i).name;
    for pp_i = 1:nof_pps
        if project.segment(segment_i).include(pp_i)
            if project.segment(segment_i).deconvolved(pp_i)

                % get the participant label, e.g. P001
                pp_label = project.pp_labels{pp_i};

                % load the deconvolved skin conductance data
                path_filename = fullfile(processed_data_directory, ['segment_deconvolved_', segment_label, '_',  pp_label, '.mat']);
                load(path_filename); % variable name = segment_deconvolved

                data_counter = data_counter + 1;
                deconvolved_data_Flying(data_counter) = segment_deconvolved;

            end
        end
    end
end


data_counter = 0;
for segment_i = 2 % Nature
    segment_label = project.segment(segment_i).name;
    for pp_i = 1:nof_pps
        if project.segment(segment_i).include(pp_i)
            if project.segment(segment_i).deconvolved(pp_i)

                % get the participant label, e.g. P001
                pp_label = project.pp_labels{pp_i};

                % load the deconvolved skin conductance data
                path_filename = fullfile(processed_data_directory, ['segment_deconvolved_', segment_label, '_',  pp_label, '.mat']);
                load(path_filename); % variable name = segment_deconvolved

                data_counter = data_counter +1;
                deconvolved_data_Nature(data_counter) = segment_deconvolved;

            end
        end
    end
end

%% plot the graphs

cfg = [];

% cfg.YLim             = [0 0.25];                             

% cfg.colours          = [[0 1 1];          [1 0 0]];

% cfg.linestyle        = {'-',          '--'};
cfg.linestyle        = '-';

% cfg.linewidth        = [2.0,          2.5]; 
cfg.linewidth        = 2.0; 

cfg.legendlabels     = {'Flying', 'Nature'};
cfg.legend           = 'yes';
cfg.errorbar         = 'sem'; % 'sem|sd|ci|none' (default = 'sem')
cfg.smoothing        = 'yes'; % 'yes|no' (default = 'no') 
cfg.smoothing_window = 10; % (default = 20)               
cfg.smoothing_method = 'gaussian'; % ('movmean|gaussian', default = 'movmean')               
cfg.Ylabel           = 'Skin conductance (\muS)';  
cfg.Xlabel           = 'Time (s)';  
cfg.latency          = 'all';
cfg.parameter        = 'conductance_phasic';

figure;
plot_timeseries_data(cfg, deconvolved_data_Flying, deconvolved_data_Nature);
title 'Phasic skin conductance data';
% set(gca, 'XTick',        [10, 15, 20, 25, 30]); 
% set(gca, 'XTickLabel', {'0', ' ', '10 ', ' ',  '20'});
fontsize(24,"points");
