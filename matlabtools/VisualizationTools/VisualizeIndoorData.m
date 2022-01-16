function out = VisualizeIndoorData(data,cfg)
% This function uses the ExperienceLabPipeline provided data format, and
% configuration file, to create a figure with a heatmap showing the
% accumilated data on the map
% 
% DATA
%   You can either provide the data, or the directory of the datafile
%
% CONFIG
%   cfg.mapfile = location of map image file
%   cfg.mapmeta = location of map xlsx metadata
%   cfg.datatype = datatype to represent in the heatmap (z value), must be
%       a character array with the same name as a character array in the data
%       file
%   cfg.participants = 'all', or an array with values of all participants
%       to include
%   cfg.gridsize = size of the grid in meters
%
% Wilco Boode 14/01/2022

%% SETUP VALUES
disp('SETUP START');
clear;
cfg.datafile = '\2.ProcessedData\data_final.mat';
cfg.mapname = '\1.Scripts&Tools\map2.png';
cfg.mapmeta = '\0.RawData\MapMeta.xlsx';
cfg.datatype = 'phasic';
cfg.participants = 'all';
cfg.gridsize = 1;

%% DIRECTORY
disp('DIRECTORY START');

%Get project directory, make sure the CURRENT FOLDER in MATLAB is the
%1.Scripts&Tools folder inside the PROJECT FOLDER
mydir  = pwd
idcs   = strfind(mydir,'\')
pdir = mydir(1:idcs(end)-1)

%load final data
load([pdir,cfg.datafile]);

if (class)

%% FORMAT DATA
disp('FORMAT START');

%Restructure data for easier use later on
if (strcmp(cfg.participants,'all'))
    data_segment = data_final;
else
    data_segment = data_final(cfg.participants);
end

data = [];
x = [];
y = [];
for i=1:length(data_final)-1
    x = [x;data_final(i).x];
    y = [y;data_final(i).z_inv];
    data = [data;flip(rot90(data_final(i).(cfg.datatype)))];
end

%% IMPORT MAP
disp('MAP START');

% Load the map meta data 
mapmeta = readtable([pdir,cfg.mapmeta],"VariableNamingRule","preserve");

%load the image file, and get the sizes for later bounding
picture = imread([pdir,cfg.mapname]);
[pheight,pwidth,pdepth] = size(picture);

%setup a grid for grouping and managing data over the size of the map
pgrid(pheight,pwidth) = struct('data',[]);

%calculate the size per gridcell
xsize = ((mapmeta.x_max-mapmeta.x_min)/pwidth);
ysize = ((mapmeta.z_max-mapmeta.z_min)/pheight);

%% BIN DATA
xInterv = mapmeta.x_min:gridsize:mapmeta.x_max;
yInterv = mapmeta.z_min:gridsize:mapmeta.z_max;

bindata = rot90(flip(x));
[xData,xE] = discretize(bindata,xInterv);

bindata = rot90(flip(y));
[yData,yE] = discretize(bindata,yInterv);

dt = table(flip(rot90(data)),xData,yData,'VariableNames',{'data';'x';'y'});


%% ACCUMILATE DATA
[uxy, ~, uidx] = unique([dt.x(:), dt.y(:)], 'rows');
avgv = accumarray(uidx, dt.data(:), [], @length);
output = [uxy, avgv];


%% FIX NAN VALUES
output(isnan(output)) = 0;


%% CREATE OUTPUT
x=output(:,1)/(xsize/cfg.gridsize);
y=output(:,2)/(ysize/cfg.gridsize);
v=output(:,3);
[xq,yq] = meshgrid(0:1:pwidth,0:1:pheight);

figure;
image(picture);
hold on
gdata = griddata(x,y,v,xq,yq,'natural');
imagesc(gdata,'AlphaData',0.5);
hold off
end