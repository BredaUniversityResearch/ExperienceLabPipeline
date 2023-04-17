function out = upsample_beacon(original, newfsample)
warning('DEPRECATED, PLEASE DONT USE ANYMORE');
%SHOULD BE COMPLETELY DEPRECATED AND REPLACED BY RESAMPLE_GENERIC OR
%RESAMPLE_BEACON

%original = segmented_position
%newfsample = 7
%fsample = original.fsample
%NEEED TO DOCUMENT #WILCO2018

maxtime = original.time(end);
newtime = 0;
for isamp=1:(maxtime*newfsample) 
    newtime = [newtime;newtime(end)+(1/newfsample)];
end

newid = original.id(1);
newdistance = original.distance(1);
newmajor = original.major(1);
newminor = original.minor(1);
newrssi = original.rssi(1);
newname = original.name(1);

time1 = 1;
time2 = 2;

%for every time value in newTime
for isamp=2:size(newtime)
    %get original time 1 and 2. 
    %If newTime(isamp) >= 1 and <= 2 then look whether current-1 or 2-current is lower, assign the value to that one 
    %else check 2 and 3, continue untill end is reached
    while newtime(isamp) > original.time(time2)
            time1 = time1+1;
            time2 = time2+1;
    end
        
    time1diff = newtime(isamp) - original.time(time1);
    time2diff = original.time(time2) - newtime(isamp);
    
    if (time1diff < time2diff)
       newid = [newid;original.id(time1)];
       newdistance = [newdistance;original.distance(time1)];
       newmajor = [newmajor;original.major(time1)];
       newminor = [newminor;original.minor(time1)];
       newrssi = [newrssi;original.rssi(time1)];
       newname = [newname;original.name(time1)];
    else
       newid = [newid;original.id(time2)];
       newdistance = [newdistance;original.distance(time2)];
       newmajor = [newmajor;original.major(time2)];
       newminor = [newminor;original.minor(time2)];
       newrssi = [newrssi;original.rssi(time2)];
       newname = [newname;original.name(time2)];      
    end      
end
    
out.initial_time_stamp = original.initial_time_stamp;
out.initial_time_stamp_mat = original.initial_time_stamp_mat;
out.fsample = newfsample;
out.time = rot90(newtime);
out.id = rot90(newid);
out.distance = rot90(newdistance);
out.major = rot90(newmajor);
out.minor = rot90(newminor);
out.rssi = rot90(newrssi);
out.name = rot90(newname);
end