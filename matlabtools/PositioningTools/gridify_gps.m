function out = gridify_gps(cfg,data)
%% GRIDIFY GPS
% function out = gridify (cfg,data)
%
% *DESCRIPTION*
% The gridify function can take a table, or structure with several tables named "data",
% to perform calculations over number-based colums on a grid with
% configurable size. By default all additional number-based columns will
% return the mean value for the position, unless the desired calculations
% are defined in cfg.variables.
%
% For a single table, the function will output a table with the calculations
% performed over that file. For a structure with multiple tables, the
% calculations will first be performed over every individual table, after
% which the same calculations will be performed over combination of all
% gridded participant tables.
% The combined gridding function will replace "Count" by "Sum" to get a
% the sum of all counts for all participants.
%
% *INPUT*
% Configuration Options
% cfg.gridsize = (OPTIONAL) the size of the calculation grid in meters
%    default = 20
% cfg.smoothmethod = (OPTIONAL) smoothing method applied over the gridde    d
%   data, possible to choose from:'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'
%   default = 'none'
%   THIS FEATURE IS STILL BEING TESTED, ONLY USE THIS IF YOU ARE AWARE OF
%   THE LIMITATIONS
% cfg.spheroid = (OPTIONAL) type of sphere used for reprojecting the data
%   from lat/lon
%   default = wgs84Ellipsoid("m");
% cfg.variables = (OPTIONAL) table with calculations performed over the
%   selected data, colums must be: 'in', 'out', 'calculation', where in is
%   the name of the data-column, out is the name in the output column, and
%   calculation is the calculation to perform over the data inside that
%   grid point.
%   calculation methods = min, max, unique, count, mean, sum
%   default = mean calculation for all data columns except 'lat';'lon';'alt'
%
% Data Requirements
% There are 3 options:
% 1. Table containing a lat & lon column as well as at least one
%    additional number-based column. An alt column is adviced but optional.
% 2. Structure with at least a single table field as described in option 1.
%    The table variable must be named 'data'.
% 3. Structure array with at least a single table field as described in
%    option 1 called data for every row in the structure array.
%    The table variable must be named 'data'.
%
% *OUTPUT*
% The output will be a single table containig lat,lon,alt,x,y,z,and a
% separate column for each calculation performed.
%
% *NOTES*
% N/A
%
% *BY*
% Wilco Boode, 09/01/2024

%% DEV INFO
% This function uses the gridify_single function to perform individual
% calculations for each participant.
% ADDITIONAL FEATURES TO ADD:
% 1. If a table is provided, check if there are multiple participants, if so
%    separate the participants to calculate per-participant
% 2. Config option to output combined & per-participant gridded data?
% 3. Config option to define the table name in the data struct

%% CHECK CFG AND DATA FOR ALL PARTICIPANTS
% Check if data is either a struct or a table
if ~isa(data,'table') && ~isstruct(data)
    error("DATA IS NEITHER A TABLE NOR A STRUCT, FORMAT IS NOT ACCEPTED!");
end

% Check settings in CFG
if ~isfield(cfg,'gridsize')
    warning('gridsize is not defined in the configuration, using default (20)');
    cfg.gridsize = 20;
end

if ~isfield(cfg,'smoothmethod')
    cfg.smoothmethod = 'none';
elseif max(strcmp(cfg.smoothmethod,{'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'})) == 0
    warning('provided smoothmethod ''%s'' is not valid. Smoothmethod = ''movmean'' will be used. Type ''help gridify'' for more info.' , cfg.smoothmethod );
    cfg.smoothmethod = 'movmean';
end

if ~isfield(cfg,'spheroid')
    % creates an ellipsoid (= a sphere that is flattened in one direction)
    % that matches the shape and size of the earth. Length of the axes is
    % in meters
    cfg.spheroid = wgs84Ellipsoid("m");
end

%Check table specific data and variables
if isa(data,'table')
    if ~isfield(cfg,'variables')
        cfg.variables = gridify_identify_variables(data);
    end
end

%Check structure specific data and variables
if isstruct(data)
    %Check if struct contains a filed with correct name (data)
    if ~max(any("data"==string(fieldnames(data))))
        error("PROVIDED STRUCT DOES NOT CONTAIN 'data' VARIABLE");
    end
    
    %check if all data entries are tables
    for samp_i = 1:length(data)
        if ~isa(data(samp_i).data,'table')
            error(strcat("ROW ",string(samp_i)," DOES NOT CONTAIN A TABLE, ONLY TABLES ARE ACCEPTED"));
        end
    end

    % Check if variables calculation exist, if not setup new based on the first participant
    if ~isfield(cfg,'variables')
        cfg.variables = gridify_identify_variables(data(1).data);
    end

    % Check individual participants in struct on available variables,
    % remove any that are not found in other participants
    for samp_i = 1:max(size(data))
        labels = fieldnames(data(samp_i).data);
        valid = contains(cfg.variables.in,labels);
        for jsamp =height(cfg.variables):-1:1
            if ~valid(jsamp)
                cfg.variables(2,:)=[];
            end
        end
    end
