function out = e4eda2matlab(cfg)
% function to read in events from Empatica files.
%
% note that the output struct as defined by the function call needs to be
% saved as a struct named data into a datafile named matData.mat if you want
% to subsequently read data into the Ledalab GUI.
%
% configuration options are:
%
% cfg.tagsfile      = string specifying file that contains EVENT data in csv
%                     format (numbers, not strings!). Default = tags.csv
% cfg.datafolder    = string containing the full path folder in which empatica files
%                     are stored. Note that for matlab-internal reasons you
%                     have to specify double backslashes in the path. For
%                     example 'c:\\data\\marcel\\europapark\\raw\\s01'
%
% Note that it is recommended to use the default configuration options for
% cfg.edafile and cfg.timefile unless you have a good reason to deviate from that.
% Wilco Boode 16/03/2020
%
%Added Try Catch on csvread, so that possible files provide a warning,
%rather than an error. Wilco Boode, 18/12/2020

% set defaults
if ~isfield(cfg, 'tagsfile')
    cfg.tagsfile = 'tags.csv';
end
if ~isfield(cfg, 'datafolder')
    error('e4event2matlab: datafolder not specified');
end

%save the current directory, and open the datafolder containing the actual
%data
curdir = pwd;
cd(cfg.datafolder)

% read eda data from file, this first opens the textfile, then scans for
try
    tagRaw = csvread(cfg.tagsfile);
catch
    warning('TagsFile could not be read, might be empty');
    tagRaw=[];
end

data.orig = cfg.datafolder;
data.datatype = "events";
data.event = [];

% fill output structure with events
for i= 1:numel(tagRaw)
    data.event(i).time_stamp = tagRaw(i)*1000;
    data.event(i).time_stamp_mat = datestr(unixmillis2datenum(data.event(i).time_stamp));
    data.event(i).nid = i;
    data.event(i).name = ['event' int2str(data.event(i).time_stamp)];
end

%make sure only the necessary data is outputted
out.orig = data.orig;
out.event = data.event;
out.datatype = data.datatype;
end
%13-11-2020: Changed eval to CD (eval was giving errors)