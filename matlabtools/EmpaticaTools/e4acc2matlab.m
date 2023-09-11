function out = e4acc2matlab(cfg)
% function to read in ACC data from Empatica files.
%
% configuration options are:
%
% cfg.accfile       = string specifying file that contains EDA data in csv
%                     format (numbers, not strings!). Default = ACC.csv
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

% testing changes

%Save current Folder Location
curdir = pwd;
cd(cfg.datafolder)

%Check existence of ACC File, if non-existent, then the default name will
%be used.
if ~isfield(cfg, 'accfile')
    cfg.accfile = 'ACC.csv';
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
accRaw = csvread(cfg.accfile);

%make initial time stamp in UNIX time Seconds
data.initial_time_stamp = accRaw(1);

%make initial time stamp human-readable
data.initial_time_stamp_mat = datetime(data.initial_time_stamp,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone',cfg.timezone);

%get data sample from the ACC file
data.fsample = accRaw(2);
%get the total length of the datasamples
nsamp = length(accRaw)-2;
%generate a matrix with all zeroes for the entirety of the acc file, third
%line for the accumulated ACC value
data.acc = zeros([nsamp 3]);
data.directionalforce = zeros([nsamp 1]);
%generate the timelist for the acc data 
data.time = rot90(flip(linspace(0,(nsamp/data.fsample)-(1/data.fsample),nsamp)));

%Separate data from ACC file into the 3 columns 
%4th column for the accumulated strength
for isamp=1:nsamp   
    data.acc(isamp,1) = accRaw(isamp+2,1);
    data.acc(isamp,2) = accRaw(isamp+2,2);
    data.acc(isamp,3) = accRaw(isamp+2,3);
    %data.acc(isamp,4) = sqrt(data.acc(isamp,1)^2+data.acc(isamp,2)^2+data.acc(isamp,3)^2);
    data.directionalforce(isamp,1) = sqrt(data.acc(isamp,1)^2+data.acc(isamp,2)^2+data.acc(isamp,3)^2);
end

% fill part of the output structure
data.timeoff = 0;
data.orig = cfg.datafolder;
data.datatype = "acc";

%make sure only the necessary data is outputted
out.initial_time_stamp = data.initial_time_stamp;
out.initial_time_stamp_mat = data.initial_time_stamp_mat;
out.fsample = data.fsample;
out.acceleration = data.acc;
out.directionalforce = data.directionalforce;
out.time = data.time;
out.timeoff= data.timeoff;
out.orig = data.orig;
out.datatype = data.datatype;

end
%13-11-2020: Changed eval to CD (eval was giving errors)
