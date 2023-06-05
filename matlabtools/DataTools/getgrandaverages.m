function out = getgrandaverages (cfg, data)
%% GETGRANDAVERAGES
%function out = getgrandaverages (cfg, data)
%
% *DESCRIPTION*
%This function can create grand averages for fields in x*1 structs. It will
%automatically fill up arrays that are too short with NaN values. An
%standard deviation will be calculated for all indicated fields
%
% *INPUT*
%Configuration Options:
%cfg.fields =       Array with string values, containing the names of all 
%                   fields that you want to average
%                   example: ["conductance" "phasic"]
%cfg.std =          Whether you want to automatically include the std for
%                   each of the indicated fields (name will be
%                   fieldname_std)
%                   (Default = true / 1)
%   
%Data Structure:
%data = x*1 struct;
%
% *OUTPUT*
%This function will output a struct with the fields indicated in
%cfg.fields, the standard deviations of these fields, calculated time, and
%the fsample
%
% *NOTES*
%
%Wilco, 05-06-2023

%% VARIABLE CHECK
allfields = fieldnames(data);
if ~isfield(cfg,"fields")
    error("Fields not defined, please use cfg.fields to define which fields should be averaged")
end
if ~isfield(cfg,"std")
    cfg.std = true;
end

%% TO ADD
%1 std, make std and output as "fieldname_std"
%   do as default, so for all of them
%   possble to turn off, is off or on for all (apart from time, fsample)
%2 add fsample check for all participants
%

%% COMBINE ALL DATA IN A SHARED MATRIX AND MEAN OVER THAT MATRIX
c_data = [];
m_data = [];

if isfield(data,'fsample')
    for psamp = 1:length(data)
        if ~exist('fsample','var')
            fsample = data(psamp).fsample;
        else
            if fsample ~= data(psamp).fsample
                error("MISMATCH BETWEEN PARTICIPANT SAMPLE FREQUENCIES");
            end
        end
    end
else
    fsample = 1;
end

for type = 1:length(cfg.fields)
    if max(contains(allfields,cfg.fields(type))) == 1
        longest = 0;
        c_data = [];

        %Check the longers array in this field
        for p = 1:length(data)
            thislength = length(data(p).(cfg.fields(type)));
            if thislength > longest
                longest = thislength;
            end
        end

        %Combine all data of this field, and make of equal length using NaN       
        for p = 1:length(data)
            n_data = nan(1,longest);
            thislength = length(data(p).(cfg.fields(type)));
            n_data(1,1:thislength) = data(p).(cfg.fields(type));
            c_data = [c_data;n_data];
        end
        m_data.(cfg.fields(type)) = mean(c_data,'omitnan');
        if cfg.std == 1
        m_data.(strcat(cfg.fields(type),"_std")) = std(c_data,"omitmissing");
        end
    else
        warning(strcat(cfg.fields(type)," DOES NOT EXIST IN DATA FILE, SKIPPING FIELD FOR GRAND AVERAGING"));
    end
end

%% CREATE FINAL STRUCTURE
averagesstruct=[];
finalfields = fieldnames(m_data);
for isamp = 1:length(finalfields)
    averagesstruct.(finalfields{isamp}) = transpose(m_data.(finalfields{isamp}));
end

%% CREATE TIME BASED ON SAMPLES AND FSAMPLE
averagesstruct.fsample = fsample;

samples = length(averagesstruct.(cfg.fields(1)));
maxtime = (samples-1)/fsample;
averagesstruct.time = transpose(linspace(0,maxtime,samples));

%% FUNCTION END
out = averagesstruct;
end