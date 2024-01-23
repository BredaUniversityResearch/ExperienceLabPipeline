function out = gridify_single(cfg,data)
%% GRIDIFY SINGLE
% function out = gridify_single (cfg,data)
%
% *DESCRIPTION*
%Gridify_single takes a single table, containing a lat,lon and additional
%number-based columns and outputs a grid-based representation of this
%data. By default all additional number-based columns will return a mean
%value for that position, unless the desired calculations are
%defined in cfg.variables.
%
% *INPUT*
%A table containing a column for lat,lon, and any amount of number-based
%columns. An alt column can be added, if not this will be automatically
%calculated. All configuration options are optional.
%
%Configuration Options
%cfg.gridsize = (OPTIONAL) the size of the calculation grid in meters
%    default = 20
%cfg.smoothmethod = (OPTIONAL) smoothing method applied over the gridded
%   data, possible to choose from:'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'
%   default = 'none' 
%   THIS FEATURE IS STILL BEING TESTED, ONLY USE THIS IF YOU ARE AWARE OF
%   THE LIMITATIONS
%cfg.spheroid = (OPTIONAL) type of sphere used for reprojecting the data
%   from lat/lon
%   default = wgs84Ellipsoid("m");
%cfg.variables = (OPTIONAL) table with calculations performed over the
%   selected data, colums must be: 'in', 'out', 'calculation', where in is
%   the name of the data-column, out is the name in the output data, and
%   calculation is the calculation to perform over the data inside that
%   grid point.
%   calculation methods = min, max, unique, count, mean, sum
%   default = mean calculation for all data columns except 'lat';'lon';'alt'
% 
%Data Requirements
%data = table containing a lat,lon and additional number-based columns, an
%   alt column is adviced, but not necessary.
%
% *OUTPUT*
%A table containing lat,lon,alt,x,y,z,and separate columns for each
%calculation performed.
%
% *NOTES*
%N/A
%
% *BY*
%Wilco Boode, 09/01/2024

%% DEV INFO
%This function is called by the gridifiy function to calculate individual 
%participant grids.
%ADDITIONAL FEATURES TO ADD:
%1. Implement proper altitude check, current function uses alt=zero if
%   nothing is supplied

%% VARIABLE CHECK
%lat MUST be provided, otherwise its impossible to calculate the grid
if ~any("lat" == string(data.Properties.VariableNames))
    if any("latitude" == string(data.Properties.VariableNames))
        data.lat = data.latitude;
    else
        error('latitude / lat not defined!!!');
    end
end

%lon MUST be provided, otherwise its impossible to calculate the grid
if ~any("lon" == string(data.Properties.VariableNames))
    if any("long" == string(data.Properties.VariableNames))
        data.lon = data.long;
    elseif any("longtitude" == string(data.Properties.VariableNames))
        data.lon = data.longtitude;
    else
        error('Longtitude / lon / long not defined!!!');
    end
end

if ~isfield(cfg,'gridsize')
    warning('gridsze is not defined in the configuration, using default (20)');

    cfg.gridsize = 20;
end

if ~isfield(cfg,'variables')
    warning('Variables and calculations have not been defined, calculating MEAN for ALL variables apart from lat/lon');
    
    %Add all variables apart from Lat & Lon to the list of variables to calculate
    varCount = 1;
    for isamp = 1:length(data.Properties.VariableNames)
        if max(strcmp(data.Properties.VariableNames{isamp},{'lat';'lon';'long';'alt'})) == 0
            cfg.variables(varCount) = struct('in',data.Properties.VariableNames{isamp},'out',data.Properties.VariableNames{isamp},'calculation','mean');
            varCount = varCount+1;
        end
    end
    cfg.variables(varCount) = struct('in','lat','out','count','calculation','count');

    cfg.variables = struct2table(cfg.variables);
end

if ~isfield(cfg,'smoothmethod')
    cfg.smoothmethod = 'none';
