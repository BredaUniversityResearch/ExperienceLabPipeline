function out = resample_beacon(cfg, beaconData)
%% RESAMPLE BEACON
% function out = resample_beacon(cfg, beaconData)
%
% *DESCRIPTION*
% Function for resampling the beacon data, this function was written as a
% generic resampler, and could be used to resample other data as well,
% although this is not fully tested
%
% *INPUT*
%Configuration Options
% cfg.fsample       = new sample rate the data should be resampled to
% cfg.stringNames   = names of string data, by default this is assumed to be the nearest beacon and nearestBeacocnID data;
% cfg.doubleNames   = names of double data, by default this is assumed to be the x,y,z,z_inv data;
%
% *OUTPUT*
%Resampled beacon data structure
%
% *NOTES*
%NA
%
% *BY*
% Wilco Boode 18/05/2020

%% DEV INFO
% this function should probably be deprecated and replaced by
% resample_generic, to create one function that can detect data types

%defining the names of all arrays to be resampled
if ~isfield (cfg, 'stringNames')
    cfg.stringNames = vertcat("nearestBeacon","nearestBeaconID");
end
if ~isfield (cfg, 'doubleNames')
    cfg.doubleNames = vertcat("x","y","z","z_inv");
end
namelist = vertcat(cfg.doubleNames,cfg.stringNames);

%create struct for storing all new data in
newData  =[];

%set new list for time (by grabbing 0 - latest time, with interfals based
%on the fsample
newtime = 0:1/cfg.fsample:beaconData.time(length(beaconData.time));
newtime = flip(rot90(newtime));

%Defining the variable arrays for all string & double data that must be resampled
for isamp=1:length(cfg.stringNames)
    newData.(cfg.stringNames(isamp,1)) = strings(length(newtime),1);
end
for isamp=1:length(cfg.doubleNames)
    newData.(cfg.doubleNames(isamp,1)) = NaN(length(newtime),1);
end

%Run through the full length of the newtime array. For each data array copy the data nearest to the current newtime amount 
for isamp=1: length(newtime)
    for jsamp=1:length(namelist)
        newData.(namelist(jsamp,1))(isamp,1) = beaconData.(namelist(jsamp,1))(round(newtime(isamp))+1,1);                
    end           
end

if (isfield(cfg,'beaconNames'))
    for isamp=1:length(cfg.beaconNames)
        newData.beaconvalues.(cfg.beaconNames(isamp,1)) = NaN(length(newtime),1);
    end
    for isamp=1:length(newtime)
        for jsamp=1:length(cfg.beaconNames)
            newData.beaconvalues.(cfg.beaconNames(jsamp,1))(isamp,1) = beaconData.beaconvalues.(cfg.beaconNames(jsamp,1))(round(newtime(isamp))+1,1);                
        end           
    end
end
    
%save all output in a new (out) structure. Out is the original structure,
%with all resampled array overwriting their original arrays (namelist +
%time + fsample);
out = beaconData;
for jsamp=1:length(namelist)
      out.(namelist(jsamp,1)) = newData.(namelist(jsamp,1));
end
if (isfield(cfg,'beaconNames'))
    out.beaconvalues = newData.beaconvalues;
end
out.time = newtime;
out.fsample = cfg.fsample;
end