end

%% RUN IF TABLE
% Check if data is provided for one or several participants
% If input is a table then assume its one participant and return the outcome
if isa(data,'table')
    cfg.multipleparticipants = 0;

    data_grid = gridify_table(cfg,data);
    out=data_grid;
    return;
end

%% RUN IF SINGLE TABLE IN STRUCT
% If a struct of size 1 is provided then run that participant and return the
% outcome
if max(size(data))==1
    if ~isa(data(1).data,'table')
        error("STRUCTS ARE ONLY ACCEPTED IF IT IS POPULATED WITH TABLES NAMED 'data'")
    end

    cfg.multipleparticipants = 0;
    data_grid = gridify_table(cfg,data(1).data);
    out=data_grid;
    warning("ONLY ONE PARTICIPANT IN STRUCT, RETURNING GRIDDED DATA FOR THIS PARTICIPANT");
    return;
end

%% RUN IF MULTIPLE TABLES IN STRUCT
% If a struct contains multiple participants, then run and return outcome
% for all
cfg.multipleparticipants = 1;

for samp_i = 1:max(size(data))
    data_grid(samp_i).data = gridify_table(cfg,data(samp_i).data);
end
data_c = struct2cell(data_grid);
data_t = vertcat(data_c{:});

% Add participant count variable
pcount_v = table({'participant'},{'participantcount'},{'unique'},'VariableNames',{'in','out','calculation'});
cfg.variables = vertcat(cfg.variables,pcount_v);

% Index combined data table
[data_g,~,idx] = unique(data_t(:,1:3),'rows');

% Calculate variables over combined table.
% The COUNT calculation is hereby changed to @sum, as a second length index would not work.
data_g = gridify_perform_variable_calculations(cfg,data_t,data_g,idx);

% Add final lat/lon/alt
[data_g.lat,data_g.lon,data_g.alt] = ecef2geodetic(cfg.spheroid,data_g.x,data_g.y,data_g.z);

%% MAIN FUNCTION END
out = data_g;

end

%% FUNCTION TO PERFORM THE IDENTIFIED VARABLIE CALCULATIONS
%Loop over all variable cfgs, and use the data_t vs data_g to perfrom the
%identified calculation. Uses @sum instead of @length on
%multipleparticipants to get the total count, instead of the count of
%counts
function out = gridify_perform_variable_calculations(cfg,data_t,data_g,idx)
for samp_v = 1:height(cfg.variables)
    if strcmp(cfg.variables.calculation{samp_v},'mean')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@mean);
    elseif strcmp(cfg.variables.calculation{samp_v},'unique')
        data_g.(cfg.variables.out{samp_v}) = groupsummary(data_t.(cfg.variables.in{samp_v}),idx,"numunique");
    elseif strcmp(cfg.variables.calculation{samp_v},'count')
        if cfg.multipleparticipants
            data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@sum);
        else
            data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@length);
        end
    elseif strcmp(cfg.variables.calculation{samp_v},'sum')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@sum);
    elseif strcmp(cfg.variables.calculation{samp_v},'min')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@min);
    elseif strcmp(cfg.variables.calculation{samp_v},'max')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@max);
    end
end
out = data_g;
end

%% FUNCTION TO IDENTIFY THE VARIABLES TO GRIDIFY
function out = gridify_identify_variables(data)
warning('Variables and calculations have not been defined, calculating MEAN for ALL variables apart from lat/lon');

%Add all variables apart from Lat & Lon to the list of variables to calculate
varCount = 1;
for isamp = 1:length(data.Properties.VariableNames)
    if max(strcmp(data.Properties.VariableNames{isamp},{'lat';'lon';'long';'alt';'z';'y';'x'})) == 0
        cfg.variables(varCount) = struct('in',data.Properties.VariableNames{isamp},'out',data.Properties.VariableNames{isamp},'calculation','mean');
        varCount = varCount+1;
    end
end
cfg.variables(varCount) = struct('in','lat','out','count','calculation','count');

out = struct2table(cfg.variables);
end


