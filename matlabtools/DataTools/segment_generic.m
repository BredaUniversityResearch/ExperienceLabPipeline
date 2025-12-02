function out = segment_generic (cfg,data)
%% SEGMENT GENERIC
% function out = segment_generic (cfg,data)
%
% *DESCRIPTION*
%This function allows you to segment LINEAR time-series data based on a time
%array, and a starttime & endtime/duration. The function can either cut
%pre-determined variables, or cut all variables with the same length as the
%time-series data, that are immediate fields (not subfields) of the provided
%structure.
%
% *INPUT*
%Configuration Options
%cfg.time = (OPTIONAL) you can provide either the name of the variable
%           containing time-series data ('timearray'), or the full time-series
%           data itself [0 1 2 3 4 5 6]. Leaving this blank will use the
%           variable "time" in the "data" as the time-series.
% cfg.timeformat = string specifying the format of the start and endtimes
%           This can be either 'datetime' (default) or 'unixtime'
%           Example of datetime: '15-May-2023 14:16:48'
%           Example of unixtime: 1700470579
%cfg.starttime = The time of the first datapoint to include in the
%           segmented section, can be indicated as datetime ("23-Feb-2022 11:29:23"),
%           as a value in the time-series data (250.5), or as "startfile"
%           to set the starttime to the start of the time-series data.
%cfg.endtime = The time of the last datapoint to include in the
%           segmented section, can be indicated as datetime ("23-Feb-2022 11:29:23"),
%           as a value in the time-series data (250.5), or as "endfile"
%           to set the endtime to the end of the time-series data.
%cfg.duration = (OPTIONAL) can be included instead of the endtime, in which case the
%           starttime + duration will be used to calculate the endtime. Is
%           only used in case cfg.endtime is not defined.
%cfg.variables = (OPTIONAL) an array of strings, containing the name of all
%           variables to analyze ["conductance";"phasic"]. If this is not
%           defined, then all variables with the same length as the
%           time-series data will be segmented.
%cfg.allowoutofbounds = (OPTIONAL) true , detemines whether data is allowed to
%           be segmented outside the actual time-range available, this will
%           by default use the last / first value in the array. And can be
%           customized
%cfg.outofboundsstring = overflow value used by string based out of bounds 
%           arrays    
%cfg.outofboundsnumeric = overflow value used by numeric based out of bounds 
%           arrays   
%
%Data Requirements
%data.time = an array with time-series data. does not need to be linear.
%           This can also be defined in the cfg. [0 1 2 3 4 5 6]
%data.{variables} = all variables with the same length as the time-series
%           data that must be segmented.
%data.initial_time_stamp_mat = must be there if a datetime is provided as
%           the starttime or endtime ("23-Feb-2022 11:29:23"). Will be
%           overwritten in the final output with the new starttime.
%data.initial_time_stamp = starttime in second based unix time. Will be
%           overwritten in the final output with the new starttime unix time.
%
%
% *OUTPUT*
%This function outputs the same data structure as put in, with as major
%differentiator that the available arrays will be segmented based on the
%provided starttime and endtime.
%
% *NOTES*
%
% *BY*
% Wilco 27-06-2022

