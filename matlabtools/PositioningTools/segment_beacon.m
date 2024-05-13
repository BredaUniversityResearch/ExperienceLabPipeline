function out = segment_beacon(cfg,beaconData)
%% SEGMENT BEACON
%function out = segment_beacon(cfg,beaconData)
%
% *DESCRIPTION*
%function to segment the beacon data
%
% *INPUT*
%Configuration Options
% configuration options are:
% cfg.onset         = date string specifying the time point of interest (trigger point)ar
% cfg.offset        = time in seconds after trigger point
% cfg.usegeodata    = whether the data includes geodata (lat lon)
% cfg.nearestBeacon = whether the data also included nearestBeacon data   
%
% *OUTPUT*
%Segmented beacon data
%
% *NOTES*
%Additional information about the function, for example if parts have been
%retrieved from an online source
%
% *BY*
% Wilco Boode 18/05/2020

%% DEV INFO
%This function is a remnant from a different era and should be replaced by
%Segment_generic wherever possible. Might be good to just call
%segment_generic from this one and let that one figure things out.

onsetDifference = seconds(cfg.onset - beaconData.initial_time_stamp_mat);
offsetDifference = -(beaconData.time(length(beaconData.time))-(cfg.offset+onsetDifference));

if (onsetDifference < 0)
   warning(strcat('onset of participant starts "',num2str(-onsetDifference),'" seconds before the beacon data file'))
end
if (offsetDifference >0)%((onsetDifference+cfg.offset) > beaconData.time(length(beaconData.time)))
     warning(strcat('offset of participant ends "',num2str(offsetDifference),'" seconds after the beacon data file ends'))
    %error(strcat('offset of participant ends "',num2str((onsetDifference+cfg.offset)-beaconData.time(length(beaconData.time))),'" seconds after the beacon data file'))
end
if ~isfield(cfg,'nearestBeacon')
    cfg.nearestBeacon = false;
end
if ~isfield(cfg,'usegeodata')
    cfg.usegeodata = false;
end

beacons = beaconData.beaconnames;

if (onsetDifference<0)
    b1 = NaN(-onsetDifference*beaconData.fsample,1);
    newOnset = 0;
else
    b1 = NaN(0);
    newOnset = onsetDifference-1;
    if newOnset == -1
        newOnset = 0;
    end
end

if (offsetDifference>0)
    b2 = NaN((offsetDifference*beaconData.fsample),1);
    newOffset = beaconData.time(length(beaconData.time));
else
    b2 = NaN(0);
    newOffset = beaconData.time(length(beaconData.time))+offsetDifference;
end

for isamp=1:length(beacons)
    beacon = beacons{isamp,1};   
    beaconCut.(beacon) = vertcat(b1,(beaconData.beaconvalues.(beacon)((newOnset+1):(newOffset),1)),b2);
end

if cfg.nearestBeacon == true
    beaconPositions.nearestBeacon = vertcat(b1,(beaconData.nearestBeacon((newOnset+1):(newOffset),1)),b2);
    beaconPositions.nearestBeaconID = vertcat(b1,(beaconData.nearestBeaconID((newOnset+1):(newOffset),1)),b2);
end
if cfg.usegeodata == true
    beaconPositions.lat = vertcat(b1,(beaconData.lat((newOnset+1):(newOffset),1)),b2);
    beaconPositions.lon = vertcat(b1,(beaconData.lon((newOnset+1):(newOffset),1)),b2);
end

beaconPositions.x = vertcat(b1,(beaconData.x((newOnset+1):(newOffset),1)),b2);
beaconPositions.y = vertcat(b1,(beaconData.y((newOnset+1):(newOffset),1)),b2);
beaconPositions.z = vertcat(b1,(beaconData.z((newOnset+1):(newOffset),1)),b2);
beaconPositions.z_inv = vertcat(b1,(beaconData.z_inv((newOnset+1):(newOffset),1)),b2);

time = flip(rot90(0:cfg.offset));

out = beaconPositions;
out.beaconvalues = beaconCut;
out.time = time;
out.beaconmeta = beaconData.beaconmeta;
out.beaconnames = beaconData.beaconnames;
out.timeoff = seconds(cfg.onset - beaconData.initial_time_stamp_mat);
out.initial_time_stamp_mat = datetime(cfg.onset, 'Format', 'yyyy-MMM-dd HH:mm:ss');
out.initial_time_stamp = posixtime(out.initial_time_stamp_mat);
out.fsample = 1;
out.orig = beaconData.orig;
out.datatype = beaconData.datatype;
end