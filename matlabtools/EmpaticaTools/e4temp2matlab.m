function out = e4temp2matlab(cfg)
% function to read in temp data from Empatica files.
%
% configuration options are:
%
% cfg.tempfile       = string specifying file that contains TEMP data in csv
%                     format (numbers, not strings!). Default = TEMP.csv
% cfg.datafolder    = string containing the full path folder in which empatica files
%                     are stored. Note that for matlab-internal reasons you
%                     have to specify double backslashes in the path. For
%                     example 'c:\\data\\marcel\\europapark\\raw\\s01'
% cfg.timezone      = string specifying the timezone the data was collected
%                     in, your local timezone will be used  if you dont
%                     specify anything. You can find all possible timezones
%                     by running the following command: timezones 
%
% Note that it is recommended to use the default configuration options for 
% cfg.edafile unless you have a good reason to deviate from that.
% Wilco Boode, 11-07-2022

%Save current Folder Location
curdir = pwd;
cd(cfg.datafolder)

%Check existence of temp File, if non-existent, then the default name will
%be used.
if ~isfield(cfg, 'tempfile')
    cfg.tempfile = 'TEMP.csv';
end
%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    error('empatica2matlab: datafolder not specified');
end
%check whether a timezone is specific, if not give warning and use local /
%current
if ~isfield(cfg, 'timezone')
    cfg.timezone = datetime('now', 'TimeZone', 'local').TimeZone;
    warning(strcat('TimeZone not specified. Using local TimeZone: ',cfg.timezone));
end

% read eda data from file
tempRaw = csvread(cfg.tempfile);

%make initial time stamp in UNIX time Seconds
data.initial_time_stamp = tempRaw(1);

%make initial time stamp human-readable
data.initial_time_stamp_mat = datetime(data.initial_time_stamp,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone',cfg.timezone);

%get data sample from the temp file
data.fsample = tempRaw(2);

%get the total length of the datasamples
nsamp = length(tempRaw)-2;
%generate a matrix with all zeroes for the entirety of the temp file, third
%line for the accumulated temp value
data.temp = zeros([nsamp 1]);

%generate the timelist for the temp data 
data.time = rot90(flip(linspace(0,(nsamp/data.fsample)-(1/data.fsample),nsamp)));

%Separate data from temp file into the 3 columns 
%4th column for the accumulated strength
for isamp=1:nsamp   
    data.temp(isamp,1) = tempRaw(isamp+2,1);
end

% fill part of the output structure
data.timeoff = 0;
data.orig = cfg.datafolder;
data.datatype = "temp";

%make sure only the necessary data is outputted
out.initial_time_stamp = data.initial_time_stamp;
out.initial_time_stamp_mat = data.initial_time_stamp_mat;
out.fsample = data.fsample;
out.temperature = data.temp;
out.time = data.time;
out.timeoff= data.timeoff;
out.orig = data.orig;
out.datatype = data.datatype;
end
%13-11-2020: Changed eval to CD (eval was giving errors)