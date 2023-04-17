function out  = beacon2matlab_unix(cfg)
%% NAME OF FUNCTION
% function out = beacon2matlab_unix (cfg)
%
% *DESCRIPTION*
%function to load, separate, and smoothen iBeacon data from our own
%iBeacon app using the Experiencelab Beacon App (Using UNIX Time). 
%
% *INPUT*
%Configuration Options
%cfg.datafolder =   String value specifying the lcoation of the beaconFile.
%                   Note that for matlab-internal reasons you have to
%                   specify double backslashes in the path
%cfg.beaconfile =   String value specifying the name of the file containing
%                   the beacon data
%cfg.beaconDataFolder =     String value specifying the lcoation of the meta
%                           data of the Beacons.
%cfg.beaconPositions =      Name of the file containing information
%                           regarding the position & number of the beacons
%                           used during this project.
%cfg.nullvalue =    integere value determining the minimum value that can
%                   be received (for creating NaN values)
%cfg.smoothen =     boolean (true/false), if true, then the output data
%                   will be smoothened (default = true);
%cfg.smoothingFactor = The factor with which the smoothing will take place
%                   (Higher is more aggresive smoothing, default = 0.2)
%cfg.smoothingMethod = The method which is applied for smoothing. The
%                   methods can be found in the smoothdata() function.
%cfg.movemean =     whether you want to use a moving mean to get smoother 
%                   data (default = true)
%cfg.movemeanduration = duration of the moving mean factor. longer duration
%                   equals a smoother dataset, but can cause missed
%                   touchpoints for short visits (default = 60);
% cfg.timezone      = string specifying the timezone the data was collected
%                     in, your local timezone will be used  if you dont
%                     specify anything. You can find all possible timezones
%                     by running the following command: timezones 
%
% *OUTPUT*
%A single struct containing:
%out BeaconRSSI     = An array for each beacon consisting of beaconData        
%                     (RSSI Signal) on a per-second scale.
%out.beaconnames    = Names of all beacons found in the file
%out.initial_time_stamp = Unix Code Time Stamp (Start of File)
%out.initial_time_stamp_mat = Human readable Time Stamp (Start of File)
%out.fsample        = Sample Frequency (1hz)
%out.time           = Array of all time stamps (should be 1 per second)
%out.timeoff        = Time off from starting time (most likely 0);
%out.datatype       = Name of Data type = 'beacon';
%
% *NOTES*
%Additional information about the function, for example if parts have been
%retrieved from an online source
%
% *BY*
% Wilco Boode: 15-04-2020

%% DEV INFO
%There are some old functions (rot90(flip())) in here, should clean it up a
%bit and check if all still works

%% VARIABLE CHECK
if ~isfield(cfg, 'beaconDataFolder')
    error('beaconNearestPosition: beaconDataFolder not specified');
end
if ~isfield(cfg, 'beaconPositions')
    warning('beaconNearestPosition: name of beacon position file not specified, using default');
    cfg.beaconPositions = 'BeaconPositions.xlsx';
end
if ~isfield(cfg, 'beaconMeta')
    warning('beaconNearestPosition: name of beacon metadata file not specified, using default');
    cfg.beaconMeta = 'BeaconMeta.xlsx';
end
if ~isfield(cfg, 'datafolder')
    error('beacon2matlab: datafolder not specified');
end
if ~isfield(cfg, 'beaconfile')
    warning('beacon2matlab: beaconfile not specified, using default name');
    cfg.beaconfile = 'beacondata.csv';
end
if ~isfield(cfg, 'nullvalue')
    warning('nullvalue: value not specified, using default value (40)');
    cfg.nullvalue = 40;
end
if ~isfield(cfg, 'smoothen')
    cfg.smoothen = true;
end
if ~isfield(cfg, 'smoothingfactor')
    cfg.smoothingfactor = 0.2;
end
if ~isfield(cfg, 'smoothingmethod')
    cfg.smoothingmethod = 'gaussian';
end
if ~isfield(cfg, 'movemean')
    cfg.movemean = true;
end
if ~isfield(cfg, 'movemeanduration')
    cfg.movemeanduration = 60;
end
if ~isfield(cfg, 'movemeanduration')
    cfg.movemeanduration = 60;
end
%check whether a timezone is specific, if not give warning and use local /
%current
if ~isfield(cfg, 'timezone')
    cfg.timezone = datetime('now', 'TimeZone', 'local').TimeZone;
    warning(strcat('TimeZone not specified. Using local TimeZone: ',cfg.timezone));
end

%save the current directory, and open the datafolder containing the actual
%data
curdir = pwd;
cd(cfg.datafolder)
%eval(sprintf('cd %s', cfg.datafolder));

%% SETUP STRUCTURE AND VARIABLES
%Create variables & set data for beaconMeta data, based on project
%position & known ID / Major_Minor_UUID
positionTable = readtable(strcat(cfg.beaconDataFolder,cfg.beaconPositions));

positionTable.Major = NaN(length(positionTable.BeaconID),1);
positionTable.Minor = NaN(length(positionTable.BeaconID),1);
positionTable.UUID = string(NaN(length(positionTable.BeaconID),1));
positionTable.cBeacon = string(NaN(length(positionTable.BeaconID),1));

