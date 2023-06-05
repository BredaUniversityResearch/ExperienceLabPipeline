function patchplot (cfg,varargin)
%% PATCHPLOT
% function out = patchplot (cfg,varargin)
%
% *DESCRIPTION*
%This function creates a figure from a struct / struct array, plotting the
%graphdata as a linegraph, and the patchdata as a transparent background
%patch
%
% *INPUT*
%This function takes a data struct / structarray, as well as a cfg
%containing the settings used for generating the visuals, and for all provided
%datasets plots the graph, and a patch of size patchdata around this graph
%
%Configuration Options
%cfg.patchdata = name of the variable containing the patch data
%   default = "y_std"
%cfg.graphdata = name of the variable containing the graph data
%   default = "y"
%cfg.timedata = name of the variable containing the time data
%   default = "x"
%cfg.dataname = (OPTIONAL) name of the data on the legend, leave empty to use "data+number"
%cfg.xlabel = name of the text shown on the x label of the figure
%   default = cfg.timedata
%cfg.ylabel = name of the text shown on the y label of the figure
%   default = cfg.graphdata
%cfg.colormap = (OPTIONAL) colormap to use for plotting multiple datasets (JEY)
%   default = colormap(jet)
%
%Data Requirements
%All of the provided datastructs must contain the variables provided for 
% patchdata, graphdata, timedata, and dataname
%
% *OUTPUT*
%This function will generate a figure with the provided data
%
% *NOTES*
%This function is currently unable to plot datasets of varying length!
%
% *BY*
%Wilco, 05-06-2023

%% DEV INFO
%Information relevant for developers, things to add to the function,
%potential updates to consider
% TO ADD:
%1 Add check / catch for multiple datasets of different length

%% CHECK VARIABLES
%check if cfg variables are set
if ~isfield(cfg,'patchdata')
    cfg.patchdata = 'y_std';
    warning('patchdata not provided, using default (y_std)');
end
if ~isfield(cfg,'graphdata')
    cfg.graphdata = 'y';
    warning('Graphdata not provided, using default (y)');
end
if ~isfield(cfg,'timedata')
    cfg.timedata = 'x';
    warning('Timedata not provided, using default (x)');
end
if ~isfield(cfg,'xlabel')
    warning('X label not provided, using X variable names instead');
    cfg.xlabel = string(cfg.timedata);
end
if ~isfield(cfg,'ylabel')
    warning('Y label not provided, using y variable names instead');
    cfg.ylabel = string(cfg.graphdata);
end
if ~isfield(cfg,'colormap')
    cfg.colormap = colormap(jet);
end

%check if variables exist in all datasets
for isamp = 1:nargin-1
    if isfield(cfg,'dataname')
        if ~isfield(varargin{isamp},(cfg.dataname))
            cfg = rmfield(cfg,'dataname');
            warning('Dataname not found in data, using default (data+number)');
        end
    end
    if ~isfield(varargin{isamp},cfg.timedata)
        error(strcat("timedata not available in dataset:",string(isamp)));
    end
    if ~isfield(varargin{isamp},cfg.graphdata)
        error(strcat("graphdata not available in dataset:",string(isamp)));
    end
    if ~isfield(varargin{isamp},cfg.patchdata)
        error(strcat("patchdata not available in dataset:",string(isamp)));
    end
end

%% CREATE THE FIGURE
hold on
%Loop over all structures in the data
amount = nargin-1;
datanames = strings(1,(nargin-1)*2);
for isamp = 1:amount

    % Determine the color for this participant
    if isamp == 1
        cloc = 1;
    elseif isamp == amount
        cloc = height(cfg.colormap);
    else
        cloc = int32(height(cfg.colormap)/(amount-1)*(isamp-1));
    end

    col = cfg.colormap(cloc,:);

    % Setup the X & Y Data
    x = varargin{isamp}.(cfg.timedata);

    y = varargin{isamp}.(cfg.graphdata);
    lo = y-varargin{isamp}.(cfg.patchdata);
    hi = y+varargin{isamp}.(cfg.patchdata);

    %Plot the Patch & Graph
    patchvis = patch([x; x(end:-1:1); x(1)], [lo; hi(end:-1:1); lo(1)], col); % shaded area (SEM) of movie

    %Generate all Patches
    set(patchvis, 'facecolor', col, 'edgecolor', 'none','facealpha',0.25);
end

for isamp = 1:amount

    % Determine the color for this participant
    if isamp == 1
        cloc = 1;
    elseif isamp == amount
        cloc = height(cfg.colormap);
    else
        cloc = int32(height(cfg.colormap)/(amount-1)*(isamp-1));
    end

    col = cfg.colormap(cloc,:);

    % Setup the X & Y Data
    x = varargin{isamp}.(cfg.timedata);

    y = varargin{isamp}.(cfg.graphdata);

    %Plot the Patch & Graph
    graphvis = line(x,y);

    %Generate all Line Graphs
    set(graphvis, 'color', col,'linewidth',1);

    %Populate Legend with Empties
    if isfield(cfg,'dataname')
        datanames(amount+isamp) = string(varargin{isamp}.(cfg.dataname));
    else
        datanames(amount+isamp) = strcat("Data",string(isamp));
    end
end

set(gca,'FontSize',20);
set(gca,'YColor','k');
set(gca,'box','on');
xlabel(cfg.xlabel);
ylabel(cfg.ylabel);

legend(datanames, 'location', 'best')
hold off
end