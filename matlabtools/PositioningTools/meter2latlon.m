function out  = meter2latlon(lat,lon,posx,posz,R)

%Function to get the lat lon position from indoor positioning
%This functiongrabs the delivered lat & long position, and adds the x y
%meters on top of this lat long position, taking the circumference of the
%earth into account.
%
%The function outputs a single structure containing:
%
%out.lat              = Estimated X position of participant
%out.lon              = Estimated Y position of participant
%
%Mandadory confuguration options are:
%lat            = Starting latitude used for calculating geodata
%lon            = Starting longitute used for calculating geodata
%posx           = x position of the meters to be added
%posz           = z position of the meters to be added
%
%Non-mandadory confuguration options are:
%R              = the radius of the earth, this is not mandatory
%
%Wilco Boode: 04-12-2019
%PLACE EXACT DESCRIPTION FOR MATLAB PROGRAMMERS HERE

%If the Radius is not defined, then the radius will be set by the function.
if ~exist('R','var')
    R=6378137;
end


dLat = posz/R;
dLon = posx/(R*cos(pi*lat/180));
out.lat = lat + dLat * 180/pi;
out.lon = lon + dLon * 180/pi;

end