%Read and Store Metadata from Beacons
metaTable = readtable(strcat(cfg.beaconDataFolder,cfg.beaconMeta));
for isamp=1: height(metaTable)
    for jsamp=1: height(positionTable)
        if (metaTable.BeaconID(isamp) == positionTable.BeaconID(jsamp,1))
            positionTable.Major(jsamp,1) = metaTable.Major(isamp);
            positionTable.Minor(jsamp,1) = metaTable.Minor(isamp);
            positionTable.UUID(jsamp,1) = metaTable.UUID(isamp);
            positionTable.cBeacon(jsamp,1) = string(char("b"+string(metaTable.Major(isamp))+"_"+string(metaTable.Minor(isamp))));
            break
        end
    end
end

%% READ AND ORGANIZE DATA
%read beacon data from file
beaconTable = readtable(strcat(cfg.datafolder,cfg.beaconfile));

%erase string indicators, split data in separate strings, and dicect the
%array into a final matrix, as well as an array struct

beaconTable.Properties.VariableNames = {'UUID' 'MAJOR' 'MINOR' 'DISTANCE' 'RSSI' 'TXPOWER' 'TIME'};

rData.UUID = beaconTable(:,1);
rData.MAJOR = beaconTable(:,2);
rData.MINOR = beaconTable(:,3);
rData.DISTANCE = beaconTable(:,4);
rData.RSSI = beaconTable(:,5);
rData.TXPOWER = beaconTable(:,6);
rData.TIME = beaconTable(:,7);

%Set the initial time stamps in both Matlab / human readable format, and
%UNIX code*

beaconTable.TIME(1)
initial_time_stamp = beaconTable.TIME(1);%str2double(cell2mat(beaconTable.TIME(1)));
initial_time_stamp_mat = datetime(initial_time_stamp,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone',cfg.timezone);
%initial_time_stamp_mat = datetime(datestr(unixmillis2datenum(initial_time_stamp*1000), 'dd-mmm-yyyy HH:MM:SS'));
txpower = beaconTable.TXPOWER(1);

%Calculate the total duration (seconds) and create array of seconds(time)
d2s = 24*3600;    % convert from days to seconds
d1  = beaconTable.TIME(height(beaconTable));%str2double(cell2mat(beaconTable.TIME(height(beaconTable)))); %get datenum of max time
d2  = beaconTable.TIME(1);%str2double(cell2mat(beaconTable.TIME(1)));%get starting datenum
tDiff = d1-d2; %get difference between start and max
time = flip(rot90(0:tDiff)); % create array of time

%cycle through all beacon data to organize it in the correct location
cTime = 0;
bData.time = time;
bData.time2 = rot90(time);
beacons = {};

%create array for every beacon in project (defined in beaconMeta)
for isamp = 1: height(positionTable)
    cBeacon = string(char("b"+string(positionTable.Major(isamp,1))+"_"+string(positionTable.Minor(isamp,1))));
    if ~isfield(bData, cBeacon)
        bData.(cBeacon) = NaN((length(time)),1);
        beacons = [beacons,cBeacon];
    end
end

for isamp=1:height(beaconTable)
    
    %get the time & name of the current beacon point (Major+Minor)
    d1 = beaconTable.TIME(isamp);%str2double(cell2mat(beaconTable.TIME(isamp)));%%d2s*datenum(rData.TIME{1,isamp});
    cTime = int16((d1-d2)+1);
    cBeacon = string(char("b"+string(beaconTable.MAJOR(isamp))+"_"+string(beaconTable.MINOR(isamp))));
    
    %check if there is a field for this beacon, if not create one of
    %required length(time) and add name to beacons list
    if ~isfield(bData, cBeacon)
        warning("beacon does not exist: " + cBeacon + ". add it to beaconPositions if it was used during the project");        
    end
    
    %Store the current RSSI value (signal strength) at the current time
    %point
    bData.(cBeacon)(cTime) = beaconTable.RSSI(isamp); % str2double(beaconTable.RSSI(isamp));
end

beacons = flip(rot90(beacons));

%% DATA CLEANING
%go through all organized beacons, inverse data, remove 0 values, then
%smoothen using smoothdata, and movmean and remove values too low for proper position data.
for isamp=1:length(beacons)
    beacon = beacons{isamp,1};
    new = bData.(beacon);
    newM = -new;
    newM(newM == 0) = NaN;
    if cfg.smoothen == true
        newM = smoothdata(newM,cfg.smoothingmethod,'omitnan','SmoothingFactor',cfg.smoothingfactor);
    end
    if cfg.movemean == true
        newM = movmean(newM,60,'omitnan');
    end
    newM(newM< cfg.nullvalue) = NaN;
	beaconvalues.(beacon) = newM;        
end

%% CREATE OUTPUT
%make sure only the necessary data is outputted
out = [];
out.beaconvalues = beaconvalues;
out.beaconnames = beacons;
out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.fsample = 1;
out.time = time;
out.beaconMeta = positionTable;
out.timeoff = 0;
out.orig = cfg.datafolder;
out.datatype = "ibeacon";
end