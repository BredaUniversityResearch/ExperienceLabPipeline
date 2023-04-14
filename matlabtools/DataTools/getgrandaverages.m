function out = getgrandaverages (cfg, data)
%% GETGRANDAVERAGES
%function out = getgrandaverages (cfg, data)
%
% *DESCRIPTION*
%This function can create grand averages for fields in x*1 structs. It will
%automatically fill up arrays that are too short with NaN values.
%
% *INPUT*
%Configuration Options:
%cfg.fields =       Array with string values, containing the names of all 
%                   fields that you want to average
%                   example: ["conductance" "phasic"]
%cfg.originaldata = determines whether the output contains the original data
%                   example: 0
%                   default: 0 (no)
%Data Structure:
%data = x*1 struct;
%
% *OUTPUT*
%This function will output a struct with the exact same fields as the input
%struct, where only the indicated fields will contain data (the average of
%all other structs that contain info).
%If originaldata is set to 1 (true) then the function will output all
%originaldata, with the averaged struct pasted at the bottom.
%If the original data contains a field called "participant", then the
%fieldvalue will be automatically set to 1
%
% *NOTES*
%
%Wilco, 21-02-2022

%% VARIABLE CHECK
if ~isfield(cfg,'originaldata')
    cfg.originaldata = 0;
end

allfields = fieldnames(data);

%% COMBINE ALL DATA IN A SHARED MATRIX AND MEAN OVER THAT MATRIX
c_data = [];
m_data = [];

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
    else
        warning(strcat(cfg.fields(type)," DOES NOT EXIST IN DATA FILE, SKIPPING FIELD FOR GRAND AVERAGING"));
    end
end

%% CREATE FINAL STRUCTURE
averagesstruct = struct();
for field = 1:length(allfields)
    fieldname = string(allfields(field));
    averagesstruct.(fieldname) = NaN;
    if ~isempty(intersect(cfg.fields,fieldname))
        averagesstruct.(fieldname) = m_data.(fieldname)';
    end
end 

if isfield(averagesstruct,'participant')
    averagesstruct.participant = -1;
end

%% FUNCTION END
if cfg.originaldata==1
    data(length(data)+1) = averagesstruct;
    out = data;
else
    out = averagesstruct;
end
end