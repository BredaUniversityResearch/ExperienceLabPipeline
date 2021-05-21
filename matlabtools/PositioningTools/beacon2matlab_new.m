function out  = beacon2matlab_new(cfg)
%function to load, separate, and smoothen iBeacon data from our own
%iBeacon app.
%
%The function outputs a single structure containing:
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
%configuration options are
%
%cfg.datafolder =   String value specifying the lcoation of the beaconFile.
%                   Note that for matlab-internal reasons you have to
%                   specify double backslashes in the path
%cfg.beaconfile =   String value specifying the name of the file containing
%                   the beacon data
%cfg.nullvalue =    integere value determining the minimum value that can
%                   be received (for creating NaN values)
%cfg.smoothen =     boolean (true/false), if true, then the output data
%                   will be smoothened (default = true);
%cfg.smoothingFactor = The factor with which the smoothing will take place
%                   (Higher is more aggresive smoothing, default = 0.2)
%cfg.smoothingMethod = The method which is applied for smoothing. The
%                   methods can be found in the smoothdata() function.
% Wilco Boode: 31-01-2018

%PLACE EXACT DESCRIPTION FOR MATLAB PROGRAMMERS HERE

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

%save the current directory, and open the datafolder containing the actual
%data
curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

%read eda data from file
[num, txt, raw] = xlsread(cfg.beaconfile);

%erase string indicators, split data in separate strings, and dicect the
%array into a final matrix, as well as an array struct
numerase = erase(raw,'"');
datestr(now,'yyyy-mm-dd HH:MM:SS');

for isamp=2:size(numerase)
    numsplit = strsplit(numerase{isamp},',');
    
    rData.UUID(isamp-1) = numsplit(1,1);
    rData.MAJOR(isamp-1) = numsplit(1,2);
    rData.MINOR(isamp-1) = numsplit(1,3);
    rData.DISTANCE(isamp-1) = numsplit(1,4);
    rData.RSSI(isamp-1) = numsplit(1,5);
    rData.TXPOWER(isamp-1) = numsplit(1,6);
    rData.TIME{isamp-1} = datetime(datevec(numsplit{1,7}), 'Format', 'yyyy-MMM-dd HH:mm:ss');
    if isfield(cfg,'startingdifference')
        rData.TIME{isamp-1} = rData.TIME{isamp-1} + seconds(cfg.startingdifference);
    end
    
    %data.TIME{isamp-1} = datetime(datestr(numsplit{1,7}, 'yyyy-mm-dd HH:MM:SS'));
    
    for nsamp=1:length(numsplit)
        nummatrix{(isamp-1),nsamp} = numsplit{1,nsamp};
    end
end

%Set the initial time stamps in both Matlab / human readable format, and
%UNIX code*
initial_time_stamp_mat = rData.TIME{1};
initial_time_stamp = posixtime(initial_time_stamp_mat);
txpower = rData.TXPOWER(1);

%Calculate the total duration (seconds) and create array of seconds(time)
d2s = 24*3600;    % convert from days to seconds
d1  = d2s*datenum(rData.TIME{length(rData.TIME)}); %get datenum of max time
d2  = d2s*datenum(rData.TIME{1}); %get starting datenum
tDiff = d1-d2; %get difference between start and max
time = flip(rot90(0:tDiff+1)); % create array of time

%cycle through all beacon data to organize it in the correct location
cTime = 0;
bData.time = time;
bData.time2 = rot90(time);
beacons = {};
for isamp=1:length(rData.UUID)
    
    %get the time & name of the current beacon point (Major+Minor)
    d1 = d2s*datenum(rData.TIME{1,isamp});
    cTime = int16((d1-d2)+1);
    cBeacon = string(char("b"+string(rData.MAJOR{1,isamp})+"_"+string(rData.MINOR{1,isamp})));
    
    %check if there is a field for this beacon, if not create one of
    %required length(time) and add name to beacons list
    if ~isfield(bData, cBeacon)
        bData.(cBeacon) = NaN((length(time)),1);
        beacons = [beacons,cBeacon];
    end
    
    %Store the current RSSI value (signal strength) at the current time
    %point
    bData.(cBeacon)(cTime) = str2num(rData.RSSI{1,isamp});
end

beacons = flip(rot90(beacons));

%go through all organized beacons, inverse data, remove 0 values, then
%smoothen and remove values too low for proper position data.
for isamp=1:length(beacons)
    beacon = beacons{isamp,1};
    new = bData.(beacon);
    newM = -new;
    newM(newM == 0) = NaN;
    if cfg.smoothen == true
        newM = smoothdata(newM,cfg.smoothingmethod,'omitnan','SmoothingFactor',cfg.smoothingfactor);
    end
    newM(newM< cfg.nullvalue) = NaN;
    sData.(beacon) = newM;
end

%make sure only the necessary data is outputted
out = sData;
out.beaconnames = beacons;
out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.fsample = 1;
out.time = time;
out.timeoff = 0;
out.orig = cfg.datafolder;
out.datatype = "ibeacon";

end