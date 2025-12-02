function plot_timeseries_data(cfg, varargin)
% PLOT_TIMESERIES_DATA plots the means amplitude over time as a line with a shaded area representing the specified measure of spread in the data
%
% Use as
%   plot_timeseries_data(cfg, data1, data2, data3, ...)
%
% The following configuration options are supported:
%   cfg.parameter        = what type of data to plot, for skin conductance data 
%       this could be 'phasic', 'pasic_z', 'tonic', 'conductance', etc.
%   cfg.latency          = 'all', [start end] (default = 'all')
%   cfg.YLim             = [min max] (if omitted, Y range fits to graph)
%   cfg.colours          = {colour1, colour2, ...} colour is either a RGB array or a MatLAB named colour
%       if not provided, default MatLAB colours will be used
%       if the number of colours is smaller than that of the data, 
%       the colours are recycled
%   cfg.legend           = 'yes|no' (default = 'no') 
%   cfg.legendlabels     = {legend_label1, legend_label2, ...} 
%   cfg.legendposition   = 'northeast|northwest|southeast|southwest' (default = 'northeast')
%   cfg.legendnumcolumns = integer value, determines in how many columns
%       the legend entries are displayed (default = 1)
%   cfg.errorbar         = 'sem|sd|ci|none' (default = 'sem')
%        Specify what the shaded area around the mean should represent.
%        sd   = standard deviation (per timepoint, across participants
%        sem  = standard error of the mean (as sd/sqrt(N))
%        ci   = 95% confidence interval (as 1.96 * sem)
%        none = the shaded area will not be plotted
%   cfg.smoothing        = 'yes|no' (default = 'no')
%        Whether to perform smoothing on the data before plotting
%   cfg.smoothing_window        = length of the smoothing window (default = 20)
%   cfg.smoothing_method        = 'movmean|gaussian' (default = 'movmean')
%   cfg.linewidth               = [linewidth1, linewidth2, ...] Either specify linewidth as a scalar 
%                                 if every line has the same width, or as an array of scalars to 
%                                 specify the width of each line seperately(default linewidth = 1.5)
%   cfg.linestyle               = {style1, style2, ...} (default style = '-'). Style options are 
%                                                       "-" Solid line, 
%                                                       "--" Dashed line, 
%                                                       ":" Dotted line, 
%                                                       "-." Dash-dotted line 
%                                 If only a single style is provided, each line will have that style 
%
%   Some figure configuration is done, but these can be overruled by simply adding
%   the desired settings after calling the plot_ERPs function
%   See example code:
%   - plot_ERPs_clean_example.m (for a 3 segment ERP plot)
%   - plot_ERPs_simple_example.m (for a single ERP plot)
%   - plot_ERPs_options_example.m (for a demonstration of multiple options
%                                  with some explanation)
%
% Created by Hans Revers, 27 sept 2023
% This script is an adaptation from the example code in the "FieldTrip made easy" paper by Popov, Oostenveld, and Schoffelen (2018)


%% VARIABLE CHECK


% assume varargin{i} is a timelocked dataset
nof_datasets  = numel(varargin);

% In case we need them, gem12 is a set of matlab default colours
default_colours = orderedcolors("gem12");
nof_default_colours     = length(default_colours);

%  If not specified, set the defaults
if ~isfield(cfg, 'latency')
    cfg.latency = 'all';
end
if ~isfield(cfg, 'Ylabel')
    cfg.Ylabel = 'Amplitude';
end
if ~isfield(cfg, 'legend')
    cfg.legend = 'no';
end
if ~isfield(cfg, 'legendlabels')
    cfg.legendlabels = {};
elseif length(cfg.legendlabels) < nof_datasets
    for dataset_i = length(cfg.legendlabels):nof_datasets
        cfg.legendlabels{dataset_i} = ['var_' dataset_i];
    end
end
if ~isfield(cfg, 'legendposition')
    cfg.legendposition = 'northeast';
end
if ~isfield(cfg, 'legendnumcolumns')
    cfg.legendnumcolumns = 1;
end
if ~isfield(cfg, 'errorbar')
    cfg.errorbar = 'sem';
end
if ~isfield(cfg, 'smoothing')
    cfg.smoothing = 'no';
elseif strcmp(cfg.smoothing, 'yes')
    if ~isfield(cfg, 'smoothing_window')
        cfg.smoothing_window = 20;
    elseif ~isnumeric(cfg.smoothing_window)
        cfg.smoothing_window = 20;
    end
    if ~isfield(cfg, 'smoothing_method')
        cfg.smoothing_method = 'movmean';
    elseif ~strcmp(cfg.smoothing_method, 'gaussian') && ~strcmp(cfg.smoothing_method, 'movmean')
        cfg.smoothing_method = 'movmean';
    end
    
end
if ~isfield(cfg, 'colours')
    for dataset_i = 1:nof_datasets
        cfg.colours(dataset_i, :) = default_colours(rem(dataset_i, nof_default_colours)+1,:);
    end
elseif ~(height(cfg.colours) == nof_datasets)
    warning('plot_physiodata_timeseries: the number of specified colours does not match the number of datasets, using default colours instead.');
    for dataset_i = 1:nof_datasets
        cfg.colours{dataset_i} = default_colours(rem(dataset_i, nof_default_colours)+1,:);
    end
end
if ~isfield(cfg, 'parameter')
    error('No parameter was specified. Unclear what you want plotted. Please specify a parameter. Type "help plot_timeseries_data" for more info');
    % cfg.parameter = 'phasic';
end
if ~isfield(cfg, 'linewidth')
    for dataset_i = 1:nof_datasets
        cfg.linewidth(dataset_i, :) = 1.5; % default value if linewidth is not provided
    end
elseif length(cfg.linewidth) < nof_datasets
    for dataset_i = 1:nof_datasets
        cfg.linewidth(dataset_i, :) = cfg.linewidth(1, :); % all linewidths are the same
    end
end
if ~isfield(cfg, 'linestyle')
    for dataset_i = 1:nof_datasets
        cfg.linestyle(dataset_i, :) = '-'; % default value if linewidth is not provided
    end
elseif length(cfg.linestyle) < nof_datasets
    for dataset_i = 1:nof_datasets
        cfg.linestyle(dataset_i, :) = cfg.linestyle(1, :); % all linestyles are the same
    end
end



% internal defaults
shaded_alpha     = .2;



%% the data


%  set x (time), get it from the first participant of the first dataset
x = varargin{1}(1).time(:)'; 

if strcmp(cfg.latency, 'all')
    % use the whole latency range
    startindex = 1;
    endindex = length(x);
else
    % Check whether latency is valid
    if ~isnumeric(cfg.latency) % latency should be two numbers
        error('Provided latency range is not valid. Use [start end] in seconds. Type help plot_timeseries_data for further info.')
    end
    if cfg.latency(1) < min(x) % the start latency cannot be before the start of the data
        error('Provided latency range is not valid. The start time is smaller then the start of the data. Type help plot_timeseries_data for further info.')
    end
    if cfg.latency(2) > max(x) % the end latency cannot be after the end of the data
        error('Provided latency range is not valid. The end time exceed the time range of the data. Type help plot_timeseries_data for further info.')
    end
    % latency values appear in order
    starttime = cfg.latency(1);
    endtime   = cfg.latency(2);
    % find the start and end indices of these times
    startindex = find(x >= starttime, 1);
    endindex   = find(x >= endtime, 1);
    % truncate the time 
    x = x(startindex:endindex);
end

% tell the plotter to keep what is already on canvas
hold on;

% for each of the datasets, determine the mean (averaged over pps), 
% and the lower/upper limits of the shaded area representing the s.e.m.
for dataset_i = nof_datasets:-1:1

    % first, create a matrix of NaNs
    nof_pps = length(varargin{dataset_i});
    nof_timepoints = (endindex-startindex+1);
    the_data = NaN(nof_pps, nof_timepoints);

    % then, fill that matrix with the participant data, 
    % each row will hold the data of one participant  
    for pp_i = 1:length(varargin{dataset_i})
        % the_data = varargin{1}(1).(cfg.parameter);
        the_data(pp_i, :) =  varargin{dataset_i}(pp_i).(cfg.parameter)(startindex:endindex)';
    end


    % smoothing
    if strcmp(cfg.smoothing, 'yes')
        the_data = smoothdata(the_data, 2, cfg.smoothing_method, cfg.smoothing_window);
    end


    % mean EEG amplitude, averaged over pps
    y(dataset_i).mean = mean(squeeze(the_data),1,"omitnan"); 



    % e = sd|sem|ci|none 
    switch cfg.errorbar
        case 'sd'   % standard deviation
            y(dataset_i).e = std(squeeze(the_data),1,"omitnan"); 
        case 'sem'  % the standard error of the mean
            y(dataset_i).e = std(squeeze(the_data),1,"omitnan") ./ sqrt(size(the_data, 1)); 
        case 'ci'   % 95% confidence interval
            N = size(the_data, 1);
            data_sem = std(squeeze(the_data),1,"omitnan") ./ sqrt(N);
            CI95 = tinv(0.975, N-1); % Calculate 95% Probability Intervals Of t-Distribution
            y(dataset_i).e = bsxfun(@times, data_sem, CI95(:)); % Calculate 95% Confidence Interval
            % y(dataset_i).e = 1.96 .* (std(squeeze(the_data),1,"omitnan") ./ sqrt(size(the_data, 1))); % old method, incorrect for small N
        case 'none' % no shaded area
            y(dataset_i).e = zeros(1, size(squeeze(the_data),2)); 
        otherwise   % user provided an unknow error-bar type. Display a warning message.
            warning('unknown error-bar type "%s", shaded area cannot be plotted', errorbar);
            y(dataset_i).e = zeros(1, size(squeeze(the_data),2)); 
    end

    % lower and upper border of shaded area: mean +- s.e.m.
    y(dataset_i).low  = y(dataset_i).mean - y(dataset_i).e; % lower bound
    y(dataset_i).high = y(dataset_i).mean + y(dataset_i).e; % upper bound
end

% first draw the shaded areas
for dataset_i=numel(varargin):-1:1
    hp(dataset_i) = patch('XData', [x, x(end:-1:1), x(1)], 'YData', [y(dataset_i).low, y(dataset_i).high(end:-1:1), y(dataset_i).low(1)]); % shaded area of SE around the mean
    if size(cfg.colours, 1) == 0
        set(hp(dataset_i), 'edgecolor', 'none', 'FaceAlpha', shaded_alpha);
    else
        set(hp(dataset_i), 'facecolor', cfg.colours(dataset_i, :), 'edgecolor', 'none', 'FaceAlpha', shaded_alpha);
    end
end

% then draw the x en y axis
x_axis_line = line(x,0*y(1).mean); % x = 0 axis
y_axis_line = line(0*x,y(1).mean); % y = 0 axis
set(x_axis_line, 'color', 'k','linewidth',1.0);
set(y_axis_line, 'color', 'k','linewidth',1.0);

% finally draw the mean amplitudes of each dataset
for dataset_i=numel(varargin):-1:1
    data(dataset_i) = line(x,y(dataset_i).mean); % mean amplitude 
    if size(cfg.colours, 1) == 0
        set(data(dataset_i), 'linewidth', cfg.linewidth(dataset_i), 'linestyle',cfg.linestyle(dataset_i)); 
    else
        set(data(dataset_i), 'color', cfg.colours(dataset_i, :),'linewidth', cfg.linewidth(dataset_i), 'linestyle', cfg.linestyle(dataset_i)); 
    end
end

% add a legend, if requested
if strcmp(cfg.legend, 'yes')
    legenddata = zeros(1, numel(varargin));
    for dataset_i=1:numel(varargin)
        legenddata(dataset_i) = data(dataset_i);
    end
    legend(legenddata, cfg.legendlabels,'FontSize',10, 'Orientation', 'vertical', 'Location', cfg.legendposition, 'NumColumns', cfg.legendnumcolumns);
end


% specify the appearance of the (sub)plot, these can beoverruled by
% specifying them after calling this function
set(gca,'FontSize',12);
set(gca,'box','off');

if isfield(cfg, 'YLim')
    set(gca, 'YLim', cfg.YLim); 
end

if isfield(cfg, 'latency') 
    if strcmp(cfg.latency, 'all')
        set(gca, "XLim", [x(1) x(end)]);
    else
        set(gca, "XLim", cfg.latency);
    end
end
if isfield(cfg, 'Xlabel')
    xlabel(cfg.Xlabel);
end


ylabel(cfg.Ylabel);

end