%% FUNCTION TO SMOOTH GRIDDED GPS DATA
%THIS FUNCTION IS NOT YET PROPERLY TESTED, AND DOESNT ALWAYS WORK WELL, USE
%WITH CAUTION, FUNCTION DOESNT YET WORK AS INTENDED, DOESNT CALCULATE Z
%POSITION EITHER, AND IS PRETTY SLOW, PREFERRED METHOD IS TO SMOOTH WHEN 
% VISUALIZING USING GEODENSITYPLOT
function out = gridify_smooth_data (cfg,data)
%Get variables required for setting up the grid
x = data.x;
y = data.y;
dataPoints = height(data);
variableGrids = [];
gridsize.x = max(x)-min(x);
gridsize.y = max(y)-min(y);

%Run over all variables, skipping the ones for latg/long
for samp_v = 1:length(data.Properties.VariableNames)
    if max(strcmp(data.Properties.VariableNames{samp_v},{'y';'x';'lat';'lon';'alt'})) == 0

        %Make a grid out of the existing variables data, with zeros
        %where no data exists
        v = data.(data.Properties.VariableNames{samp_v});
        variableGrid=zeros(gridsize.x,gridsize.y);
        for isamp = 1:dataPoints
            xpos = x(isamp)-min(x);
            ypos = y(isamp)-min(y);
            variableGrid(xpos+1,ypos+1) = v(isamp);
        end

        %Smooth the data and store the new grid
        if isfield(cfg,'smoothwindow')
            smoothenedGrid = smoothdata2(variableGrid,cfg.smoothwindow);
        else
            smoothenedGrid = smoothdata2(variableGrid);
        end
        variableGrids.(data.Properties.VariableNames{samp_v}) = smoothenedGrid;
    end
end

%Retrieve and setup struct with available variables
gridFields = fieldnames(variableGrids);
data_smoothened = [];
data_smoothened.x = [];
data_smoothened.y = [];
for samp_v = 1:length(gridFields)
    data_smoothened.(gridFields{samp_v}) = [];
end

%Loop over all grid points
for samp_x = 1:gridsize.x
    for samp_y = 1:gridsize.y
        %Check if any of the variables have non-zero values at that
        %position
        sampleFound = false;
        for samp_v = 1:length(gridFields)
            if variableGrids.(gridFields{samp_v})(samp_x,samp_y) >0
                sampleFound = true;
            end
        end

        %If thereare values found, add to the structure
        if sampleFound
            data_smoothened.x = [data_smoothened.x;min(x)+(samp_x-1)];
            data_smoothened.y = [data_smoothened.y;min(y)+(samp_y-1)];
            for samp_v = 1:length(gridFields)
                data_smoothened.(gridFields{samp_v}) = [data_smoothened.(gridFields{samp_v});variableGrids.(gridFields{samp_v})(samp_x,samp_y)];
            end
        end
    end
end

%Convert back to table for further processing
out = struct2table(data_smoothened);
end

%% FUNCTION RUN THE GRIDDING CALCULATIONS ON A PER-TABLE BASIS
function out = gridify_table(cfg,data)

%% CHECK DATA & CFG
if ~isfield(data,'alt')
    data.alt = zeros(height(data),1);
end

%% CALCULATE GRID
% Setup the projection method
spheroid = cfg.spheroid;

% Calculate the grid values
if sum(any(["x";"y";"z"]== string(data.Properties.VariableNames)))~=3
    %calculate x y z offset
    [data.x, data.y, data.z] = geodetic2ecef(spheroid,data.lat, data.lon, data.alt);

    % round based on gridsize
    data.x = round(data.x / cfg.gridsize) * cfg.gridsize;
    data.y = round(data.y / cfg.gridsize) * cfg.gridsize;
    data.z = round(data.z / cfg.gridsize) * cfg.gridsize;
end

%% CALCULATE UNIQUE GRID POSITIONS
% get unique lat long values
[data_g,~,idx] = unique(data(:,width(data)-2:width(data)),'rows');

%% PERFORM VARIABLE CALCULATIONS
% Use the defined calculation method to calculate the gridded data over the
% defined variables, and store them using the preferred output name
data_g = gridify_perform_variable_calculations(cfg,data,data_g,idx);

%% SMOOTH DATA
%If smoothing is enabled, run the smooth Data function
if ~strcmp(cfg.smoothmethod,'none')
    data_g = gridify_smooth_data(cfg,data_g);
end

%% CALCULATE LAT / LONG
[data_g.lat,data_g.lon,data_g.alt] = ecef2geodetic(spheroid,data_g.x,data_g.y,data_g.z);

%% FUNCTION END
% copy all gridded data over to the output
out = data_g;
end

