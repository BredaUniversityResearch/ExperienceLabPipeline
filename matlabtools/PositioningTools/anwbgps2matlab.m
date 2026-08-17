function out = anwbgps2matlab(cfg)
%% ANWB GPS 2 MATLAB
%function out = anwbgps2matlab(cfg)
%
% *DESCRIPTION*
% function to read GPS data that has been collected using the ANWB GPS tracker app
%
% *INPUT*
% Configuration Options
% cfg.gpsfile = string specifying the file that contains the gps data
% cfg.originaltimezone = string specifying the Time Zone the data was measured in
% cfg.newtimezone = string specifying the Time Zone it should be measured in
% cfg.datafolder = string containing the full path to the folder with the
%                 strava data. double backlashes have to be specified due 
%                 to matlab-internal reasons
%
% *OUTPUT*
% Single structure containing the following info:
% fsample = 1 ( 1 sample per second)
% time
% lat
% lon
% accuracy
%
%
% *Addapted by Hans Revers 31/03/2026 from 
% stravatcx2matlab.m written by Wilco Boode 17/06/2022 *

%% VARIABLE CHECK
%set defaults
if ~isfield(cfg, 'datafolder')
    warning('anwbgps2matlab: datafolder not specified');
end
if ~isfield(cfg, 'gpsfile')
    warning('anwbgps2matlab: gps file not specified');
end
if ~isfield(cfg, 'originaltimezone')
    cfg.originaltimezone = 'GMT';
end


%% READ DATA
%  save the current directory, and open the datafolder containing the actual data

% read gps data from file, if file does not exist
if isfile(fullfile(cfg.datafolder, cfg.gpsfile))
    file = fullfile(cfg.datafolder, cfg.gpsfile);
    GPStable = readtable(file,'HeaderLines',0,'ReadVariableNames',true);
else
    warning('GPS File Not Found');
end

% the anwb timestamp has 19 digits, unix timestamp in seconds has 10
% convert to seconds
nof_nanoseconds_in_a_second = 1000000000;
data.initial_time_stamp_mat = ceil(GPStable.timestamp(1)/nof_nanoseconds_in_a_second);
data.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat, 'convertfrom','posixtime', 'Format','dd-MMM-yyyy HH:mm:ss');
data.initial_time_stamp_mat = string(data.initial_time_stamp_mat);


%% Interpolate the data to 1 datapoint per second

% get the elapsed time from the start
% the ANWB app records every 0.01 second
% the timestamp is in 19 digits -> 10 digits is in seconds
% so divide by 10.000.000 (the 8 extra digits)
time_elapsed = GPStable.timestamp - GPStable.timestamp(1);
% extract the number of seconds that have elapsed since start
nof_seconds_elapsed = 0:floor(time_elapsed(end)./nof_nanoseconds_in_a_second);

% build the data struct
data.time = nof_seconds_elapsed';

% get the average over each 100 centiseconds part
num = ceil(length(GPStable.latitude)/100)*100;
lat_data = nan(num, 1);
lat_data(1:length(GPStable.latitude)) = GPStable.latitude;
data.lat = mean(reshape(lat_data, 100, []), "omitnan")';

lon_data = nan(num, 1);
lon_data(1:length(GPStable.longitude)) = GPStable.longitude;
data.lon = mean(reshape(lon_data, 100, []), "omitnan")';

acc_data = nan(num, 1);
acc_data(1:length(GPStable.accuracy)) = GPStable.accuracy;
data.acc = mean(reshape(acc_data, 100, []), "omitnan")';

data.fsample = 1;
data.datatype = "ANWBGPS";



% TODO: do we need to mess with the timezone?
% newdatetime = datetime(data.initial_time_stamp_mat,'TimeZone',cfg.originaltimezone,'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
% newdatetime.TimeZone = cfg.newtimezone;
% data.initial_time_stamp_mat = newdatetime;%string(newdatetime);
% data.initial_time_stamp = posixtime(datetime(data.initial_time_stamp_mat));


out = data;
end