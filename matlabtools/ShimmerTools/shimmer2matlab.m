function out = shimmer2matlab(cfg)
% function to read in eda data from Empatica files.
%
% configuration options are:
%
% cfg.shimmerfile       = string specifying file that contains eda data in csv
%                     format (numbers, not strings!). Default = shimmer.csv
% cfg.datafolder    = string containing the full path folder in which empatica files
%                     are stored. Note that for matlab-internal reasons you
%                     have to specify double backslashes in the path. For
%                     example 'c:\\data\\marcel\\europapark\\raw\\s01'
% cfg.timezone      = string specifying the timezone the data was collected
%                     in, your local timezone will be used  if you dont
%                     specify anything. You can find all possible timezones
%                     by running the following command: timezones 
% Note that it is recommended to use the default configuration options for 
% cfg.edafile unless you have a good reason to deviate from that.
% Wilco Boode, 19-09-2022


%% TO DO:
% for creating the time array, and doing the restructuring, use the first and last unix timestamp, that way we know for certain we got the correct length, incase we have some skipping samples (which we shouldnt, bt just in case) 

%%

%Check existence of eda File, if non-existent, then the default name will
%be used.
if ~isfield(cfg, 'shimmerfile')
    cfg.shimmerfile = 'shimmer.csv';
end
%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    error('shimmer2matlab: datafolder not specified');
end
%check whether a timezone is specific, if not give warning and use local /
%current
if ~isfield(cfg, 'timezone')
    cfg.timezone = datetime('now', 'TimeZone', 'local').TimeZone;
    warning(strcat('TimeZone not specified. Using local TimeZone: ',cfg.timezone));
end
%check whether max allow data interval is specified. If not, set default
if ~isfield(cfg, 'allowedsampledifference')
    cfg.allowedsampledifference = 1;
    warning(strcat('AllowedSampleDifference not specified. Using default: ',mat2str(cfg.allowedsampledifference)));
end
%check whether desired sample frequency
if ~isfield(cfg, 'fsample')
    cfg.fsample = 128;
    warning(strcat('fsample not specified. Using default: ',mat2str(cfg.fsample)));
end

%check whether the data column names are specified, if not use default values
if ~isfield(cfg, 'columnname')
    cfg.columnname = [];
end
if ~isfield(cfg.columnname, 'eda')
    cfg.columnname.eda  = 'GSR_Skin_Conductance';
end
if ~isfield(cfg.columnname, 'acc_x')
    cfg.columnname.acc_x  = 'Accel_LN_X'; 
end
if ~isfield(cfg.columnname, 'acc_y')
    cfg.columnname.acc_y  = 'Accel_LN_Y'; 
end
if ~isfield(cfg.columnname, 'acc_z')
    cfg.columnname.acc_z  = 'Accel_LN_Z'; 
end
if ~isfield(cfg.columnname, 'unix')
    cfg.columnname.unix = 'Unix';
end
if ~isfield(cfg.columnname, 'temp')
    cfg.columnname.temp = 'Temperature';
end
if ~isfield(cfg.columnname, 'hr')
    cfg.columnname.hr = 'PPGtoHR';
end

%Save current Folder Location
curdir = pwd;
cd(cfg.datafolder)

% read shimmer data from file
opts = detectImportOptions(cfg.shimmerfile);
opts.DataLines = 4;
opts.VariableNamesLine = 2;

shimmerraw = readtable(cfg.shimmerfile,opts);

% determine find provided data and column names
datanames= fieldnames(shimmerraw);
columnnames = fieldnames(cfg.columnname);
datacolumns = [];

% iterate over the columnnames to find the corresponding dataname, and
% store this in a structure for later use
for isamp = 1:length(columnnames)
    c = find(contains(datanames,cfg.columnname.(columnnames{isamp}))==1);

    if isempty(c)
        continue;
    end
    if (max(size(c))==1)
        datacolumns.(columnnames{isamp}) = datanames{c};
    else
        result = 0;
        while result == 0
            warning(strcat('MULTIPLE COLUMNS FOUND FOR: ',columnnames{isamp}));
            warning('PLEASE PROVIDE ID FOR THE DESIRED COLUM NAME');
            for jsamp = 1:max(size(c))
                warning(strcat('ID: ',mat2str(jsamp), ' NAME: ',datanames{c(jsamp)}));
            end

            prompt = 'PLEASE PROVIDE THE DESIRED COLUMN ID: ';
            id = input(prompt);

            if ~isa(id,'double')
                try
                    id = str2double(id);
                catch
                    warning('Invalid ID');
                    id = 0;
                end
            end

            if id > 0 && id <=max(size(c))
                result = c(id);
                datacolumns.(columnnames{isamp}) = datanames{result};
            end
        end
    end
end


%make initial time stamp in UNIX time Seconds
data.initial_time_stamp = shimmerraw.(datacolumns.unix)(1)/1000;

%make initial time stamp human-readable
data.initial_time_stamp_mat = datetime(data.initial_time_stamp,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone',cfg.timezone);

%check if the sample interval difference is larger than the maximum required (could indicate multiple sessions in one file) 
if max(diff(shimmerraw.(datacolumns.unix)/1000)) > cfg.allowedsampledifference
    error(strcat('Largest interfal between samples is : ',mat2str(max(diff(shimmerraw.(datacolumns.unix)/1000))),'s Maximum allowed sample difference is: ', mat2str(cfg.allowedsampledifference),'s'));
end

%create new time array based on updated 
timeorig = shimmerraw.(datacolumns.unix)/1000;
timeorig = timeorig-timeorig(1);

datapoints =  floor(max(timeorig) * cfg.fsample);
data.time = rot90(flip(linspace(0,datapoints/cfg.fsample,datapoints+1)));

%see whether eda column has been recognized, resample, and store this data
if isfield(datacolumns, 'eda')
    tsin = timeseries(shimmerraw.(datacolumns.eda),timeorig);
    tsout = resample(tsin,data.time);    
    data.conductance = tsout.data;
    data.conductance_z = zscore(data.conductance);
end
%see whether hr column has been recognized, resample, and store this data
if isfield(datacolumns, 'hr')
    tsin = timeseries(shimmerraw.(datacolumns.hr),timeorig);
    tsout = resample(tsin,data.time);    
    data.heartrate = tsout.data;
end
%see whether temp column has been recognized, resample, and store this data
if isfield(datacolumns, 'temp')
    tsin = timeseries(shimmerraw.(datacolumns.temp),timeorig);
    tsout = resample(tsin,data.time);    
    data.temperature = tsout.data;
end
%see whether acc column has been recognized, resample, and store this data
if isfield(datacolumns, 'acc_x') && isfield(datacolumns, 'acc_y') && isfield(datacolumns, 'acc_z')
    acc = zeros(length(data.time),3);

    tsin = timeseries(shimmerraw.(datacolumns.acc_x),timeorig);
    tsout = resample(tsin,data.time);    
    acc(:,1)= tsout.data;

    tsin = timeseries(shimmerraw.(datacolumns.acc_y),timeorig);
    tsout = resample(tsin,data.time);    
    acc(:,2)= tsout.data;

    tsin = timeseries(shimmerraw.(datacolumns.acc_z),timeorig);
    tsout = resample(tsin,data.time);    
    acc(:,3)= tsout.data;
        
    data.acceleration = acc;
    data.directionalforce = sqrt(sum(acc.^2,2));
end

%set data sample from the eda file
data.fsample = cfg.fsample;

% fill part of the output structure
data.timeoff = 0;
data.orig = cfg.datafolder;
data.datatype = "shimmer";

%output the data
out = data;
end