elseif max(strcmp(cfg.smoothmethod,{'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'})) == 0
    cfg.smoothmethod = 'movmean';
end

if ~isfield(cfg,'spheroid')
    cfg.spheroid = wgs84Ellipsoid("m");
end

if ~isfield(data,'alt')
    data.alt = zeros(height(data),1);
end

%% CALCULATE GRID
% Setup the projection method 
spheroid = cfg.spheroid;

% Calculate the grid values
if ~any("x" == string(data.Properties.VariableNames))
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
for vsamp = 1:height(cfg.variables)
    if strcmp(cfg.variables.calculation{vsamp},'mean')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data.(cfg.variables.in{vsamp}),[],@mean);
    elseif strcmp(cfg.variables.calculation{vsamp},'unique')
        data_g.(cfg.variables.out{vsamp}) = groupsummary(data.(cfg.variables.in{vsamp}),idx,"numunique");
    elseif strcmp(cfg.variables.calculation{vsamp},'count')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data.(cfg.variables.in{vsamp}),[],@length);
    elseif strcmp(cfg.variables.calculation{vsamp},'sum')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data.(cfg.variables.in{vsamp}),[],@sum);
    elseif strcmp(cfg.variables.calculation{vsamp},'min')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data.(cfg.variables.in{vsamp}),[],@min);
    elseif strcmp(cfg.variables.calculation{vsamp},'max')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data.(cfg.variables.in{vsamp}),[],@max);
    end
end

%% SMOOTH DATA
%This section will smooth the data based on the data gridded so far
if ~strcmp(cfg.smoothmethod,'none')

    %Get variables required for setting up the grid
    x = data_g.x;
    y = data_g.y;    
    z = data_g.z;    
    dataPoints = height(data_g);
    variableGrids = [];
    gridsize.x = max(x)-min(x);
    gridsize.y = max(y)-min(y);

    %Run over all variables, skipping the ones for latg/long
    for vsamp = 1:length(data_g.Properties.VariableNames)
        if max(strcmp(data_g.Properties.VariableNames{vsamp},{'x';'y';'x';'lat';'lon';'alt'})) == 0

            %Make a grid out of the existing variables data, with zeros
            %where no data exists
            v = data_g.(data_g.Properties.VariableNames{vsamp});            
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
            variableGrids.(data_g.Properties.VariableNames{vsamp}) = smoothenedGrid;
        end
    end

    %Retrieve and setup struct with available variables
    gridFields = fieldnames(variableGrids);
    data_smoothened = [];
    data_smoothened.x = [];
    data_smoothened.y = [];
    for vsamp = 1:length(gridFields)
        data_smoothened.(gridFields{vsamp}) = [];
    end

    %Loop over all grid points
    for xsamp = 1:gridsize.x%max(x)
        for ysamp = 1:gridsize.y%max(y)
            %Check if any of the variables have non-zero values at that
            %position
            sampleFound = false;
            for vsamp = 1:length(gridFields)
                if variableGrids.(gridFields{vsamp})(xsamp,ysamp) >0
                    sampleFound = true;
                end
            end
            
            %If thereare values found, add to the structure
            if sampleFound
                data_smoothened.x = [data_smoothened.x;min(x)+(xsamp-1)];
                data_smoothened.y = [data_smoothened.y;min(y)+(ysamp-1)];
                for vsamp = 1:length(gridFields)
                   data_smoothened.(gridFields{vsamp}) = [data_smoothened.(gridFields{vsamp});variableGrids.(gridFields{vsamp})(xsamp,ysamp)];
                end
            end
        end
    end

    %Convert back to table for further processing
    data_g = struct2table(data_smoothened);
end


%% CALCULATE LAT / LONG
[data_g.lat,data_g.lon,data_g.alt] = ecef2geodetic(spheroid,data_g.x,data_g.y,data_g.z);


%% FUNCTION END
% copy all gridded data over to the output
out = data_g;
end