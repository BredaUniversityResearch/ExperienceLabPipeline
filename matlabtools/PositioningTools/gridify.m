function out = gridify(cfg,data)
%% GRIDIFY SINGLE
% function out = gridify (cfg,data)
%
% *DESCRIPTION*
% The gridify function can take a table, or structure with several tables,
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
% cfg.smoothmethod = (OPTIONAL) smoothing method applied over the gridded
%   data, possible to choose from:'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'
%   default = 'none' 
%   THIS FEATURE IS STILL BEING TESTED, ONLY USE THIS IF YOU ARE AWARE OF
%   THE LIMITATIONS
% cfg.spheroid = (OPTIONAL) type of sphere used for reprojecting the data
%   from lat/lon
%   default = wgs84Ellipsoid("m");
% cfg.variables = (OPTIONAL) table with calculations performed over the
%   selected data, colums must be: 'in', 'out', 'calculation', where in is
%   the name of the data-column, out is the name in the output data, and
%   calculation is the calculation to perform over the data inside that
%   grid point.
%   calculation methods = min, max, unique, count, mean, sum
%   default = mean calculation for all data columns except 'lat';'lon';'alt'
% 
% Data Requirements
% There are 3 options:
% 1. Table containing a lat & lon column as well as at least one
%    additional number-based column. An alt column is adviced but optional.
% 2. Structure with at least a single table field as described in option 1
%    called data
% 3. Structure array with at least a single table field as described in 
%    option 1 called data for every row in the structure array.
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
%    separate the participants
% 2. See if we can replace the calculations in RUN IF MULTIPLE PARTICIPANTS
%    with a call to gridify_single, skipping the gridding, and replacing
%    variables with a count to a sum
% 3. Config option to output combined & per-participant gridded data?
% 4. Config option to define the table name in the data struct

%% CHECK CFG AND DATA FOR ALL PARTICIPANTS
% Check data format
if isa(data,'table')
    %check for lat & lon/long names
end    
if isstruct(data)
    % check for lat & lon/long names for all participants
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

% Check if variables calculation exist, if not setup new based on the first participant
if isstruct(data)
    if ~isfield(cfg,'variables')
        warning('Variables and calculations have not been defined, calculating MEAN for ALL variables apart from lat/lon');

        % Add all variables apart from Lat & Lon to the list of variables to calculate
        varCount = 1;
        for samp_i = 1:length(data(1).data.Properties.VariableNames)
            if max(strcmp(data(1).data.Properties.VariableNames{samp_i},{'lat';'lon';'long';'alt'})) == 0
                cfg.variables(varCount) = struct('in',data(1).data.Properties.VariableNames{samp_i},'out',data(1).data.Properties.VariableNames{samp_i},'calculation','mean');
                varCount = varCount+1;
            end
        end
        cfg.variables(varCount) = struct('in','lat','out','count','calculation','count');

        cfg.variables = struct2table(cfg.variables);
    end

    % Check individual participants in struct on available variables
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
    data_grid = gridify_single(cfg,data);
    out=data_grid;
    return;
end

%% RUN IF SINGLE PARTICIPANT
% If a struct of size 1 is provided then run that participant and return the
% outcome
if max(size(data))==1
    data_grid = gridify_single(cfg,data(1).data);
    out=data_grid;
    warning("ONLY ONE PARTICIPANT IN STRUCT, RETURNING GRIDDED DATA FOR THIS PARTICIPANT");
    return;
end

%% RUN IF MULTIPLE PARTICIPANTS
% If a struct contains multiple participants, then run and return outcome
% for all

for samp_i = 1:max(size(data))
    data_grid(samp_i).data = gridify_single(cfg,data(samp_i).data);
end
data_c = struct2cell(data_grid);
data_t = vertcat(data_c{:});

% Add participant count variable
vNew = table({'participant'},{'participantcount'},{'unique'},'VariableNames',{'in','out','calculation'});
cfg.variables = vertcat(cfg.variables,vNew);

% Index combined data table
[data_g,~,idx] = unique(data_t(:,1:3),'rows');

% Calculate variables over combined table
for samp_v = 1:height(cfg.variables)
    if strcmp(cfg.variables.calculation{samp_v},'mean')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@mean);
    elseif strcmp(cfg.variables.calculation{samp_v},'unique')
        data_g.(cfg.variables.out{samp_v}) = groupsummary(data_t.(cfg.variables.in{samp_v}),idx,"numunique");
    elseif strcmp(cfg.variables.calculation{samp_v},'count')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@sum);
    elseif strcmp(cfg.variables.calculation{samp_v},'sum')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@sum);
    elseif strcmp(cfg.variables.calculation{samp_v},'min')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@min);
    elseif strcmp(cfg.variables.calculation{samp_v},'max')
        data_g.(cfg.variables.out{samp_v}) = accumarray(idx,data_t.(cfg.variables.in{samp_v}),[],@max);
    end
end

% Add final lat/lon/alt
[data_g.lat,data_g.lon,data_g.alt] = ecef2geodetic(cfg.spheroid,data_g.x,data_g.y,data_g.z);

%% FUNCTION END
out = data_g;

end
