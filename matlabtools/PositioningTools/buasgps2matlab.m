function out = buasgps2matlab(cfg)
%% BUAS GPS 2 MATLAB
%function out = buasgps2matlab(cfg)
%
% *DESCRIPTION*
% function to read GPS data that has been collected using the BUas GPS tracker app
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

%% DEV INFO
%during the latest update, the full importer has been replaced by the
%matlab XML import functions. Also, the way data is being altered into a
%linear structure has been overhauled to better catch possible missing
%datapoints.

%% VARIABLE CHECK
%set defaults
if ~isfield(cfg, 'datafolder')
    warning('buasgps2matlab: datafolder not specified');
end
if ~isfield(cfg, 'gpsfile')
    warning('buasgps2matlab: gps file not specified');
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


data.initial_time_stamp_mat = GPStable.timestamp_utc(1);
data.initial_time_stamp_mat = string(data.initial_time_stamp_mat);

%% Interpolate the data to 1 datapoint per second

% get the elapsed time from the start
GPStable.time_elapsed = GPStable.timestamp_utc - GPStable.timestamp_utc(1);
% extract the number of seconds that have elapsed since start
GPStable.nof_seconds_elapsed = round(seconds(GPStable.time_elapsed));
max_time_elapsed = GPStable.nof_seconds_elapsed(end);

% build the data struct
data.time = linspace(0, max_time_elapsed, max_time_elapsed + 1)';
data.lat      = NaN(max_time_elapsed + 1, 1);
data.lon      = NaN(max_time_elapsed + 1, 1);
data.acc      = NaN(max_time_elapsed + 1, 1);


%% PLACE THE GPS DATA IN THE DATA STRUCT

for data_i = 1:length(GPStable.nof_seconds_elapsed)
    datastruct_index = GPStable.nof_seconds_elapsed(data_i) + 1;
    data.lat(datastruct_index) = GPStable.latitude(data_i);
    data.lon(datastruct_index) = GPStable.longitude(data_i);
    data.acc(datastruct_index) = GPStable.accuracy(data_i);
end


%% FILL IN THE GAPS
%  all the seconds that have no recoded data get filled with the last recorded data
%  TODO: think about whther this is the optimal solution
%        this leads to many duplicate points
%        which hinders data cleaning
%        Why not leave them empty, until matched with skin condcutance data?
data.lat = fillmissing(data.lat,'previous');
data.lon = fillmissing(data.lon,'previous');
data.acc = fillmissing(data.acc,'previous');

% TODO: do we need to mess with the timezone?
% newdatetime = datetime(data.initial_time_stamp_mat,'TimeZone',cfg.originaltimezone,'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
% newdatetime.TimeZone = cfg.newtimezone;
% data.initial_time_stamp_mat = newdatetime;%string(newdatetime);
% data.initial_time_stamp = posixtime(datetime(data.initial_time_stamp_mat));

%% CREATE OUTPUT
%make sure only the necessary data is collected int eh out struct
data.fsample = 1;
data.datatype = "BUasGPS";

out = data;
end