function out = segment_acc(cfg, data)
%function out = segment_acc(cfg, data)
% function to resegment the ACC data from the Empatica Devices
%
% configuration options are:
%
% cfg options are:
% cfg.trigger_time: date string specifying the time point of interest (trigger point)
% cfg.pretrigger: time in seconds before trigger point
% cfg.posttrigger: time in seconds after trigger point
%
% Wilco Boode, 11-04-2019
%

%check for pretrigger
if ~isfield(cfg, 'pretrigger')
    cfg.pretrigger = 0;
end

%calculate when the file must start (based on data timestamp & trigger_time)
triggertime = seconds(datetime(cfg.trigger_time) - datetime(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;

%check whether the posttrigger is defined, if not then the posttrigger will be equal
%to the final date/time
if ~isfield(cfg, 'posttrigger')
    warning('posttrigger undefined: will use entire file');
    cfg.posttrigger = data.time(length(data.time))-triggertime;
end

%check whether the trigger_time / posttrigger are within the range of the provided data
if (pretrigger < 0)
    error(strcat('trigger_time of participant starts "',num2str(pretrigger),'" seconds before the acceleration data file'))
end
if ((pretrigger+cfg.posttrigger) > data.time(length(data.time)))
    error(strcat('posttrigger of participant end "',num2str((pretrigger+cfg.posttrigger)-data.time(length(data.time))),'" seconds after the acceleration data file'))
end

%cut the section out of the acceleration file based on the trigger_time and trigger_time
%point
startpoint = 1+(pretrigger*data.fsample);
endpoint = 1+((triggertime*data.fsample)+(cfg.posttrigger*data.fsample));

acceleration = data.acceleration(startpoint:endpoint,:);
directionalforce = data.directionalforce(startpoint:endpoint,:);

%create a new linear time array from 0-posttrigger time with the amount of
%datapoints available in the acceleration list
time = rot90(flip(linspace(0,cfg.posttrigger+cfg.pretrigger,length(acceleration))));

%output the requried data
out = data;
out.time = time;
out.acceleration = acceleration;
out.directionalforce = directionalforce;
out.timeoff = 0;
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = data.initial_time_stamp - pretrigger;
out.orig = data.orig;
out.datatype = data.datatype;
end