%% DEV INFO
%cfg.starttime does not accept datetimes for some reason!
% EXTRA INFO
% format for millis based timestamping, probably needs to be adopted by all
% our stuff, as we are getting into a stage where its necessary :(
% datetime(data.initial_time_stamp_mat, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')+seconds(max(data.time));
%
% localization, we are currently doing just a simple to datetime, but that
% will frack up if people in other locations / timezones run the data. So
% we will need to add a location I imagine. Ewhhh
% Default = amsterdam from now on I guess

% TO ADD
%1 option for out of bounds data, and a fill up with specific data type (zeroes ,  "" , self-provided, or last-available)
%2 option for excludevariables, in case you want to do all but certain variables in the data file
%maybe we make it variable dependent? (not sure if its a good idea, but allowing per variable fill options might be interesting) NO, SOUNDS HORRIBLE
%3 posttrigger/duration, add check if its a cell that can be turned into an
%integer or not
%4 add config for pretrigger, posttrigger, trigger_time
%5 make it possible to use datetimes rather than string values

%% VARIABLE CHECK
if isfield (cfg, 'trigger_time')
    cfg.starttime = string(cfg.trigger_time);
end
if isfield (cfg, 'pretrigger')
    cfg.starttime = string(datetime(cfg.starttime)-seconds(cfg.pretrigger));
end
if isfield (cfg, 'posttrigger')
    cfg.duration = cfg.posttrigger;
end

if ~isfield(cfg,'allowoutofbounds')
    cfg.allowoutofbounds = 'false';
    %if ~isfield(cfg,'outofboundsstring')
    %    cfg.outofboundsstring = ""; %fill in text to use for out of bound strings
    %end
    %if ~isfield(cfg,'outofboundsnumeric')
    %    cfg.outofboundsnumeric = zeros; %fill in value to use for out of bound strings. Optionally, use "bound" to use the last available value
    %end
end
if ~isfield(cfg, 'timeformat')
    cfg.timeformat = 'datetime';
end

%% SET TIME VARIABLE
if ~isfield(cfg,'time')
    if ~isfield(data,'time')
        error('CANNOT FIND TIME DATA, EITHER INDICATE THE VARIABLENAME, OR PROVIDE A TIME ARRAY')
    end
    time = data.time;
else
    if isa(cfg.time,'string')
        time = data.(cfg.time);
    elseif ~isscalar(cfg.time)
        time = cfg.time;
    else
        error('CANNOT FIND TIME DATA, EITHER INDICATE THE VARIABLENAME, OR PROVIDE A TIME ARRAY')
    end
end

%% SET NAMES OF VARIABLES TO SEGMENT
% AT FIRST WE ONLY ALLOW VARIABLED DIRECTLY PART OF THE PROVIDED STRUCTURE

%If variables are not defined, then get all in the data
if ~isfield(cfg,'variables')
    vnames = fieldnames(data);
else
    vnames = cfg.variables;
end

%Loop to check and create a final array of all variables to edit
variables = [];
for isamp = 1:length(vnames)
    curname = vnames{isamp};

    %See whether the data actually exists
    if ~isfield(data,curname)
        if isfield(cfg,'variables')
            warning(strcat("Variable *",curname,"* does not exist in the provided data structure"))
        end
        continue
    end

    %Check if the data is of the same length as time
    try
        equallength = length(data.(curname)) == length(time);
    catch
        if ~isequal(class(equallength),'Int')
            display(strcat("Could not check length for: ",curname));
            equallength = 0;
        end
    end

    %Check the out put of equallength, then assume its time series data if its true / 1
    if equallength
        variables = [variables;string(curname)];
    elseif isfield(cfg,'variables')
        warning(strcat("Variable *",curname,"* has the wrong length compared to the Time variable"))
    end
end

%% SET START TIME
if ~isfield(cfg,'starttime')
    starttime = 0;
    warning('Starttime not defined, assuming start of file')
else
    if isnumeric(cfg.starttime)
        starttime = cfg.starttime;
        if strcmp(cfg.timeformat, 'unixtime')
            % calculate the starttime relative to the start of the measurement 
            starttime = starttime - data.initial_time_stamp;
        end
    else
        if strcmp(cfg.starttime, "startfile")
            starttime = 0;
        elseif isfield(data,'initial_time_stamp_mat')
            try
                starttime = etime(datevec(cfg.starttime),datevec(data.initial_time_stamp_mat));
            catch exception
                error('Could not convert the start datetime, make sure it uses the correct format, and that the data contains the initial_time_stamp_mat variable')
            end
        else
            error('Cannot find initial_time_stamp_mat in the original data, stopping segmentation')
        end
    end
end
if starttime < min(time) && strcmp(cfg.allowoutofbounds,'false')
    error(strcat('New Start time is less than the data start time, this is not allowed',' DataStart: ', string(data.initial_time_stamp_mat),' DataEnd:',string(cfg.starttime)))
elseif starttime < min(time) && strcmp(cfg.allowoutofbounds,'true')
    preduration = -starttime;
    starttime = min(time);
end

%% SET END TIME
if isfield(cfg,'endtime')
    if isnumeric(cfg.endtime)
        endtime = cfg.endtime;
        if strcmp(cfg.timeformat, 'unixtime')
            % calculate the endtime relative to the start of the measurement 
            endtime = endtime - data.initial_time_stamp;
        end
    else
        if cfg.endtime == "endfile"
            endtime = max(time);
        elseif isfield(data,'initial_time_stamp_mat')
            try
                endtime = etime(datevec(cfg.endtime),datevec(data.initial_time_stamp_mat));
            catch exception
                error('Could not convert the end datetime, make sure it uses the correct format, and that the data contains the initial_time_stamp_mat variable')
            end
        else
            error('Cannot find initial_time_stamp_mat in the original data, stopping segmentation')
        end
    end

    if isfield(cfg,'duration')
        warning('Endtime has been defined, will not use duration')
    end
else
    if isfield(cfg,'duration')
        endtime = starttime+cfg.duration;
        if exist('preduration','var')
            endtime = endtime-preduration;
        end
    else
        endtime = max(time);
        warning('Endtime not defined, assuming end of file')
    end
end
if endtime > max(time) && strcmp(cfg.allowoutofbounds,'false')
    error('New End time is higher than the data end time, this is not allowed')
elseif endtime > max(time) && strcmp(cfg.allowoutofbounds,'true')
    postduration = endtime-max(time);
    endtime = max(time);
end

if endtime<starttime || endtime==starttime
    error('New end time is lower than or equal to the start time, this is not allowed')
end


%% GET NEW DATA FOR THE INDICATED VARIABLES
%create outstructure for populating with new data
out = data;

%get the indexes of all data to retrieve from the original data
tindex = find(data.time >= starttime & data.time <= endtime);

%replace the out variable with the section cut based on tindex
for isamp = 1:length(variables)
    out.(variables(isamp))=data.(variables(isamp))(min(tindex):max(tindex),:);
end


%% CREATE NEW TIME VARIABLES
%NEEDS TO USE THE STARTTIME TO ENDTIME, AS CURRENTLY IT WILL BREAK WITH
%OUTSIDE TIME ARRAY VALUES
newtime = linspace(0,time(max(tindex))-time(min(tindex)),length(tindex))';
out.time = newtime;

%calculate new initial_time_stamp_mat & initial_time_stamp
if isfield(data,'initial_time_stamp_mat')
    %NEEDS TO NOT BE AN OFFSET FROM DATE TIME, BUT USE THE STARTTIME VALUE,
    %AS IT CAN BE A RANGE OUTSIDE OF THE DATA.TIME ARRAY
    out.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat)+seconds(data.time(min(tindex)));
    %WAY OF DOING IT IN THE FUTURE, TO BETTER FACILITATE DIFFERENT TIMEZONES AND MILLISECOND DATA
    %data.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')+seconds(data.time(min(tindex)), 'TimeZone', cfg.timezone);
    out.initial_time_stamp = posixtime(out.initial_time_stamp_mat);
end

%% NEW PRE POST TEST LOOP
if exist('postduration','var') || exist('preduration','var')
    fsample = 1/diff([time(1),time(2)]);
    originalsize = length(tindex);

    if exist('preduration','var')
        prepoints = fsample*preduration;
        if mod(prepoints,1) > 0
            warning('Preduration does not fit within sampling frequency, adjusting to nearest sampling point')
            prepoints = prepoints-mod(prepoints,1);
        end
    else
        prepoints = 0;
    end

    if exist('postduration','var')
        postpoints = fsample*postduration;
        if mod(postpoints,1) > 0
            warning('Postduration does not fit within sampling frequency, adjusting to nearest sampling point')
            postpoints = postpoints-mod(postpoints,1);
        end
    else
        postpoints = 0;
    end

    extension = [prepoints+1 linspace(1,1,originalsize-2) postpoints+1];

    for isamp = 1:length(variables)
        oldarray = out.(variables(isamp));
        newarray = repelem(oldarray,extension);

        if (isnumeric(oldarray))
            if isfield(cfg,'outofboundsnumeric')
                newarray(1:prepoints) = cfg.outofboundsnumeric;
                newarray(length(newarray)-(postpoints-1):length(newarray)) = cfg.outofboundsnumeric;
            end
        end
        if isa(oldarray(1),'string')
            if isfield(cfg,'outofboundsstring')
                newarray(1:prepoints) = cfg.outofboundsstring;
                newarray(length(newarray)-(postpoints-1):length(newarray)) = cfg.outofboundsstring;
            end
        end
        
        out.(variables(isamp)) = newarray;
    end
    % ADJUST TIME VARIABLES for PRE POST
    newtime = transpose(linspace(0,double(max(newtime)+((prepoints + postpoints)*diff([time(1),time(2)]))),double(length(tindex)+(prepoints + postpoints))));

    out.time = newtime;

    %calculate new initial_time_stamp_mat & initial_time_stamp
    if isfield(data,'initial_time_stamp_mat')
        %NEEDS TO NOT BE AN OFFSET FROM DATA.TIME, BUT USE THE STARTTIME VALUE,
        %AS IT CAN BE A RANGE OUTSIDE OF THE DATA.TIME ARRAY
        out.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat)-seconds(prepoints*diff([time(1),time(2)]));
        %WAY OF DOING IT IN THE FUTURE, TO BETTER FACILITATE DIFFERENT TIMEZONES AND MILLISECOND DATA
        %data.initial_time_stamp_mat = datetime(data.initial_time_stamp_mat, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')+seconds(data.time(min(tindex)), 'TimeZone', cfg.timezone);
        out.initial_time_stamp = posixtime(out.initial_time_stamp_mat);
    end
end
end