function out  = nearest_beacon(cfg, beaconData)

%Function used to analyze beaconData from the beacon2matlab_unix function,
%and determine the nearest beacon based on Signal Strength & Beacon Name
%
%The function outputs a single structure containing:
%out.beaconMeta     = Original Data
%out.nearestBeacon  = Name of the neareast beacon at that time point
%out.nearestBeaconID  = ID of the neareast beacon at that time point
%out.x              = X position of nearest beacon
%out.y              = Y position of neareast beacon
%out.z              = Z position of neareast beacon
%out.z_Inv          = Z_Inv position of neareast beacon
%out.datatype       = original datatype name + '_nearest';
%cfg.usegeodata     = Must be set to true if geodata format must be used.
%This then also requires cfg.lat and cfg.lon to be included
%cfg.lat            = Starting latitude used for calculating geodata
%cfg.lon            = Starting longitute used for calculating geodata
%configuration options are not available, it will just grab the nearest
%beacon
%
%cfg.exportPosition = true/false statement whether the beacon position must be
%exported as well, this is on by default
%
%beaconData =               Data outputted from the beacon2matlab_new file.
%
% Wilco Boode: 07-02-2018

%PLACE EXACT DESCRIPTION FOR MATLAB PROGRAMMERS HERE
if ~isfield(cfg, 'exportPosition')
    cfg.exportPosition = true;
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

beacons = beaconData.beaconnames;

%Get the nearest beacon name & value of the beaconData sample
%For every timepoint in beaconData, cycle through all beacons (based on
%beaconName), and if the value is lower than the lowest stored value, then
%overwrite lowestvalue and lowestbeacon with these values. extend list at
%end of every cycle.
lValue = NaN(length(beaconData.time),1);
lBeacon = strings(length(beaconData.time),1);
for isamp=1: length(beaconData.time)
    lowestvalue = NaN;
    lowestbeacon = "NaN";
    for jsamp=1:length(beacons)
        beacon = beacons{jsamp,1};
        value = beaconData.beaconvalues.(beacon)(isamp);
        if isnan(lowestvalue)
            if value > cfg.strengthmin && value < cfg.strengthmax
                lowestvalue = value;
                lowestbeacon = beacon;
            end
        elseif value < lowestvalue && value > cfg.strengthmin && value < cfg.strengthmax
            lowestvalue = value;
            lowestbeacon = beacon;
        end
    end
    lValue(isamp,1) = lowestvalue;%= [lValue,lowestvalue];
    lBeacon(isamp,1) = lowestbeacon;%= [lBeacon,lowestbeacon];
end

%Retrieve & stire the X,Y,Z,Z_Inv of the nearest beacon, based on the beacon name
lPosition.x = NaN(length(lBeacon),1);
lPosition.y = NaN(length(lBeacon),1);
lPosition.z = NaN(length(lBeacon),1);
lPosition.z_inv= NaN(length(lBeacon),1);
lBeaconID = NaN(length(lBeacon),1);
for isamp=1: length(lBeacon)
    beacon = sscanf(string(lBeacon(isamp)),'b%d_%d');
    if isempty(beacon)
    
    else
        for jsamp=1: length(beaconData.beaconMeta.BeaconID)
            if beaconData.beaconMeta.Major(jsamp,1) == beacon(1,1)
                if beaconData.beaconMeta.Minor(jsamp,1) == beacon(2,1)
                    lBeaconID(isamp,1) = beaconData.beaconMeta.BeaconID(jsamp,1);
                    lPosition.x(isamp,1) = beaconData.beaconMeta.x(jsamp,1);
                    lPosition.y(isamp,1) = beaconData.beaconMeta.y(jsamp,1);
                    lPosition.z(isamp,1) = beaconData.beaconMeta.z(jsamp,1);
                    lPosition.z_inv(isamp,1) = beaconData.beaconMeta.z_inv(jsamp,1);
                    break;
                end
            end
        end
    end
end

if cfg.usegeodata == true
    lat = NaN(length(lPosition.x),1);
    lon = NaN(length(lPosition.x),1);

    for isamp=1: length(lPosition.x)
        ll = meter2latlon(cfg.lat,cfg.lon,lPosition.x(isamp,1),lPosition.z(isamp,1));
        lat(isamp,1) = ll.lat;
        lon(isamp,1) = ll.lon;
    end
end

%Store all beacon data in a final struct to send back to the user
out = beaconData;
out.nearestBeacon = lBeacon;
out.nearestBeaconID = lBeaconID;
if cfg.exportPosition == true
    out.x = lPosition.x;
    out.y = lPosition.y;
    out.z = lPosition.z;
    out.z_inv = lPosition.z_inv;
end
if cfg.usegeodata == true
    out.lat = lat;
    out.lon = lon;
end

out.datatype = out.datatype +"_nearest";

end