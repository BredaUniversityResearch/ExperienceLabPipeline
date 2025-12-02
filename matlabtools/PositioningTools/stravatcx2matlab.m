function out = stravatcx2matlab(cfg)
%% STRAVA TCX 2 MATLAB
%function out = stravatcx2matlab(cfg)
%
% *DESCRIPTION*
%function to read Strava data (which can be used to record outdoor walking and
%biking movement. This data can be collected using the strava app, and
%downloaded as a TCX file from the strava website: 
% https://support.strava.com/hc/en-us/articles/216918437-Exporting-your-Data-and-Bulk-Export#TCX
%
% *INPUT*
%Configuration Options
%cfg.stravafile = string specifying the file that contains the Strava data
%                 in tcx fomat. This is the default strava format using
%                 /export_tcx
%cfg.originaltimezone = string specifying the Time Zone the data was measured in
%cfg.newtimezone = string specifying the Time Zone it should be measured in
%cfg.datafolder = string containing the full path to the folder with the
%                 strava data. double backlashes have to be specified due 
%                 to matlab-internal reasons
%
% *OUTPUT*
%Single structure containing the following info:
%fsample = 1;
%time
%lat
%lon
%altitude
%distance
%speed = NA
%speed2 = NA
%power = NA
%
% *NOTES*
%for the strava measurements, please use the default strava file
%- Retrieve the file via the link in strava, an include "/export_tcx" in the
%  url
%
% *BY*
%Wilco Boode 17/06/2022

%% DEV INFO
%during the latest update, the full importer has been replaced by the
%matlab XML import functions. Also, the way data is being altered into a
%linear structure has been overhauled to better catch possible missing
%datapoints.

%% VARIABLE CHECK
%set defaults
if ~isfield(cfg, 'datafolder')
    error('strava2matlab: datafolder not specified');
end
if ~isfield(cfg, 'stravafile')
    cfg.stravafile = 'strava.tcx';
end
if ~isfield(cfg, 'originaltimezone')
    cfg.originaltimezone = 'GMT';
end
if ~isfield(cfg, 'newtimezone')
    cfg.newtimezone = datetime('now', 'TimeZone', 'local').TimeZone;
    warning(strcat('TimeZone not specified. Using local TimeZone: ',cfg.newtimezone));
end


%% READ DATA
%save the current directory, and open the datafolder containing the actual
%data
% curdir = pwd;
% cd(cfg.datafolder)

%read strava data from file, if file does not exist, look for other .tcx
%files and suggest these instead
if isfile(fullfile(cfg.datafolder, cfg.stravafile))
    file = readstruct(fullfile(cfg.datafolder, cfg.stravafile),'FileType','xml');
else
    fileList = dir(fullfile(cfg.datafolder, '*.tcx'));
    disp(strcat(cfg.stravafile,' Not Found'));
    if ~isempty(fileList)
        for f=1:length(fileList)
            
            prompt = strcat('Do you want want to use "',fileList(f).name,'"? y/n [n]: ');
            usenamefromlist = input(prompt,'s');
            if isempty(usenamefromlist)
                usenamefromlist = 'n';
            end
            
            if usenamefromlist == 'y'
                cfg.stravafile = fileList(f).name;
                
                file = readstruct(fullfile(cfg.datafolder, cfg.stravafile),'FileType','xml');
                break
            end
        end
    else
        error('Strava File Not Found');
    end
end

data.initial_time_stamp_mat = file.Activities.Activity.Lap.StartTimeAttribute;
data.initial_time_stamp_mat = replace(data.initial_time_stamp_mat,"T"," ");
data.initial_time_stamp_mat = replace(data.initial_time_stamp_mat,"Z","");
data.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat,'TimeZone',cfg.originaltimezone,'Format', 'yyyy-MM-dd HH:mm:ss' );
data.initial_time_stamp_mat = string(data.initial_time_stamp_mat);

%% CREATE STRUCTURE
%Create data arrays with all necessary data from the files
trackdata = file.Activities.Activity.Lap.Track.Trackpoint;
offsets = zeros(length(trackdata),1);
for i = 1:length(trackdata)
    t=trackdata(i).Time;
    t=replace(t,"T"," ");
    t=replace(t,"Z","");
    t=datetime(t);
    offset = etime(datevec(t),datevec(datetime(data.initial_time_stamp_mat)));
    offsets(i)=offset;
end

data.time = linspace(0,max(offsets),max(offsets)+1)';
data.lat = NaN(max(offsets)+1,1);
data.lon = NaN(max(offsets)+1,1);
data.altitude = NaN(max(offsets)+1,1);
data.distance = NaN(max(offsets)+1,1);
data.speed = zeros(max(offsets)+1,1);
data.speed2 = zeros(max(offsets)+1,1);
data.power = zeros(max(offsets)+1,1);

%% PLACE DATA IN STRUCTURE
for i = 1:length(trackdata)
    data.lat(offsets(i)+1) = trackdata(i).Position.LatitudeDegrees;
    data.lon(offsets(i)+1) = trackdata(i).Position.LongitudeDegrees;
    data.altitude(offsets(i)+1) = trackdata(i).AltitudeMeters;
    data.distance(offsets(i)+1) = trackdata(i).DistanceMeters;
end

data.lat = fillmissing(data.lat,'previous');
data.lon = fillmissing(data.lon,'previous');
data.altitude = fillmissing(data.altitude,'previous');
data.distance = fillmissing(data.distance,'previous');

newdatetime = datetime(data.initial_time_stamp_mat,'TimeZone',cfg.originaltimezone,'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
newdatetime.TimeZone = cfg.newtimezone;
data.initial_time_stamp_mat = newdatetime;%string(newdatetime);
data.initial_time_stamp = posixtime(datetime(data.initial_time_stamp_mat));

%% CREATE OUTPUT
%make sure only the necessary data is collected int eh out struct
out.initial_time_stamp = data.initial_time_stamp;
out.initial_time_stamp_mat = data.initial_time_stamp_mat;
out.fsample = 1;
out.time = data.time;
out.lat = data.lat;
out.lon = data.lon;
out.altitude = data.altitude;
out.distance = data.distance;
out.speed = data.speed;
out.speed2 = data.speed2;
out.power = data.power;
out.datatype = "strava";

end