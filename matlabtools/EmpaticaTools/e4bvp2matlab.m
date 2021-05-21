function out = e4bvp2matlab(cfg)
% function to read in bvp data from Empatica files.
%
% configuration options are:
%
% cfg.bvpfile       = string specifying file that contains BVP data in csv
%                     format (numbers, not strings!). Default = BVP.csv
% cfg.datafolder    = string containing the full path folder in which empatica files
%                     are stored. Note that for matlab-internal reasons you
%                     have to specify double backslashes in the path. For
%                     example 'c:\\data\\marcel\\europapark\\raw\\s01'
%
% Note that it is recommended to use the default configuration options for 
% cfg.edafile unless you have a good reason to deviate from that.
% Wilco Boode, 07-01-2020

%Save current Folder Location
curdir = pwd;
cd(cfg.datafolder)

%Check existence of bvp File, if non-existent, then the default name will
%be used.
if ~isfield(cfg, 'bvpfile')
    cfg.bvpfile = 'BVP.csv';
end
%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    error('empatica2matlab: datafolder not specified');
end

% read eda data from file
bvpRaw = csvread(cfg.bvpfile);

%make initial time stamp in UNIX time Seconds
data.initial_time_stamp = bvpRaw(1);

%make initial time stamp human-readable
data.initial_time_stamp_mat = datestr(unixmillis2datenum(data.initial_time_stamp*1000));

%get data sample from the bvp file
data.fsample = bvpRaw(2);
%get the total length of the datasamples
nsamp = length(bvpRaw)-2;
%generate a matrix with all zeroes for the entirety of the bvp file, third
%line for the accumulated bvp value
data.bvp = zeros([nsamp 1]);

%generate the timelist for the bvp data 
data.time = rot90(flip(linspace(0,(nsamp/data.fsample)-(1/data.fsample),nsamp)));

%Separate data from bvp file into the 3 columns 
%4th column for the accumulated strength
for isamp=1:nsamp   
    data.bvp(isamp,1) = bvpRaw(isamp+2,1);
end

% fill part of the output structure
data.timeoff = 0;
data.orig = cfg.datafolder;
data.datatype = "bvp";

%make sure only the necessary data is outputted
out.initial_time_stamp = data.initial_time_stamp;
out.initial_time_stamp_mat = data.initial_time_stamp_mat;
out.fsample = data.fsample;
out.bvp = data.bvp;
out.time = data.time;
out.timeoff= data.timeoff;
out.orig = data.orig;
out.datatype = data.datatype;
end
%13-11-2020: Changed eval to CD (eval was giving errors)