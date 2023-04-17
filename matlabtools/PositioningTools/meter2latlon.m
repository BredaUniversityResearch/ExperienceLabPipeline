function out  = meter2latlon(lat,lon,posx,posz,R)
%% METER 2 LAT LONG
% function out  = meter2latlon(lat,lon,posx,posz,R)
%
% *DESCRIPTION*
%Function to get the lat lon position from indoor positioning
%This function adds the x y distance in meters to the provided lat lon
%position, taking the circumference of the earth into account.
%Keep in mind that the direction of the local coordinate system MUST point
%north for this to make sense.
%
% *INPUT*
%Configuration Options
%lat            = Starting latitude used for calculating geodata
%lon            = Starting longitute used for calculating geodata
%posx           = x position of the meters to be added
%posz           = z position of the meters to be added
%
%Non-mandadory configuration options are:
%R              = the radius of the earth, this is not mandatory
%
% *OUTPUT*
%The function outputs a single structure containing:
%out.lat              = Estimated X position of participant
%out.lon              = Estimated Y position of participant
%
% *NOTES*
%This function does not consider different projection formats
%
% *BY*
%Wilco Boode: 04-12-2019

%% DEV INFO
%NA

%If the Radius is not defined, then the radius will be set by the function.
if ~exist('R','var')
    R=6378137;
end


dLat = posz/R;
dLon = posx/(R*cos(pi*lat/180));
out.lat = lat + dLat * 180/pi;
out.lon = lon + dLon * 180/pi;

end