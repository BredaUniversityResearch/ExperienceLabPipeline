function out  = getoutdoorpoi(cfg,data)
%% GET OUTDOOR POI
% function out = getoutdoorpoi (cfg,data)
%
% *DESCRIPTION*
%This function can be used to check wheter a datapoint is
%inside of a specific point of interest. This can be used in outdoor
%projects to calculate the measures of data based on their position.
%To run this data, the location of a poifile will be necessary, this is a
%geojson file, containing features, where each feature has the point of that poi
%
% *INPUT*
%Configuration Options
%cfg.datafolder     = the folder where the POI data files are stored
%cfg.poifile        = the name of the poi geojson
%
%Data Requirements
%data.lat = array with latitude positions
%data.long = array with longitude positions of same length as data.lat
%
% *OUTPUT*
%Outputs the 
%
% *NOTES*
%poifile
%The POIs are easiest to create using a GeoJson editor, such as: https://geojson.io/
%The file should be saved using the geojson format.
%Every feature requires a "name" variable, which will be used to set the poi name in the
%datastructure.
%The current function calculates single dimension POIs, meaning there can
%be no overlapping POIs, as there is only one map to draw on. If necessary, this can be altered in
%the future.
%
% *BY*
%Wilco 02/07/2021

%% DEV INFO
%This function works by:
%1. retrieving the geojson file containing all POI areas
%2. comparing all lat/lon points in the data file to polygons created with the geojson file


%% VARIABLE CHECK
if ~isfield(cfg, 'datafolder')
    error('getoutdoorPOI: datafolder not specified');
end
if ~isfield(cfg, 'poifile')
    warning('getoutdoorPOI: poi json not specified, using default name');
    cfg.poifile = 'poi.geojson';
end
if ~isfield(data, 'lat')
    error('getoutdoorPOI: lat value of data not defined');
end
if ~isfield(data, 'long')
    error('getoutdoorPOI: long value of data not defined');
end

%% LOAD DATA
%Load POI json file
fname = strcat(cfg.datafolder,cfg.poifile);
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
jsondata = jsondecode(str);

%% RETRIEVE POIS
% get all pois from the json data, and store it in a separate structure for easy access
amount = length(jsondata.features);

pois = [];
for i = 1:amount
    name = jsondata.features(i).properties.name;
    lat = jsondata.features(i).geometry.coordinates(:,:,2);
    long = jsondata.features(i).geometry.coordinates(:,:,1);

    %Store colorcode and corresponding boundaries for every POI
    pois.(name).lat = lat;
    pois.(name).long = long;    
end

%% CHECK POSITIONS VS POIS
%Calculate which of the points are inside of the different POIs, and store
%this in individual tables
     
poinames = fieldnames(pois);

%Go over all POIs to calculate whether dat is inside them
for i = 1:length(poinames)
    curname = cell2mat(poinames(i));
    curpois = pois.(curname);
    pois.(curname).inside = false(1,length(data.lat));
    
    %For each boundary in the POI, compare it to the x,z position of the
    %data using inpolygon to get a list of all points inside the boundarie,
    %then save this in the POI inside field
    %for k = 1:length(curpois)
        [in,~] = inpolygon(data.long,data.lat,curpois.long,curpois.lat);

        %[in,~] = inpolygon(data.x*x_ppm,data.z*z_ppm,boundary(:,2), boundary(:,1));
        
        pois.(curname).inside = max(in,pois.(curname).inside);
    %end
end
%% CREATE OUTPUT
%Create a list with the current POI, to create a list of easy to recognize POI values
     
currentpoi = strings(length(data.lat),1);

%Go over all POIs to see whether there is a point inside them
for i = 1:length(poinames)
    curname = cell2mat(poinames(i));
    for j = 1:length(data.lat)
        if (pois.(curname).inside(j) == 1)
            currentpoi(j) = string(curname);
        end            
    end
end

%% FUNCTION END
%create the output structure
out = data;
out.poidata = pois;
out.currentpoi = currentpoi;
end