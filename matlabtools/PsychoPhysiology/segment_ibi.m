function out = segment_ibi(cfg, data)
% function out = segment_ibi(cfg, data)
% function to resegment the ibi data from the Empatica Devices
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
% Update: Added Isempty Check (line 42) in case IBI is empty, which is
% possible with short E4 files. Wilco Boode, 18/12/2020

%calculate when the file must start (based on data timestamp & trigger_time)
triggertime = seconds(datetime(cfg.trigger_time,'TimeZone',data.initial_time_stamp_mat.TimeZone) - datetime(data.initial_time_stamp_mat))
pretrigger = triggertime-cfg.pretrigger;

%check whether the posttrigger is defined, if not then the posttrigger will be equal
%to the final date/time
if ~isfield(cfg, 'posttrigger')
    warning('posttrigger undefined: will use entire file');
    cfg.posttrigger = data.time(length(data.time))-triggertime;
end

startpoint = 1;
for i=1:length(data.time)
    if data.time(i) > pretrigger
        startpoint = i;
        break;
    end
end

endpoint = 1;
for i=1:length(data.time)
    if data.time(i) > triggertime+cfg.posttrigger
        endpoint = i-1;
        break;
    end
end

if isempty(data.ibi)
    ibi=[];
    time=[];
else
    ibi = data.ibi(startpoint:endpoint,:);
    time = data.time(startpoint:endpoint,:);
end

for i=1:length(time)
    time(i) = time(i)-pretrigger;
end

%output the requried data
out = data;
out.time = time;
out.ibi = ibi;
out.timeoff = cfg.pretrigger;
out.initial_time_stamp_mat = datetime(cfg.trigger_time)-seconds(cfg.pretrigger);
out.initial_time_stamp = data.initial_time_stamp - pretrigger;
out.orig = data.orig;
out.datatype = data.datatype;
end