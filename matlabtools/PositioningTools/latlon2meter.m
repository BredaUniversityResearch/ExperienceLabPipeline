function out  = latlon2meter(cfg)
%% LAT LON 2 METER
% function out = latlon2meter (cfg)
%
% *DESCRIPTION*
%Function to get the x z position in meters from the lat and long positions
%This function creates a distance calculation based on the the starting lat/lon 
%position, and the current data lat/lon, to calculate grids and generate
%indoor mappable data
%
% *INPUT*
%Configuration Options
%cfg.lato = Origin latitude
%cfg.lono = Origin longitute
%cfg.latd = Destination latitude
%cfg.lond = Destination longitude
%cfg.R = (OPTIONAL)the radius of the earth
%
% *OUTPUT*
%out.x = Estimated X position of participant
%out.z = Estimated Z position of participant
%
% *NOTES*
%
% *BY*
%Wilco Boode: 12-03-2021

%% DEV INFO
%12-03-2021 - Added output in lat/lon as well, as its more sensible in some
%situations

%% VARIABLE CHECK
%If the Radius is not defined, then the radius will be set by the function.
if ~isfield(cfg,'R')
    cfg.R=6378137;
end

%% CALCULATION & OUTPUT
dLat = cfg.lato * pi / 180 - cfg.latd * pi / 180;
dLon = cfg.lono * pi / 180 - cfg.lond * pi / 180 ;

out.z = dLat*cfg.R;
out.x = dLon*(cfg.R*cos(pi*cfg.lato/180));

out.lat = dLat*cfg.R;
out.lon = dLon*(cfg.R*cos(pi*cfg.lato/180));
end