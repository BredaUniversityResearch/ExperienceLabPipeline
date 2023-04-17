function out = strava2matlab(cfg)
%function to ready in Strava data (which can be used to record outdoor walking and
%biking movement.
%
%The configuration options are:
%cfg.stravafile = string specifying the file that contains the Strava data
%                 in CSV fomat. This is the default strava format + one 
%                 extra column for speed2
%cfg.originaltimezone = string specifying the Time Zone measured in
%cfg.newtimezone = string specifying the Time Zone it should be measured in
%cfg.datafolder = string containing the full path to the folder with the
%                 strava data. double backlashes have to be specified due 
%                 to matlab-internal reasons
%
%for the strava measurements, please use the default strava file
%- Retrieve the file via the link in strava, an include "/export_tcx" in the
%  file
%- Open the file in excel, ignore all warnings, they dont matter, then save
%  as CSV
%Wilco Boode 19-11-2018

%set defaults
if ~isfield(cfg, 'stravafile')
    cfg.stravafile = 'strava.csv';
end
if ~isfield(cfg, 'originaltimezone')
    cfg.originaltimezone = 'GMT';
end
if ~isfield(cfg, 'newtimezone')
    cfg.newtimezone = 'Europe/Amsterdam';
end
if ~isfield(cfg, 'datafolder')
    error('strava2matlab: datafolder not specified');
end

%save the current directory, and open the datafolder containing the actual
%data
curdir = pwd;
cd(cfg.datafolder)

%read strava data from file
[num, txt, raw] = xlsread(cfg.stravafile);

%Create data arrays with all necessary data from the files
data.initial_time_stamp = raw(3,2);
data.time = rot90(fliplr(raw(2:end,10)'));
data.lat = cell2mat(rot90(fliplr(raw(2:end,11)')));
data.long = cell2mat(rot90(fliplr(raw(2:end,12)')));
data.altitude = cell2mat(rot90(fliplr(raw(2:end,13)')));
data.distance = cell2mat(rot90(fliplr(raw(2:end,14)')));
data.speed = cell2mat(rot90(fliplr(raw(2:end,15)')));

data.mydatetime = [];

%Set Easy to use DateTime Values
nsamp = size(data.time,1);
count = 1;
for isamp=1:nsamp 
    newdatetime = [data.mydatetime;datetime(extractBefore(data.time(isamp),"T") + " " +extractAfter(extractBefore(data.time(isamp),"Z"),"T"),'TimeZone',cfg.originaltimezone,'Format', 'yyyy-MM-dd HH:mm:ss' )];
    newdatetime.TimeZone = cfg.newtimezone;
    data.mydatetime = newdatetime;
end

% create new data structuresfor all output data
time = [];
mydatetime = [];
lat = [];
long = [];
altitude = [];
distance = [];
speed = [];
speed2 = [];
power = [];

nsamp = length(data.time);
for isamp=1:nsamp 
    mydatetime = [mydatetime;data.mydatetime(isamp)];
    lat = [lat;data.lat(isamp)];
    long = [long;data.long(isamp)];
    altitude = [altitude;data.altitude(isamp)];
    distance = [distance;data.distance(isamp)];
    speed = [speed;data.speed(isamp)];
    speed2 = [speed2;data.speed(isamp)*3.6];
    time = [time;length(mydatetime)-1];
    cfg = [];
    cfg.timeinseconds = 1;
    cfg.speed = data.speed(isamp)*3.6;
    
    if (isamp > 1)
       cfg.verticalgain = data.altitude(isamp)- data.altitude(isamp-1);
    end
    
    power = [power;calculatebikingpower(cfg)];

    if (isamp < nsamp)      
        d2s = 24*3600;
        cur = datenum(data.mydatetime(isamp));
        next = datenum(data.mydatetime(isamp+1));
        tCur = d2s*datenum(data.mydatetime(isamp));
        tNext = d2s*datenum(data.mydatetime(isamp+1));
        tDiff = tNext-tCur;        
        if tDiff > 1            
            for tFill = 1:tDiff-1
                    mydatetime = [mydatetime;data.mydatetime(isamp)+seconds(tFill)];
                    lat = [lat;data.lat(isamp)];
                    long = [long;data.long(isamp)];
                    altitude = [altitude;data.altitude(isamp)];
                    distance = [distance;data.distance(isamp)];
                    speed = [speed;0];
                    speed2 = [speed2;0];
                    time = [time;length(mydatetime)-1];
                    power = [power;calculatebikingpower(cfg)];
            end
        end
    end
end

%create an altered / correct time stamp 
initial_time_stamp = posixtime(mydatetime(1));
initial_time_stamp_mat = mydatetime(1);

%make sure only the necessary data is collected int eh out struct
out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.fsample = 1;
out.time = time;
out.lat = lat;
out.long = long;
out.altitude = altitude;
out.distance = distance;
out.speed = speed;
out.speed2 = speed2;
out.power = power;
out.datatype = "strava";

end