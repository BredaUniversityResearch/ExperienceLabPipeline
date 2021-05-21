function out = e4ibi2matlab(cfg)
% function to read in ibi data from Empatica files.
%
% configuration options are:
%
% cfg.ibifile       = string specifying file that contains ibi data in csv
%                     format (numbers, not strings!). Default = ibi.csv
% cfg.datafolder    = string containing the full path folder in which empatica files
%                     are stored. Note that for matlab-internal reasons you
%                     have to specify double backslashes in the path. For
%                     example 'c:\\data\\marcel\\europapark\\raw\\s01'
%
% Note that it is recommended to use the default configuration options for
% cfg.edafile unless you have a good reason to deviate from that.
% Wilco Boode, 07-01-2020
%
% Update: Added isempty check (Line 38), as IBI from empaticas can be empty with too
% little data. Wilco Boode, 18/12/2020

%Save current Folder Location
curdir = pwd;
cd(cfg.datafolder)

%Check existence of ibi File, if non-existent, then the default name will
%be used.
if ~isfield(cfg, 'ibifile')
    cfg.ibifile = 'IBI.csv';
end
%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    error('empatica2matlab: datafolder not specified');
end

% read eda data from file
ibiRaw = readtable(cfg.ibifile);

% Since IBI can be empty in certain files, we must check for this
if isempty(ibiRaw)
    data.initial_time_stamp =datenum2unixmillis(cfg.trigger_time)
    data.initial_time_stamp_mat = cfg.trigger_time;

    data.ibi = [];
    data.time = [];
else
    %make initial time stamp in UNIX time Seconds
    data.initial_time_stamp = ibiRaw{1,1};
    %make initial time stamp human-readable
    data.initial_time_stamp_mat = datestr(unixmillis2datenum(data.initial_time_stamp*1000));
    
    %get the total length of the datasamples
    nsamp = height(ibiRaw)-1;
    
    %generate a matrix with all zeroes for the entirety of the ibi file, third
    %line for the accumulated ibi value
    data.ibi = zeros([nsamp 1]);
    %line for the accumulated ibi value
    data.time = zeros([nsamp 1]);
    
    %Separate data from ibi file into the 3 columns
    %4th column for the accumulated strength
    for isamp=1:nsamp
        data.time(isamp,1) = ibiRaw{isamp+1,1};
        data.ibi(isamp,1) = str2double(ibiRaw{isamp+1,2});
    end
end



% fill part of the output structure
data.timeoff = 0;
data.orig = cfg.datafolder;
data.datatype = "ibi";

%make sure only the necessary data is outputted
out.initial_time_stamp = data.initial_time_stamp;
out.initial_time_stamp_mat = data.initial_time_stamp_mat;
out.ibi = data.ibi;
out.time = data.time;
out.timeoff= data.timeoff;
out.orig = data.orig;
out.datatype = data.datatype;
end
%13-11-2020: Changed eval to CD (eval was giving errors)