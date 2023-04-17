function out  = position_beacon(cfg, data)
%% POSITION BEACON
%function out  = position_beacon(cfg, data)
%
% *DESCRIPTION*
%Function used to calculate the position of the participant from the imported data
%This function looksat the, in the importer defined, beacon, meta, and
%position data, then uses that to estimate the position of the user within
%the beacons that are in reach
%
% *INPUT*
%Configuration Options
%cfg.coefficient    = (OPTIONAL) Coefficients used for calculating distance from
%point, these are mostly pre-set based on Exp Lab Estimote Beacon Settings
%cfg.txpower        = (OPTIONAL)  The power of the beacons
%cfg.strengthmin    = (OPTIONAL)  This is the lowest signal strength considered for
%calculating position
%cfg.strengthmax    = (OPTIONAL) This is the highest signal strength considered for
%calculating position
%cfg.usegeodata     = (OPTIONAL) Must be set to true if geodata format must be used.
%This then also requires cfg.lat and cfg.lon to be included
%cfg.lat            = (MANDATORY WHEN USEGEODATA = true) Starting latitude used for calculating geodata
%cfg.lon            = (MANDATORY WHEN USEGEODATA = true) Starting longitute used for calculating geodata
%
%Data Requirements
%The beacon2matlab data importer has a specific format, you should stick to
%that structure / data, or use that importer to get the correct format
%
% *OUTPUT*
%The function outputs the structure you provided, adding:
%out                = Original data is part of the out structure
%out.x              = Estimated X position of participant
%out.y              = Estimated Y position of participant
%out.z              = Estimated Z position of participant
%out.z_inv          = Estimated Z_Inv position of participant
%out.datatype       = original datatype name + '_position';
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode: 11-11-2019

%% DEV INFO
%Lowest beacon value is currently unused. Should add a configuration for
%"weighted, nearest, both" to extend capabilities of this function
%   Maybe best to integrate use of the "nearest_beacon" function

%% VARIABLE CHECK
if ~isfield(cfg, 'coefficient')
    cfg.coefficient = [2.840314667 6.67786743 -0.455822126];
end
if ~isfield(cfg, 'txpower')
    cfg.txpower = -62;
end
if ~isfield(cfg,'strengthmin')
    cfg.strengthmin = 40;
end
if ~isfield(cfg,'strengthmax')
    cfg.strengthmax = 90;
end
if isfield(cfg,'usegeodata')
    if cfg.usegeodata == true
        if ~isfield(cfg,'lat')
            error('Starting Latitude Not Available')
        end
        if ~isfield(cfg,'lon')
            error('Starting Longitude Not Available')
        end
    end
else
    cfg.usegeodata = false;
end

beacons = data.beaconnames;


%% GET NEAREST BEACON
%Get the nearest beacon name & value of the data sample
%For every timepoint in data, cycle through all beacons (based on
%beaconName), and if the value is lower than the lowest stored value, then
%overwrite lowestvalue and lowestbeacon with these values. extend list at
%end of every cycle.
lValue = NaN(length(data.time),1);
lBeacon = strings(length(data.time),1);
for isamp=1: length(data.time)
    lowestvalue = NaN;
    lowestbeacon = "NaN";
    for jsamp=1:length(beacons)
        beacon = beacons{jsamp,1};
        value = data.beaconvalues.(beacon)(isamp);
        if isnan(lowestvalue)
            lowestvalue = value;
            lowestbeacon = beacon;
        elseif value < lowestvalue
            lowestvalue = value;
            lowestbeacon = beacon;
        end
    end
    lValue(isamp,1) = lowestvalue;%= [lValue,lowestvalue];
    lBeacon(isamp,1) = lowestbeacon;%= [lBeacon,lowestbeacon];
end


%% WEIGHT ALL BEACONS
%Loop over nearest beacon list
%Per timepoint store all beacon names within a predefined strengthrange (of
%the first beacon)
aPosition.X = NaN(length(data.time),1);
aPosition.Y = NaN(length(data.time),1);
aPosition.Z = NaN(length(data.time),1);
aPosition.Z_Inv = NaN(length(data.time),1);

for isamp=1: length(data.time)
    lBeacons = {};
    lDistance = [];
    
    totalDistance = 0;
    %beacons within range calculation
    for jsamp=1:length(beacons)
        beacon = beacons{jsamp,1};
        value = data.beaconvalues.(beacon)(isamp);
        if value > cfg.strengthmin && value < cfg.strengthmax
            distance = beacon_distance(-value, cfg.txpower, cfg.coefficient);
            lDistance = [lDistance;distance];
            lBeacons = [lBeacons,beacon];
            totalDistance = totalDistance + distance;
        end
    end
    
    %cBeaconNum = [];
    lWeight = NaN(length(lDistance),1);
    
    if length(lDistance) == 1
        lWeight(1) = 1;
    else
        for jsamp=1:length(lDistance)
            w1 = lDistance(jsamp)/totalDistance;
            w2 = 1-w1; %(totalDistance-w1)/totalDistance;
            
            lWeight(jsamp) = w2/(length(lDistance)-1);
        end
    end
     
    %disp(lWeight);
    
    x=0;
    y=0;
    z=0;
    z_inv=0;
    
    %weight calculation
    for jsamp=1:length(lBeacons)
        weight = lWeight(jsamp);
        cBeacon = sscanf(string(lBeacons(jsamp)),'b%d_%d');
        for ksamp=1:length(data.beaconMeta.BeaconID)
            if data.beaconMeta.Major(ksamp,1) == cBeacon(1,1)
                if data.beaconMeta.Minor(ksamp,1) == cBeacon(2,1)
                    x = x+(data.beaconMeta.x(ksamp,1)*weight);
                    y = y+(data.beaconMeta.y(ksamp,1)*weight);
                    z = z+(data.beaconMeta.z(ksamp,1)*weight);
                    z_inv = z_inv+(data.beaconMeta.z_inv(ksamp,1)*weight);
                    %cBeaconNum = [cBeaconNum;beaconMeta.ID(ksamp,1)];
                end
            end
        end
    end
    aPosition.X(isamp,1) = x;
    aPosition.Y(isamp,1) = y;
    aPosition.Z(isamp,1) = z;
    aPosition.Z_Inv(isamp,1) = z_inv;
end

%% ADD GEODATA

if cfg.usegeodata == true
    lat = NaN(length(aPosition.X),1);
    lon = NaN(length(aPosition.X),1);
    
    for isamp=1: length(aPosition.X)
        ll = meter2latlon(cfg.lat,cfg.lon,aPosition.X(isamp,1),aPosition.Z(isamp,1));
        lat(isamp,1) = ll.lat;
        lon(isamp,1) = ll.lon;        
    end
end

%Loop over the lBeacons list, and per beacon:
%use the beacon_distance for a rough estimate
%accumulate these values into one number
%get a per-beacon percentage (100- that number, since lower = better)
%create X,Y,Z,Z_Inv = 0
%To X,Y,Z,Z_Inv add beaconposition*percentage


%% CREATE OUTPUT

out = data;
%out.beaconMeta = data.beaconMeta;
out.x = aPosition.X;
out.y = aPosition.Y;
out.z = aPosition.Z;
out.z_inv = aPosition.Z_Inv;
if cfg.usegeodata == true
    out.lat = lat;
    out.lon = lon;
end
out.datatype = out.datatype +"_position";

end