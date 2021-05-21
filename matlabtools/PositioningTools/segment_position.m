function out = segment_position(cfg, data)
% function out = segment_position(cfg, data);
% segments position data (in matlab formt) around a trigger point.
% It returns segmented position data - only beacon psoition data in current implementation.
% input data are e.g. the output struct from beacon2matlab
%
% cfg options are:
% cfg.trigger_time: date string specifying the time point of interest (trigger point)
% cfg.pretrigger: time in seconds before trigger point
% cfg.posttrigger: time in seconds after trigger point, can also be string 'EOF', in which case data are included until the end of the recordings
%
% pretrigger and posttrigger together define the data segment that results
% from this function.
%
% Marcel & Wilco, 05-04-2018

% find timestamp (seconds) of trigger
% find timestamp (seconds) of preTrigger
% find timestamp (seconds) of postTrigger

triggertime = etime(datevec(cfg.trigger_time),datevec(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;

%determine posttrigger depending on user input
if isnumeric(cfg.posttrigger)
    posttrigger = triggertime+cfg.posttrigger;
elseif strcmpi('EOF', cfg.posttrigger)
   posttrigger = data.time(numel(data.time));
else
    error('segment_position: cfg.posttrigger is not correctly specified. Type help segment_position for options');
end

% cut out data and time segments
newtime = [];
newid = [];
newdistance = [];
newmajor = [];
newminor = [];
newrssi = [];
newname = [];

for  i = 1:numel(data.time)
    if (data.time(i) >= 1+pretrigger) && (data.time(i) <=  1+posttrigger)
        newtime = [newtime,data.time(i)-pretrigger];
        newid = [newid,data.id(i)];
        newdistance = [newdistance,data.distance(i)];
        newmajor = [newmajor,data.major(i)];
        newminor = [newminor,data.minor(i)];
        newrssi = [newrssi,data.rssi(i)];
        newname = [newname,data.name(i)];
    end
end

out = data;
out.time = newtime;
out.id = newid;
out.distance = newdistance;
out.major = newmajor;
out.minor = newminor;
out.rssi = newrssi;
out.name = newname;
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = data.initial_time_stamp + pretrigger;
end