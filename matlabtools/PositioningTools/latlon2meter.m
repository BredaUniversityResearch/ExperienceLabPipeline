function out  = latlon2meter(lato,lono,latd,lond,R)
%
%Function to get the x z position in meters from the lat and long positions
%This function creates a distance calculation based on the the starting lat/lon 
%position, and the current data lat/lon, to calculate grids and generate
%indoor mappable data
%
%The function outputs a single structure containing:
%
%out.x              = Estimated X position of participant
%out.z              = Estimated Z position of participant
%
%Mandadory confuguration options are:
%lato            = Starting latitude
%lono            = Starting longitute
%latd            = Latitude of the data
%lond            = Longitude of the data
%
%Non-mandadory confuguration options are:
%R              = the radius of the earth, this is not mandatory
%
%Wilco Boode: 12-03-2021
%PLACE EXACT DESCRIPTION FOR MATLAB PROGRAMMERS HERE
%12-03-2021 - Added output in lat/lon as well, as its more sensible in some
%situations

%If the Radius is not defined, then the radius will be set by the function.
if ~exist('R','var')
    R=6378137;
end

dLat = lato * pi / 180 - latd * pi / 180;
dLon = lono * pi / 180 - lond * pi / 180 ;
out.z = dLat*R;
out.x = dLon*(R*cos(pi*lato/180));
out.lat = dLat*R;
out.lon = dLon*(R*cos(pi*lato/180));
end