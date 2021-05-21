function out = dataseparator(data,cfg)
%% DATA SEPARATOR
% This is a simple script that takes the input datafile, loops over all rows, and separates the data
% per participantvalue. The function can then export all values as separate csv files for easier per participant
% separation with smaller files. The order will remain as in the original file, and can handle both
% clearly separated participants, as well as mixed participant data.
%
% Configuration Options:
% participantcolumn = the number of the column containing the participant name / value  | 5
% exportlocation = the folder where the data should be exported to | 'D:\Projectname\Data\EyeTracking\'
% 
% Wilco Boode, 21/05/2021

%% LOAD DATA
%if data is a string value, then it loads the datafile
if ischar(data)
    data = readtable(data,"VariableNamingRule","preserve");
end

%% SET STARTING VALUES
% set starting values, where possible from the cfg file
if isfield (cfg,'participantcolumn')
    p_column = cfg.participantcolumn;
else
   error('No Participant Column Defined, not possible to run if there is no known participant value'); 
end

if isfield (cfg,'exportlocation')
    exportlocation = cfg.exportlocation;
end

s_data = [];

%% LOOP AND SEPARTE DATA
% for every row, separate the data based on the participant value / name
for i=1:height(data)
    cur_p = string(cell2mat(table2cell(data(i,p_column))));
    
    if ~isfield(s_data,cur_p)
        s_data.(cur_p) = data(i,:);
    else
        s_data.(cur_p) = [s_data.(cur_p) ; data(i,:)];
    end        
end

%% EXPORT
% if there is an exportlocation, export individual participants data as csv files, based on the
% participantnames
if exist('exportlocation')
    names = fieldnames(s_data);
    for i=1:height(names)
        path = cell2mat(strcat(exportlocation,names(i),'.csv'));   
        writetable(s_data.(cell2mat(names(i))),path);
    end
end

%% OUTPUT
% return the struct containing all separated participants
out = s_data;

end