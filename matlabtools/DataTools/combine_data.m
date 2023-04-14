function out = combine_data(data1,data2,cfg)
%% COMBINE DATA
% function out = combine_data (cfg,data1,data2)
%
% *DESCRIPTION*
% A simple function that combines the data from 2 structures. 
% It is required to add two different data structures, and a cfg containing
% the names that should be combined
% If the same names are set for data1 and data2, then the data from data2
% will be used, discarding the data from data1.
%
% *INPUT*
%Configuration Options
% cfg.data1names = the names of the data that must be copied from datastruct1
% cfg.data2names = the names of the data that must be copied from datastruct2
%
% *OUTPUT*
%Structure combining the indicated data from the data1 and data2 structs
%
% *NOTES*
%if the cfg.data%names is nonexistent, then all fields will be copied over
%to the out struct
%if a field is not available in the datafile, then a warning will be
%provided, after which the function will continue to the next field
%if the same fields are copied for data1 and data2, then data2 will be the
%final 
%
% *BY*
%Wilco Boode 18-05-2020

%% DEV INFO
% Add option to 1. determine if duplicates must be exactly the same, and 2
% which of the data structs is dominant
% cfg.duplicatesmustmatch = if both data%names have the same fields, 
%           default = false;
% cfg.dominantdata = 
%           default = 1;
%if ~isfield(cfg, 'duplicatesmustmatch')
%    cfg.duplicatesmustmatch = false;
%end
%if ~isfield(cfg, 'dominantdata')
%    cfg.dominantdata = 1;
%end

%% VARIABLE CHECK
%checks whether the name fields are available, if not, it retrieves all
%field names in that struct
if ~isfield(cfg, 'data1names')
    cfg.data1names = fieldnames(data1);
end
if ~isfield(cfg, 'data2names')
    cfg.data2names = fieldnames(data2);
end

%% COMBINE STRUCTS
%copy all data with the requested names from data1
for i=1: length(cfg.data1names)
    if isfield(data1, cfg.data1names(i))
        new_struct.(cfg.data1names{i}) = data1.(cfg.data1names{i});
    else
        warning(strcat('Missing Variable: ',char(cfg.data1names(i)), ' in Data1'));
    end
end
%copy all data with the requested names from data2
for i=1: length(cfg.data2names)
    if isfield(data2, cfg.data2names(i))
        new_struct.(cfg.data2names{i}) = data2.(cfg.data2names{i});
    else
        warning(strcat('Missing Variable: ',char(cfg.data2names(i)), ' in Data2'));
    end
end

%% FUNCTION END
%copy all data to the out struct, used for outputting data from the
%function
out = new_struct;
end
