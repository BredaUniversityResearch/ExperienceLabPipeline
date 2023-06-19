function out = resample_generic(cfg, data)
%% RESAMPLE GENERIC
%function out = resample_generic(cfg, data)
%
% *DESCRIPTION*
% generic function to resample all data inside a struct. Allows you to
% provide a struct, and resample all array data of equal length to a new
% sample frequency. Assumes all data is of the same frequency, and only
% takes arrays of same length!
%
% *INPUT*
%Configuration Options
% cfg.fsample       =   desired fsample, must be provided
% cfg.valueList     =   provide the required datanames, these will be taken
% and resampled from the data struct, then overwritten in the output
%
% *OUTPUT*
%The same as the input struct, but with all array data re-structured
%
% *NOTES*
% See the following page for more info on the resampling function
% https://nl.mathworks.com/help/signal/ref/resample.html#bumhz33-beta
% THIS FUNCTION IS STILL UNDER CONSTRUCTION, AND REQUIRES CAREFULL USE!!!
%
% *BY*
% Wilco Boode, 20-11-2020

%% VARIABLE CHECK
%Check whether the desired fsample is defined, this value is mandatory
if ~isfield (cfg,'fsample')
    error('no sample frequency is defined');
end

if ~isfield (data,'time')
    error('no time data provided')
end

%Deterine wheter any datavalues are provided, if not, give a warning
if ~isfield (cfg,'valueList')
    warning('no data values provided, using all arrays with length as time');
    cfg.valueList = [];
    vars = fieldnames(data);
    for isamp = 1:length(vars)
        if strcmpi(string(vars{isamp}),"time")
            continue
        end
        if height(data.(vars{isamp})) == height(data.time)
            cfg.valueList = [cfg.valueList;string(vars{isamp})];
        end
    end
end

%% TAKE ALL VARIABLES AND RESAMPLE THEM TO THE NEW FREQUENCY
datanames = matlab.lang.makeValidName(cfg.valueList);
datalength = 0;
%uses the default Matlab resampling function to resample the data from the
%data fsample to the desired fsample rate. This uses the data.time, to get
%an accurate representaiton, and remove any overfitting
for i=1:length(datanames)
    if isfield(data,datanames{i})
        newdata.(datanames{i}) = resample(data.(datanames{i}),data.time,cfg.fsample,1,1);
        datalength = length(newdata.(datanames{i}));
    end
end

%calculate the total duration of the data, then generate an array of time
%points
tFinal = (1/cfg.fsample)*(datalength-1);% data.time(length(data.time));
time = transpose(linspace(0,tFinal,datalength));

%% FUNCTION END
out = data;
f = fieldnames(newdata);
for i = 1:length(f)
    out.(f{i}) = newdata.(f{i});
end
out.time = time;
out.fsample = cfg.fsample;
end