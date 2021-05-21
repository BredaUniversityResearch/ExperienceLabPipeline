function out = segment_strava(cfg, data)

triggertime = etime(datevec(cfg.trigger_time),datevec(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;

if isnumeric(cfg.posttrigger)
    posttrigger = triggertime+cfg.posttrigger;
elseif strcmpi('EOF', cfg.posttrigger)
   posttrigger = data.time(numel(data.time));
else
    error('segment_position: cfg.posttrigger is not correctly specified. Type help segment_position for options');
end

newtime = [];
newlat = [];
newlong = [];
newaltitude = [];
newdistance = [];
newspeed = [];
newspeed2 = [];
newpower = [];

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


out = data;
out.time = newtime;
out.lat = newlat;
out.long = newlong;
out.altitude = newaltitude;
out.distance = newdistance;
out.speed = newspeed;
out.speed2 = newspeed2;
out.power = newpower;
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = data.initial_time_stamp + pretrigger;
end