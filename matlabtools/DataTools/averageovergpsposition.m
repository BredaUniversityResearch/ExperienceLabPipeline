function out = averageovergpsposition(data,cfg)
%% AVERAGE OVER GPS POSITION
% function out = default_structure (cfg,data)
%
% *DESCRIPTION*
% AverageOverGPSPosition averages ExpLab formatted participant data based
% on their Lat and Long values. This function will output data in a way
% which can more easily be used in software such as Kepler.gl, which cannot
% handle the large csv files that are usually generated on a p.p. basis.
% The function requires a data structure, and cfg specifying the data types 
% to average. It looks for the total range of the GPS data, and creates a 
% grid of predefined size per grid-point. 
% The signals of the participants are then mapped to this grid, and a mean
% is used on each grid cell to get the mean value of all values mapped to
% that point. This is output to create a list of averaged values with lan
% long values based on the designated grid cell.
%
% *INPUT*
%Configuration Options
%cfg.gridsize = (OPTIONAL) the size of the grid sections in meters
%           default = 10;
%cfg.datatypes =   a list containing the names of the data that should be
%           averaged, these need to be number based.
%
%Data Requirements
%data = a structure, containing all participants, where every participant 
%           has least the lat, long and at least 1 number based data type. 
%           all lists/arrays need to be of equal length.
%
% *OUTPUT*
%A structure containing all grid positions and their mean values per 
%datatype.
%
% *NOTES*
%NA
%
% *BY*
% Wilco Boode, 16-04-2021

%% VARIABLE CHECK
%check whether the gridsize is specified
if ~isfield(cfg, 'gridsize')
    cfg.gridsize = 10;
end
%check whether the gridsize is specified
if ~isfield(cfg, 'datatypes')
    error('averageovergpsposition: datatypes not specified');
end

%% DEFINE GPS POSITIONS
%define min and max lat/lon positions
lat_min = NaN;
lon_min = NaN;
lat_max = NaN;
lon_max = NaN;

%loop over all participants, and find the highest and lowest lat/lon
for p =1:length(data)
    pdata = data(p);
    
    if isnan(lat_min)
        lat_min = min(pdata.lat);
        lon_min = min(pdata.long);
        lat_max = max(pdata.lat);
        lon_max = max(pdata.long);
    else
        if (min(pdata.lat)<lat_min)
            lat_min = min(pdata.lat);
        end
        if (min(pdata.long)<lon_min)
            lon_min = min(pdata.long);
        end
        if (max(pdata.lat)>lat_max)
            lat_max = max(pdata.lat);
        end
        if (max(pdata.long)>lon_max)
            lon_max = max(pdata.long);
        end
    end
end

%calculate the size of the gps area in meters
positionsize = latlon2meter(lat_min,lon_min,lat_max,lon_max);
gridsize = cfg.gridsize;

size_lat = abs(round(positionsize.lat/gridsize));
size_lon = abs(round(positionsize.lon/gridsize));

%% GENERATE MATRIX FOR EVERY DATATYPE AND POPULATE WITH DATA
%generate a matrix containing a value for lat,lon, and every datatype in
%the cfg.datatypes list
mx =[];
for x =1:size_lon
    for z = 1:size_lat
        pos = meter2latlon(lat_min,lon_min,x*gridsize,z*gridsize);
        
        mx(z,x).lat = pos.lat;
        mx(z,x).lon = pos.lon;
        
        for type = 1:length(cfg.datatypes)
            mx(z,x).(cfg.datatypes(type)) = [];
        end
    end
end

% For every participant, calculate the gridposition of every entry, and add
% the values of the datatypes to the indicated gridposition
for p =1:length(data)
    
    pdata = data(p);
    
    for i =1:length(pdata.lat)
        p_point = latlon2meter(lat_min,lon_min,pdata.lat(i),pdata.long(i));
        p_lat = bound(abs(round(p_point.lat/gridsize)),1,size_lat);
        p_lon = bound(abs(round(p_point.lon/gridsize)),1,size_lon);
        
        for type = 1:length(cfg.datatypes)
            mx(p_lat,p_lon).(cfg.datatypes(type)) = [mx(p_lat,p_lon).(cfg.datatypes(type));pdata.(cfg.datatypes(type))(i)];
        end
    end
end

%% CREATE AND OUTPUT THE FINAL STRUCTURE
%create a final structure containing all grid positions containing data
d = 1;
for x =1:size_lon
    for z = 1:size_lat
        if (mx(z,x).(cfg.datatypes(1)) > 0)
            dd.lat = mx(z,x).lat;
            dd.lon = mx(z,x).lon;
            for type = 1:length(cfg.datatypes)
                dd.(cfg.datatypes(type)) = mean(mx(z,x).(cfg.datatypes(type)));              
            end
            data_out(d) = dd;
            d = d+1;
        end
    end
end

out = data_out;
end
