function out = segment_strava(cfg, data)
% function out = segment_strava(cfg, data)
% function to resegment the Strava data. Any time-points (pre-post trigger)
% outside of the duration of the datasource will be filled with i=1, i=end,
% or 0 values, to create an array equal to the length of the indicated
% pre-post trigger
%
% configuration options are:
% cfg.trigger_time: date string specifying the time point of interest (trigger point)
% cfg.pretrigger: time in seconds before trigger point
% cfg.posttrigger: time in seconds after trigger point
%
% Wilco Boode, 18-05-2020

%trigger time is the difference between the first time stamp, and the
%initial time in the data. It will in this case generate a number to indicate whether the
%indicated trigger time is before or after (- or +) the time stamp in the
%data
triggertime = etime(datevec(cfg.trigger_time),datevec(data.initial_time_stamp_mat));
disp(triggertime)

%pretrigger is the triggertime (indicated above) - the additional
%pretrigger time. (if cfg.pretrigger = 0, then pretrigger will be equal to
%triggertime.
pretrigger = triggertime-cfg.pretrigger;
disp(pretrigger)

%posttrigger is the time from triggertime onwards
if isnumeric(cfg.posttrigger)
    posttrigger = triggertime+cfg.posttrigger;
elseif strcmpi('EOF', cfg.posttrigger)
   posttrigger = data.time(numel(data.time));
else
    error('segment_position: cfg.posttrigger is not correctly specified. Type help segment_position for options');
end
disp(posttrigger)

%Create arrays for every datatype in the strava data, later filled by the
%looping functions
newtime = [];
newlat = [];
newlong = [];
newaltitude = [];
newdistance = [];
newspeed = [];
newspeed2 = [];
newpower = [];

%For all time before the trigger_time, fill the array with 0, or i=1 data
if (triggertime < 0)
    for i = 1:(-triggertime)*data.fsample
        newtime = [newtime,(i-1)*data.fsample];
        newlat = [newlat,data.lat(1)];
        newlong = [newlong,data.long(1)];
        newaltitude = [newaltitude,data.altitude(1)];
        newdistance = [newdistance,0];
        newspeed = [newspeed,0];
        newspeed2 = [newspeed2,0];
        newpower = [newpower,0];
    end
end

%For all data inside the pre and post trigger, fill the array with
%corresponding data from the original datasource
for  i = 1:numel(data.time)
    if (data.time(i) >= pretrigger) && (data.time(i) <=  posttrigger)
        newtime = [newtime,data.time(i)-pretrigger];
        newlat = [newlat,data.lat(i)];
        newlong = [newlong,data.long(i)];
        newaltitude = [newaltitude,data.altitude(i)];
        newdistance = [newdistance,data.distance(i)];
        newspeed = [newspeed,data.speed(i)];
        newspeed2 = [newspeed2,data.speed2(i)];
        newpower = [newpower,data.power(i)];
    end
end

%For all timepoints after the data ends, fill the array with i=end, or 0
%values, to fill up the rest of the array.
if (posttrigger > data.time(end)) 
    for i = 1:(posttrigger-data.time(end))*data.fsample
        newtime = [newtime,newtime(end)+(1/data.fsample)];
        newlat = [newlat,data.lat(end)];
        newlong = [newlong,data.long(end)];
        newaltitude = [newaltitude,data.altitude(end)];
        newdistance = [newdistance,0];
        newspeed = [newspeed,0];
        newspeed2 = [newspeed2,0];
        newpower = [newpower,0];
    end
end

%add all data to an output
out = data;
out.time = newtime';
out.lat = newlat';
out.long = newlong';
out.altitude = newaltitude';
out.distance = newdistance';
out.speed = newspeed';
out.speed2 = newspeed2';
out.power = newpower';
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = posixtime(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
end