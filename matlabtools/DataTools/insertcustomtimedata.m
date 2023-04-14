function out = insertcustomtimedata(cfg, data)
%% INSERT ADDITIONAL LONG DATA
% function out = insertcustomtimedata (cfg,data)
%
% *DESCRIPTION*
%Uses a long format xlsx file to insert data into an existing data
%structure. Usefull if you have a data structure and an excel sheet with 
%additional data for multiple participants, and need to inject the data 
%from the excel sheet into the datastructure.
%
%Say i have a struct for a participant, and a final output excel where data
%from all my participants is stored. If I need to inject data from this
%excel sheet then I can use this function to do so based on Participant,
%StartTime, and Duration variables
%
%
% *INPUT*
%Excel File Requirements (COLUMS REQUIRED)
% Participant = Participant number as an integer (1)
% Start Time = Starting time in datetime (12-Jan-2019 11:49:00)
% Duration = How long the interaction takes in seconds (23)
% {DataName} = Additional columns with data to add (integer, float/double, string) 
%
%Configuration Options
% cfg.customdatafile = datapath to an excel file with the correct structure
% cfg.datatypes = struct with desired datatypes to add, using the following format
%       datatypes(i).name = Column name of the data type
%       datatypes(i).type = Type of data (string, integer, float)
%
%Data Requirements
%participant = Participant number as an integer (1) 
%time = one dimensional array of double values [0.250;0.500;0.750;1.000]
%
% *OUTPUT*
%The same structure as went in, but with the added data from the excel
%sheet
%
% *NOTES*
%N/A
%
% *BY*
% Wilco Boode 10/06/2022

%% VARIABLE CHECK
if ~isfield(cfg, 'datatypes')
    error(strcat("Column *datatypes* not defined, please provide datatypes"));
end
if ~isfield(cfg, 'customdatafile')
    error(strcat("Column *customdatafile* not defined, please provide path to the datafile"));
end

%% IMPORT DATA
%import the xlsx as a table
newdatatable = readtable(cfg.customdatafile,"VariableNamingRule","preserve");

%% SETUP STRUCTURE
%Create a newdata structure and populate it with an array for every
%indicated datatype, with the same length as time
newdata = [];
for isamp=1:length(cfg.datatypes)
    %check if the requested column exists, if not output a warning
    if strcmp(cfg.datatypes(isamp).name,newdatatable.Properties.VariableNames) == 0
        warning(strcat("Column *",cfg.datatypes(isamp).name,"* does not exist in the table and will be skipped"));
        continue
    end

    %check the desired data type and add a 1 dimensional array to the
    %struct of that type
    if strcmp(cfg.datatypes(isamp).type,"string")
        newdata.(cfg.datatypes(isamp).name) = strings(length(data.time),1);
    elseif strcmp(cfg.datatypes(isamp).type,"text")
        newdata.(cfg.datatypes(isamp).name) = strings(length(data.time),1);
    elseif strcmp(cfg.datatypes(isamp).type,"integer")
        newdata.(cfg.datatypes(isamp).name) = zeros(length(data.time),1,'int8');
    elseif strcmp(cfg.datatypes(isamp).type,"float")
        newdata.(cfg.datatypes(isamp).name) = zeros(length(data.time),1,'double');
    elseif strcmp(cfg.datatypes(isamp).type,"double")
        newdata.(cfg.datatypes(isamp).name) = zeros(length(data.time),1,'double');
    else
        warning(strcat("datatype *",cfg.datatypes(isamp).type,"* unknown, skipping: ",cfg.datatypes(isamp).name));
    end
end

%provide an error if the datatype correlations cannot be found
if isempty(newdata)
    error('NONE OF THE INDICATED DATAYPES CAN BE FOUND, PLEASE CHECK THE PROVIDED TYPES, AND THE DATAFILE, TO SEE IF THE COLUMN NAMES ARE CORRECT');
end

%% POPULATE STRUCTURE
%find the rows containing data for this participant
pindex = find(newdatatable.Participant == data.participant);
dnames = fieldnames(newdata);

%loop over every row / instance, and grab the time range
for isamp=1:length(pindex)
    %get the start & end time, then determine the correct range based on
    %the time ara in the original data 
    tstart = etime(datevec(newdatatable.("Start Time")(pindex(isamp))),datevec(data.initial_time_stamp_mat));
    tend = tstart+newdatatable.Duration(pindex(isamp));
    tindex = find(data.time >= tstart & data.time <= tend);

    %populate the range in the newdata elements with the corresponding values from the table
    for jsamp=1:length(dnames)
        newdata.(dnames{jsamp})(min(tindex):max(tindex)) = newdatatable.(dnames{jsamp})(pindex(isamp));
    end
end

%% CREATE OUTPUT
% create output, and add the newdata colums to it
out = data;
for isamp=1:length(dnames)
    out.(dnames{isamp}) = newdata.(dnames{isamp});
end

end