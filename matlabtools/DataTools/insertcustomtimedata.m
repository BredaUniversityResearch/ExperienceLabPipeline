function out = insertcustomtimedata(cfg, data)
%function out = insertcustomtimedata(cfg, data)
%Grabs an xlsx file, and allows the user to define custom time periods to
%add manual data to the participant using the long format. 
%WHAT DOES IT OUTPUT
%
%XLSX file structure requires the following columns
% Participant = Participant number as an integer (1)
% Start Time = Starting time in datetime (12-Jan-2019 11:49:00)
% Duration = How long the interaction takes in seconds (23)
% {DataName} = Additional columns with data to add (integer, float/double, string) 
%
%DATA file requires the following variables
% participant = Participant number as an integer (1) 
% time = one dimensional array of double values [0.250;0.500;0.750;1.000]
%
%CFG options
% cfg.customdatafile = datapath to an excel file with the correct structure
% cfg.datatypes = struct with desired datatypes to add, using the following format
%       datatypes(i).name = Column name of the data type
%       datatypes(i).type = Type of data (string, integer, float)
%
% Wilco Boode 10/06/2022

%% CHECK REQUIRED CFG VALUES
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