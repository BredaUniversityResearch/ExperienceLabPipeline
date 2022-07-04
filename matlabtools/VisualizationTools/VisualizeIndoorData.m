function out = VisualizeIndoorData(data,cfg)
%% EXAMPLE VALUES
clear;
cfg = [];
data = 'G:\BUas\602012 - Experience Lab - Cxxxxxx - Markiezenhof - Cxxxxxx - Markiezenhof\EmpaticaProject\2.ProcessedData\data_final.mat';
cfg.mapname = 'G:\BUas\602012 - Experience Lab - Cxxxxxx - Markiezenhof - Cxxxxxx - Markiezenhof\EmpaticaProject\1.Scripts&Tools\map2.png';
cfg.mapmeta = 'G:\BUas\602012 - Experience Lab - Cxxxxxx - Markiezenhof - Cxxxxxx - Markiezenhof\EmpaticaProject\0.RawData\MapMeta.xlsx';
cfg.transparency = 0.5;
cfg.datatype = 'phasic';
cfg.participants = 'all';
cfg.participants = [1,4,7,28,34];
cfg.gridsize = 2;
cfg.calculation = @length;

%% CONFIG INFO
% This function uses the ExperienceLabPipeline provided data format, and
% configuration file, to create a figure with a heatmap showing the
% accumilated data on the map
%
% DATA
%   You can either provide the data, or the directory of the datafile
%
% CONFIG
%   cfg.mapname = location of map image file
%   cfg.mapmeta = location of map xlsx metadata
%   cfg.datatype = datatype to represent in the heatmap (z value), must be
%       a character array with the same name as a character array in the data
%       file
%   cfg.participants = 'all', or an array with values of all participants
%       to include
%   cfg.gridsize = size of the grid in meters
%   cfg.calculation = the function used (mean, max, min, length)
%
% Wilco Boode 21/01/2022

%% TO DO
% Make it smoother. Perhaps fill rest of the grid with 0 values for
% smoother interpolation?

%% VARIABLE SETUP
disp('SETUP START');

if ~exist(data)
	error('Data not provided, cancelling visualization');
end
if ~isfield(cfg,'mapname')
    error('Mapfile not provided, cancelling visualization');
end
if ~isfield(cfg,'mapmeta')
    error('MapMeta not provided, cancelling visualization');
end
if ~isfield(cfg,'datatype')
    cfg.datatype = 'phasic';
    warning('DatatType not provided, using default (phasic)');
end
if ~isfield(cfg,'transparency')
    cfg.transparency = 0.5;
end
if ~isfield(cfg,'participants')
    cfg.participants = 'all';
end
if ~isfield(cfg,'gridsize')
    cfg.gridsize = 1;
end
if ~isfield(cfg,'calculation')
    cfg.calculation = @length;
    warning('Calculation not provided, using default (@length)');
end

%% CHECK & IMPORT DATA
disp('DATA CHECK START');
data = 'G:\BUas\602012 - Experience Lab - Cxxxxxx - Markiezenhof - Cxxxxxx - Markiezenhof\EmpaticaProject\2.ProcessedData\data_final.mat';

%Check if the data is just a char, if so use this to load the data
if class(data) == 'char'
    if isfile(data)        
        data = load(data);
        datanames = fieldnames(data);
        data = data.(datanames{1});
        clear(datanames{1});
    else
        error('THE SUGGESTED DATAFILE DOES NOT EXIST');
    end
end

%check if the data file contains the required structural elements
%(x,y,datatype), and if all are of equal length
valid = 1;
for i=1:length(data)
    len = 0;
    lensame = 1;
    if ~isfield(data(1),'x')
        warning(strcat('Participant: ', int2str(i), ' has no x column'));
        valid = 0;
    else
        len = length(data(1).x);
    end
    if ~isfield(data(1),'y')
        warning(strcat('Participant: ', int2str(i), ' has no y column'));
        valid = 0;
    else
        if ~length(data(1).y) == len
            valid = 0;
            lensame = 0;
        end
    end
    if ~isfield(data(1),cfg.datatype)
        warning(strcat('Participant: ', int2str(i), ' has no: ',cfg.datatype,' column'));
        valid = 0;
    else
        if ~length(data(1).(cfg.datatype)) == len
            valid = 0;
            lensame = 0;
        end
    end
    if (lensame == 0)
        warning(strcat('Data in participant: ', int2str(i), ' is not the same in the required columns'));
    end
end

if valid == 0
    error('Provided data is not valid, please check warnings and fix the indicated issues');
end

%% FORMAT DATA
disp('FORMAT START');

%Combine participants to be used in this visualization
data_final = [];
if (strcmp(cfg.participants,'all'))
    data_final = data;
else
    p =cell2mat({data.participant});
    for i = 1:length(cfg.participants)
        ind=find(p==cfg.participants(i));
        if ~isempty(ind)
            data_final = [data_final;data(ind)];
        else
            warning(strcat('Participant: ', int2str(cfg.participants(i)), ' does not exist')); 
        end
    end
end

%Gather all data in one long matrix for easier aggregation
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
mapmeta = readtable(cfg.mapmeta,"VariableNamingRule","preserve");

%load the image file, and get the sizes for later bounding
picture = imread(cfg.mapname);
[pheight,pwidth,~] = size(picture);

%calculate the size per gridcell
xsize = ((mapmeta.x_max-mapmeta.x_min)/pwidth);
ysize = ((mapmeta.z_max-mapmeta.z_min)/pheight);

%% EDIT DATA
disp('EDIT DATA');

%Create a interval array for the x and y values of the final grid
xInterv = mapmeta.x_min:cfg.gridsize:mapmeta.x_max;
yInterv = mapmeta.z_min:cfg.gridsize:mapmeta.z_max;

%Reassign x and y values to intervals
bindata = rot90(flip(x));
[xData,~] = discretize(bindata,xInterv);
bindata = rot90(flip(y));
[yData,~] = discretize(bindata,yInterv);

%Create table out of new x and y values, settin data to correct grid position
dt = table(flip(rot90(data)),xData,yData,'VariableNames',{'data';'x';'y'});

%Create list of unique xy values, and accumulate the data values for these
%locations using the desired method (Average, Total, Max, Min, etc.)
[uxy, ~, uidx] = unique([dt.x(:), dt.y(:)], 'rows');
avgv = accumarray(uidx, dt.data(:), [], cfg.calculation);

%Combine the unique XY values & Accumulated data
output = [uxy, avgv];

%Remove NAN values. Still need to determine whether to set to 0 or
%completely omit NAN rows
%output(isnan(output)) = 0;
output(any(isnan(output), 2), :) = [];

%% CREATE OUTPUT
disp('CREATE OUTPUT');

%Separate table 
x=output(:,1)/(xsize/cfg.gridsize);
y=output(:,2)/(ysize/cfg.gridsize);
v=output(:,3);

%Create x y grid
[xq,yq] = meshgrid(0:cfg.gridsize:pwidth,0:cfg.gridsize:pheight);

%%Rescale the image based on gridsize, then plot the background image
figure;
image(imresize(picture,1/cfg.gridsize));
hold on

%Create v based grid, and plot as transparent image on top of the
%background
gdata = griddata(x,y,v,xq,yq,'natural');
imagesc(gdata,'AlphaData',cfg.transparency);

hold off
end