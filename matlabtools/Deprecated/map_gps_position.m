function out = map_gps_position (cfg, data)
%THIS FUNCTION IS BASICALLY DEPRECATED NOW WE USE KEPLER.GL

%Width Visualization. Providing only the minwidth will set the width to
%that size. For custom with, provide the data, min, and max
%cfg.widthdata
%cfg.minwidth
%cfg.maxwidth

%Color Visualization. Providing only the colorstart will set the visuals to
%that color. For custom color, provide the data, start, and end
%cfg.colordata
%cfg.colorstart
%cfg.colorend
map = figure;

%clearvars -except segmented_strava

%Data required for the width representation. 1 = the widthdata itself (list
%of data floats). Then the starting and the ending width.
%data = segmented_strava;
%cfg.widthdata = data.power;
%cfg.widthmin = 4;
%cfg.widthmax = 5;

%Data required for the color representation. 1 = the colordata itself (list
%of data floats). Then the starting and the ending colour.
%cfg.colordata = data.power;
%cfg.colorstart = [0 1 0];
%cfg.colorend = [1 0 0];

%Use the Geo Variables for displaying background information for the player
%such as shapefiles, GEOTIFF files, or a GoogleMaps based background
%cfg.datafolder = 'C:\data\Ondrej\Gina\GeoDataLocation';
%cfg.geotif = 'NL_GeoTiff_EPSG4326.tif';
%cfg.geotfw = 'NL_GeoTiff_EPSG4326.tfw';
%cfg.polyfile = 'Polygons.shp';
%cfg.linefile = 'Lines.shp';
%cfg.pointfile = 'Point.shp';
%cfg.googlemaps = 'yes';

%cfg.northarrow = 'yes';

curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

lat = rot90(fliplr(data.lat));
lon = rot90(fliplr(data.long));

latmin = min(lat);
latmax = max(lat);
lonmin = min(lon);
lonmax = max(lon);
latlim = [latmin latmax];
lonlim = [lonmin lonmax];

%Uses the min and max in the colordata list to create a complete range
%within the colors. An offset can be applied (min and Max) to filter
%between two % values. This list is then store to be applied later on.
if isfield (cfg, 'colordata')
    colormin = min(cfg.colordata);
    colormax = max(cfg.colordata);
    colordiff = colormax - colormin;
    minoffset = (colordiff/100)*cfg.minoffset;
    maxoffset = (colordiff/100)*cfg.maxoffset;
    newcolormin = colormin+minoffset;
    newcolormax = colormax-(colormax-maxoffset);
    newcolordiff = newcolormax - newcolormin;
    colorlist = [];
    for i=1:length(cfg.colordata) 
        if ~isnan(cfg.colordata(i))
        if cfg.colordata(i) < newcolormin
               colorlist = [colorlist; 0];
        elseif cfg.colordata(i) > newcolormax
               colorlist = [colorlist; 1];
        else
             colorlist = [colorlist; (cfg.colordata(i)-newcolormin) / newcolordiff];
        end
        else
            colorlist = [colorlist; 0];
        end
    end
else
    thisColor = cfg.colorstart;
end

%Width To Visualize. Sets a width based on the Maximum Width, Minimum
%Width, and the actual data in the list of data to be respresented on the
%Width of the line
if isfield (cfg, 'widthdata')
    widthmin = min(cfg.widthdata);
    widthmax = max(cfg.widthdata);
    widthdiff = widthmax - widthmin;
    widthlist = [];
    for i=1:length(cfg.widthdata)
        widthlist = [widthlist; cfg.widthmin+(((cfg.widthdata(i)-widthmin) / widthdiff)*(cfg.widthmax-cfg.widthmin))];
    end
else
    thisWidth = cfg.widthmin;
end

%Checks for a possible GEOTIFF file, and puts this in the background
if isfield (cfg, 'geotif')
    [geotiff cmap]= geotiffread(cfg.geotif);
    R = worldfileread(cfg.geotfw);
    mapshow(geotiff, R);
end
%Checks for the presence of Shapefiles in the CFG file, and represends them
%with corresponding colours and sizes
if isfield (cfg, 'polyfile')
    polyfile = shaperead(cfg.polyfile);
    mapshow(polyfile, 'Linewidth', 0.5, 'FaceColor', [1.0 1.0 1.0], 'DefaultEdgeColor',[1 1 1]);
end
if isfield (cfg, 'linefile')
    linefile = shaperead(cfg.linefile);
    mapshow(linefile,'LineStyle',':', 'Color','black');
end
if isfield (cfg, 'pointfile')
    pointfile = shaperead(cfg.pointfile);
    mapshow(pointfile,'Marker','o','MarkerEdgeColor','black','MarkerSize',5);
end


%Goes over the entire Color and Width list, and creates a line with colours
%and width based on these lists (created earlier)
thisColor = [1 1 0];
for i=1:length(lat)-1
    curlat = [lat(i) lat(i+1)];
    curlon = [lon(i) lon(i+1)];
    if exist ('colorlist')
        thisColor = [colorlist(i) 1-colorlist(i) 0];
    end
    if exist ('widthlist')
        thisWidth = widthlist(i);
    end
    geoshow(curlat, curlon,'Linewidth', thisWidth, 'DisplayType', 'line', 'Color', thisColor);
end

%Checks whether there is a struct "Text" in the CFG, if so, then it places
%the text based on the Lat Lon Positions in that same struct. The text is
%black with a white background. This comes on top of all other elements.
if isfield (cfg, 'text')
        text(cfg.text.lon, cfg.text.lat, cfg.text.value,'Color', [0 0 1], 'BackgroundColor', [1 1 1]);
end

%Checks whether the GoogleMaps should be used for the background, if so
%then it uses the plot_google_maps.m file for plotting maps on the existing
%figure
if isfield (cfg, 'googlemaps') 
    if cfg.googlemaps == 'yes'
        plot_google_map()
    end
end

if isfield(cfg, 'ruler')
    scaleruler on
    scaleruler('units', cfg.ruler);
end

if isfield (cfg, 'camerazoomlevel') 
    camzoom(cfg.camerazoomlevel);
    cfg.camerazoomlevel
end

if isfield (cfg, 'northarrow') 
    if cfg.northarrow == 'yes'
        northarrow('latitude', -50, 'longitude', 5);
    end
end

%Sets the side Axis, and the Title of the Plot
axis([lonmin lonmax latmin latmax])
if isfield (cfg, 'plotname')
    title(cfg.plotname);
else
    title('GeoTiff');
end

out = map;

end