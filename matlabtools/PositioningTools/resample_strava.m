function out = resample_strava(cfg, data)
%% RESAMPLE STRAVA
%function out = resample_strava(cfg, data)
%
% *DESCRIPTION*
%This function can be used to resample the strava data. This is currently
%still a self-written resampler, and should be replaced with the Matlab
%build-in resample option at some point.
%
% *INPUT*
%Configuration Options
% cfg.fsample       =   desired fsample, must be provided
%
% *OUTPUT*
%Resampled strava data structure
%
% *NOTES*
%NA
%
% *BY*
% Wilco Boode 18/05/2020

%% DEV INFO
% this function should probably be deprecated and replaced by
% resample_generic, to create one function that can detect data types

%Check whether the desired fsample is defined, this value is mandatory
if ~isfield (cfg,'fsample')
    error('no sample frequency is defined for resample_strava');
end

newtime = [];
for i = 0: cfg.fsample * data.time(end)
    newtime = [newtime, i*(1/cfg.fsample)];
end

newlat = data.lat(1);
newlong = data.long(1);
newaltitude = data.altitude(1);
newdistance = data.distance(1);
newspeed = data.speed(1);
newspeed2 = data.speed2(1);
newpower = data.power(1);

time1 = 1;
time2 = 2;

%for every time value in newTime
for isamp=2:length(newtime)
    %get original time 1 and 2. 
    %If newTime(isamp) >= 1 and <= 2 then look whether current-1 or 2-current is lower, assign the value to that one 
    %else check 2 and 3, continue untill end is reached
    while newtime(isamp) > data.time(time2)
            time1 = time1+1;
            time2 = time2+1;
    end
        
    time1diff = newtime(isamp) - data.time(time1);
    time2diff = data.time(time2) - newtime(isamp);
    
    if (time1diff < time2diff)
       newlat = [newlat;data.lat(time1)];
       newlong = [newlong;data.long(time1)];
       newaltitude = [newaltitude;data.altitude(time1)];
       newdistance = [newdistance;data.distance(time1)];
       newspeed = [newspeed;data.speed(time1)];
       newspeed2 = [newspeed2;data.speed2(time1)];
       newpower = [newpower;data.power(time1)];
    else
       newlat = [newlat;data.lat(time2)];
       newlong = [newlong;data.long(time2)];
       newaltitude = [newaltitude;data.altitude(time2)];
       newdistance = [newdistance;data.distance(time2)];
       newspeed = [newspeed;data.speed(time2)];
       newspeed2 = [newspeed2;data.speed2(time2)];
       newpower = [newpower;data.power(time2)];    
    end      
end

out = data;
out.fsample = cfg.fsample;
out.time = newtime';
out.lat = newlat;
out.long = newlong;
out.altitude = newaltitude;
out.distance = newdistance;
out.speed = newspeed;
out.speed2 = newspeed2;
out.power = newpower;
end