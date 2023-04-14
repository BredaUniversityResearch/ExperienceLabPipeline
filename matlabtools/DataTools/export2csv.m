function export2csv(cfg, data)
%% EXPORT 2 CSV
% function out = export2csv (cfg,data)
%
% *DESCRIPTION*
%Function to export the default Exp Lab structure to a long format CSV file
%
%The exporter automatically checks whether it can find data, based on
%either a matlab file, or a scr_data struct, meaning the function can be
%used as a standalone function, or at the end of a project file.
%
%The script automatically detect whether a readable data format is added.
%The script automatically detects and excludes data which can not be exported into a long format (structs inside the participant struct.
%The script automatically finds all data names, and maps them correspondedly as headers in the csv file
%The script automatically checks whether the data is  a matrix / row, and makes sure that single-property data is duplicated over the length of the long file, and that array data is correctly mapped on the long file
%
%Transposing the data from the current struct into a combined file is
%low-performance, however saving it into a csv file can take a long time
%dependand on the strength of the computer, large data files such as the
%Prison Escape (containing several million data points) can take 15-30
%minutes on the lab PC to export, please dont stop the process mid-way.
%
% *INPUT*
%Configuration Options
%cfg.datanames        : Cell array with characters, indicating the datanames to be exported. Not including this will cause the exporter to use all available data types instead
%                       example: cfg.datanames = {'participant' 'initial_time_stamp' };
%cfg.excludenames     : Cell array with characters, indicating datatypes to exclude from exporting, mostly handy when not utilizing the datanames config option.
%                       example: cfg.excludenames = {'event' 'eventchan'};
%cfg.savename         : Name of the csv file created by the exporter, not including this cfg option will cause the name to become 'data.csv'
%cfg.savelocation     : Location where the csv file is created, not utilizing this cfg option will cause the file to be saved in the folder currently active in matlab
%
%Data Requirements
%data (Mandatory) : Either character or data struct containing either the location + name of the data file, or full scr_data struct containing all participant data
%                       example character: 'C:\Users\data\wilco\test\testdata.mat'
%
% *OUTPUT*
%Outputs the final CSV structure to the indicated location and name
%
% *NOTES*
%This function works well with the format defined by the experience lab
%pipeline for multiple participants, we cannot promise this works well for 
%alternative data structures.
%
% *BY*
%Wilco 26-08-2019

%% VARIABLE CHECK
if ~isfield(cfg, 'savename')
    warning('No save name is set, using default name')
    cfg.savename = 'data.csv';
end
if ~isfield(cfg, 'savelocation')
    warning('No save name is set, using current folder')
end
if ~isfield(cfg, 'excludenames')
    cfg.excludenames = {};
end

%% GET DATA
%Set data, either from struct, or from a file, when data could not be
%identified, or when the struct is empty, an error will be shown
if isa(data, 'char')
    if isfile(data)
        raw_data = load(data);
        dataname = fieldnames(raw_data);
        raw_data = raw_data.(dataname{1});
    else
        error ("Data file cannot be found on computer.");
    end
elseif isa(data, 'struct')
    raw_data = data;
else
    error ("Could not identify data type");
end
if isempty(raw_data)
    error ("No data found in data struct");
end

%% DEFINE VARIABLES / NAMES OF DATA TO EXPORT
%Set all datanames to export, when no datanames are set, gather all
%datanames from the struct
if isfield(cfg,'datanames')
    datanames = cfg.datanames;
else
    datanames = fieldnames(raw_data);
end

%Check all datanames against data from p1, if the data is incompatible
%for exporting to CSV using LONG formatting then add it to the excludenames
arrayexample = datanames{1};
for ivar = 1: length(datanames)
    if ~(isnumeric(raw_data(1).(datanames{ivar})) || isstring(raw_data(1).(datanames{ivar})) || ischar (raw_data(1).(datanames{ivar})))
        if ~any(strcmp(cfg.excludenames,datanames{ivar}))
            cfg.excludenames = [cfg.excludenames datanames{ivar}];
        end
    else
        if ismatrix(raw_data(1).(datanames{ivar})) && length(raw_data(1).(datanames{ivar}))>1
            arrayexample = datanames{ivar};
        end
    end
end
if isfield(cfg, 'excludenames')
    for ivar = 1: length(cfg.excludenames)
        datanames(ismember(datanames,cfg.excludenames(ivar))) = [];
    end
end

%% ALLOCATION
%Set generic variables used for identifying the scale of the data for
%preallocating matrixes
participants = length(raw_data);
datatypes = length(datanames);
totaldatalength = 1;

%%
%Identify total data length for pre-allocation of matrix
for ivar = 1: length(raw_data)
    totaldatalength = totaldatalength +length(raw_data(ivar).(arrayexample));
end

%Set data headers based on data names
data_header = {};
for ivar = 1: datatypes
    data_header = [data_header datanames(ivar)];
end

%% 
%Pre-allocate empty matrix for optimization of data gathering process
combined_data=cell(totaldatalength,datatypes);

current_point_total = 1;

%% LOOP AND STRUCTURE DATA
%For every participant, for every data point, for every data type, check
%whether the current type is a row, and whether it is numeric, based on
%that determine how the data is copied and placed in the combined data
%struct.
for ivar = 1: participants
    current_point_participant = 1;
    
    for jvar = 1: length(raw_data(ivar).(arrayexample))
        for kvar = 1: datatypes
            if (isrow(raw_data(ivar).(datanames{kvar}))|| iscolumn(raw_data(ivar).(datanames{kvar}))) && length(raw_data(ivar).(datanames{kvar}))>1 && ~ischar(raw_data(ivar).(datanames{kvar}))
                if isnumeric(raw_data(ivar).(datanames{kvar}))
                    combined_data(current_point_total,kvar) = num2cell(raw_data(ivar).(datanames{kvar})(current_point_participant));
                else
                    combined_data(current_point_total,kvar) = cellstr(string(raw_data(ivar).(datanames{kvar})(current_point_participant)));
                end
            else
                if isnumeric(raw_data(ivar).(datanames{kvar}))
                    combined_data(current_point_total,kvar) = num2cell(raw_data(ivar).(datanames{kvar}));
                else
                    combined_data(current_point_total,kvar) = cellstr(string(raw_data(ivar).(datanames{kvar})));
                end
            end
        end
        
        current_point_participant = current_point_participant+1;
        current_point_total = current_point_total+1;
        
    end
end

%Combine the data in a table, required for saving to CSV with headers
cData = array2table(combined_data,'VariableNames',data_header);

%% SAVING

%if savelocation is available, open the indicated folder
if isfield(cfg, 'savelocation')
    cd (cfg.savelocation)
end

%Write the table to the csv file in the currently open folder
writetable(cData,cfg.savename,'Delimiter',',','QuoteStrings',false);

end
