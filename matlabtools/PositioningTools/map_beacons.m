function out = map_beacons(cfg, data)
%% NAME OF FUNCTION
% function out = map_beacons(cfg, data)
%
% *DESCRIPTION*
%This function loads in combined data, and using user provided argument (in
%the cfg plots this data on a map). This particular script is written for
%beacon data, but can be expended for other data.
%The Script outputs the final map (it also saves the map in the participant
%folder) and all variables combined for future combinations of all data.
%
% *INPUT*
%Configuration Options
%cfg.participantFolder =    String of the participant data folder position
%cfg.beacondataFolder =     String of the folder containing overall beacon info
%cfg.sizeStart =            Num Value of the starting size of the points
%cfg.sizeMultiplier =       Num Value of the multiplication factor for the
%cfg.intensityType =        string for the calculations used on the beacon data
%cfg.sampleVariable =       From the datasource, what variable should be used
%for the point color (conductance, phasic, distance)
%cfg.beaconFile =           String name& format of the file with beacon info
%cfg.mapFile =              String name & format of the map file. This map file
%
%Data Requirements
%requires data to be formatted the way we do with the experiencelab
%pipeline
%
% *OUTPUT*
%map.png file with the plotted data
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode

%% DEV INFO
%This function is pretty old, but seems to have some relevance still.
%Should probably make a couple of visualization options and use this as a
%wrapper around it in the future.

%% VARIABLE CHECK
%check if all required CFG fields are available, if not then generate them
if ~isfield(cfg, 'participantFolder')
    warning('PARTICIPANT FOLDER NOT FOUND, MAP WILL NOT BE AUTOMATICALLY SAVED');
end
if ~isfield(cfg, 'beacondataFolder')
    warning('BEACONDATAFOLDER NOT FOUND, CANNOT RETRIEVE BEACON POSITION DATA');
end
if ~isfield(cfg, 'sizeStart')
    cfg.sizeStart = 50;
end
if ~isfield(cfg, 'sizeMultiplier')
    cfg.sizeMultiplier = 0.2;
end
if ~isfield(cfg, 'intensityType')
    cfg.intensityType = 'mean';
end
if ~isfield(cfg, 'sampleVariable')
    cfg.sampleVariable = 'conductance';
end
if ~isfield(cfg, 'beaconFile')
    cfg.beaconFile = 'beaconPositions.xlsx';
end
if ~isfield(cfg, 'mapFile')
    cfg.mapFile = 'Map.tif';
end

%Move to the overall data folder, and load the map using imshow
eval(sprintf('cd %s', cfg.beacondataFolder));
imshow(cfg.mapFile)

%Read the beacon position data
beaconPos = xlsread(cfg.beaconFile);
minor = beaconPos(1:size(beaconPos),1);
x = beaconPos(1:size(beaconPos),2);
y = beaconPos(1:size(beaconPos),3);

%Generate arrays for saving the samples, intensity, seconds and pointsize
%in
[allSamples{1:length(beaconPos)}] = deal([]);
[intensity{1:length(beaconPos)}] = deal(0);
[seconds{1:length(beaconPos)}] = deal(0);
[pointsize{1:length(beaconPos)}] = deal(1);

%Grab all data from the sampleVariable array and past it in the array
%struct of the correct beacon
for  i = 1:length(data.minor)
    if ~(isnan(data.minor(i)))
        for  j = 1:length(minor)
            if minor(j) == data.minor(i)
                allSamples{j} = [allSamples{j} data.(cfg.sampleVariable)(i)];
            end
        end
    end
end

%for every beacon calculate: Total seconds, how to interpret the sample
%data, and the size the point should have (based on the seconds and sizes)
for  i = 1:length(minor)
    if ~(isnan(allSamples{i}))
        seconds{i} =  length(allSamples{i})/data.fsample;
        
        if strcmp(cfg.intensityType,'max')
            intensity{i} = max(allSamples{i});
        elseif strcmp(cfg.intensityType,'mean')
            intensity{i} = mean(allSamples{i});
        elseif strcmp(cfg.intensityType,'min')
            intensity{i} = min(allSamples{i});
        elseif strcmp(cfg.intensityType,'mode')
            intensity{i} = mode(allSamples{i});
        elseif strcmp(cfg.intensityType,'median')
            intensity{i} = median(allSamples{i});
        end
        
        if seconds{i} > 0
            pointsize{i} = cfg.sizeStart + (seconds{i}*cfg.sizeMultiplier);
        end
    end
end

hold on

%Alter the data to the correct format & orientation
pointsize = cell2mat(pointsize);
intensity  = cell2mat(intensity);
pointsize = transpose(pointsize);
intensity = transpose(intensity);

%Place the points on top of the map. Use Colormap type Jet. Add the
%Index for the Sample Data (Color)
scatter(x,y,pointsize,intensity,'filled');
colormap('jet');
colorbar;

%Open participant folder and save the map in this folder
if isfield(cfg, 'participantFolder')
    eval(sprintf('cd %s', cfg.participantFolder));
    saveas(gcf,'Map_Data.png');
end

out.map = gcf;
out.allSamples = allSamples;
end