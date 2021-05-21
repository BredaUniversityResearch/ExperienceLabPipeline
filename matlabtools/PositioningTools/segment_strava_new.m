function out = segment_strava(cfg, data)

%calculate when the file must start (based on data timestamp & trigger_time)
triggertime = seconds(datetime(cfg.trigger_time) - datetime(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;
pretrigger2 = pretrigger;

%check whether the posttrigger is defined, if not then the posttrigger will be equal
%to the final date/time
if ~isfield(cfg, 'posttrigger')
    warning('posttrigger undefined: will use entire file');
    cfg.posttrigger = data.time(length(data.time))-triggertime;
end

%check whether the trigger_time / posttrigger are within the range of the provided data
if (pretrigger < 0)    
    warning(strcat('trigger_time of participant starts "',num2str(pretrigger),'" seconds before the strava data file, filling with starting data'))
    for i=1:abs(pretrigger)
        data.lat = [data.lat(i); data.lat];
        data.long = [data.long(i); data.long];
        data.altitude = [data.altitude(i); data.altitude];
        data.distance = [0; data.distance];
        data.speed = [0; data.speed];
        data.speed2 = [0; data.speed2];
        data.power = [0; data.power];
    end     
    pretrigger2 = 0;
end
if ((pretrigger+cfg.posttrigger) > data.time(length(data.time)))    
    warning(strcat('posttrigger of participant end "',num2str((pretrigger+cfg.posttrigger)-data.time(length(data.time))),'" seconds after the strava data file, filling rest with ending data'))
    for i=1:abs((pretrigger+cfg.posttrigger)-data.time(length(data.time)))
        data.lat = [data.lat;data.lat(length(data.lat))];
        data.long = [data.long;data.long(length(data.long))];
        data.altitude = [data.altitude;data.altitude(length(data.altitude))];
        data.distance = [data.distance;data.distance(length(data.distance))];
        data.speed = [data.speed;data.speed(length(data.speed))];
        data.speed2 = [data.speed2;data.speed2(length(data.speed2))];
        data.power = [data.power;data.power(length(data.power))];
    end  
end

%cut the section out of the acceleration file based on the trigger_time and trigger_time
%point
startpoint = 1+(pretrigger2*data.fsample);
endpoint = 1+((triggertime*data.fsample)+(cfg.posttrigger*data.fsample));

lat = data.lat(startpoint:endpoint,:);
long = data.long(startpoint:endpoint,:);
altitude = data.altitude(startpoint:endpoint,:);
distance = data.distance(startpoint:endpoint,:);
speed = data.speed(startpoint:endpoint,:);
speed2 = data.speed2(startpoint:endpoint,:);
power = data.power(startpoint:endpoint,:);

%create a new linear time array from 0-posttrigger time with the amount of
%datapoints available in the acceleration list
time = rot90(flip(linspace(0,cfg.posttrigger+cfg.pretrigger,length(lat))));

%output the requried data
out = data;
out.time = time;
out.lat = lat;
out.long = long;
out.altitude = altitude;
out.distance = distance;
out.speed = speed;
out.speed2 = speed2;
out.power = power;
out.timeoff = 0;
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = data.initial_time_stamp - pretrigger;
out.datatype = data.datatype;
end