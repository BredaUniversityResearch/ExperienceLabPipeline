function out  = getindoorpoi(cfg,data)
%The getindoorpoi function can be used to measure wheter a datapoint is
%inside of a specific point of interest. This can be used in indoor
%projects to calculate the measures of data based on their position.
%The data required to run this process are MapMeta, POIMeta, and a Map. 
%The current function calculates single dimension POIs, meaning there can
%be no overlapping POIs, as there is only one map to draw on.
%
%Data
%The data file can be the default EXP Lab participant structure. All it
%requires is an X and a Z value, for the horizontal, and the depth data.
%You can also send a data struct with only these two values
%
%CFG
%cfg.datafolder     = the folder where the POI data files are stored
%cfg.poifile        = the name of the poimetafile containing POI rgb values and name
%cfg.mapfile        = the name of the map including the POI areas, should be a .png file. You can
%define multiple map files if you want overlapping POIs, all of these map files can use the same
%color if you want them to use the same POI, however they files need to be the same size, as they
%will share metafiles for now.
%cfg.mapmetafile    = the name of the xlsx file containing meta data on the map (sizes)
%cfg.zname          = the name of the array to use for the z value (as matlab uses inversed order
%from many other tools, including our beacon tools (0 = top)
%cfg.colorleeway    = amount of leeway allowed in the RGB colors, to take compression artifacts into
%account. This value is in RGB units
%
%Wilco 08/02/2021

%%
%This function works by:
%1. Getting a map image, and calculating the corresponing scale
%2. Transforming the map into separate binary data files (black-white) masked by the colors of the
%POIs
%3. Getting the boundaries of every POI, allowing every POI to contain more than one area
%4. Treating every boundary as a polygon to calculate whether the datapoints are inside these areas

%%
if ~isfield(cfg, 'datafolder')
    error('getindoorPOI: datafolder not specified');
end
if ~isfield(cfg, 'poifile')
    warning('getindoorPOI: poimeta not specified, using default name');
    cfg.poifile = 'poimeta.xlsx';
end
if ~isfield(cfg, 'mapfile')
    warning('getindoorPOI: mapfile not specified, using default name');
    cfg.mapfile = "map.png";
end
if ~isfield(cfg, 'mapmetafile')
    warning('getindoorPOI: mapmetafile not specified, using default name');
    cfg.mapmetafile = 'mapmeta.xlsx';
end
if ~isfield(data, 'x')
    error('getindoorPOI: X value of data not defined');
end
if ~isfield(data, 'z')
    error('getindoorPOI: Z value of data not defined');
end
if ~isfield(cfg, 'zname')
    cfg.zname = 'z';
end
if ~isfield(cfg, 'colorleeway')
    cfg.colorleeway = 5;
end

%%
% Load map image, and define the scale values for map to real life scale 
I = imread(strcat(cfg.datafolder,cfg.mapfile));

mapmeta = readtable(strcat(cfg.datafolder,cfg.mapmetafile));

x_min = mapmeta.x_min;
x_max = mapmeta.x_max;
x_size = abs(x_min - x_max);
z_min = mapmeta.z_min;
z_max = mapmeta.z_max;
z_size = abs(z_min - z_max);

m_size = size(I);
x_ppm = m_size(2) / x_size;
z_ppm = m_size(1) / z_size;

%%
%Use the POITable to find all POI Color Areas on the map, and store the
%pois on a per color basis
poitable = readtable(strcat(cfg.datafolder,cfg.poifile));

pois = [];
for i = 1:height(poitable)
    %Make mask for current poi, and only keep the pixels with the colors of the
    %current POI. Utilizes ColorLeeway to alow for offsets due to image compression
    mask = (I(:, :, 1) >= poitable.r(i)-cfg.colorleeway & I(:, :, 1) <= poitable.r(i)+cfg.colorleeway) & (I(:, :, 2) >= poitable.g(i)-cfg.colorleeway & I(:, :, 2) <= poitable.g(i)+cfg.colorleeway) & (I(:, :, 3) >= poitable.b(i)-cfg.colorleeway & I(:, :, 3) <= poitable.b(i)+cfg.colorleeway);
    maskedRgbImage = bsxfun(@times, I, cast(mask, 'like', I));
    
    %Create a binary image from the masked image
    grey = rgb2gray(maskedRgbImage);
    BW = imbinarize(grey);
    
    %Calculate boundaries from the Binary Image
    [B,~] = bwboundaries(BW,'noholes');
    
    %Store colorcode and corresponding boundaries for every POI
    pois.(cell2mat(poitable.name(i))).colorcode = [poitable.r(i) poitable.g(i) poitable.b(i)];
    pois.(cell2mat(poitable.name(i))).boundaries = B;    
end

%%
%Calculate which of the points are inside of the different POIs, and store
%this in individual tables
     
poinames = fieldnames(pois);

%Go over all POIs to calculate whether dat is inside them
for i = 1:length(poinames)
    curname = cell2mat(poinames(i));
    curpois = pois.(curname).boundaries;
    pois.(curname).inside = false(length(data.x),1);
    
    %For each boundary in the POI, compare it to the x,z position of the
    %data using inpolygon to get a list of all points inside the boundarie,
    %then save this in the POI inside field
    for k = 1:length(curpois)
        boundary = curpois{k};
        [in,~] = inpolygon(data.x*x_ppm,data.(cfg.zname)*z_ppm,boundary(:,2), boundary(:,1));
        
        pois.(curname).inside = max(in,pois.(curname).inside);
    end
end
%%
%Create a list with the current POI, to create a list of easy to recognize POI values
     
currentpoi = strings(length(data.x),1);

%Go over all POIs to see whether there is a point inside them
for i = 1:length(poinames)
    curname = cell2mat(poinames(i));
    for j = 1:length(data.x)
        if (pois.(curname).inside(j) == 1)
            currentpoi(j) = string(curname);
        end            
    end
end

%%
%create the output structure
out = data;
out.poidata = pois;
out.currentpoi = currentpoi;
end

%%
%FEATURE ENHANCEMENT OPTIONS
%cfg.usemap - Option to either define map data, polygon data, or area data
