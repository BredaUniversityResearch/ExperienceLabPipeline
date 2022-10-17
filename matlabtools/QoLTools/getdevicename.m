function out = getdevicename(cfg)
%function out = getdevicename(cfg)
%
%This function allows the user to compare and create a column with deviceIDs based on its name. 
%It is specifically meant to more easily add empatica IDs to your participant
%data sheet, as that will simplify the process of looking for the devices
%in the Empatica Manager.
%
%Currently recognised situations.
%   100     (just numbers) = Recognized as EL0100
%   EL100   ("el EL El eL" prefix + and any amount of numbers) = Recognized
%           as EL0100
%   Z3      ("Z z" prefix + number) = Recognized as Z3
%
%Excel Format:
%An excel file with 2 columns, the existing sheet with ExperienceLab owned
%devices can be found in Teams -> Experience Lab Team -> General Channel ->
%Files Tab -> Inventory Folder ("EmpaticaNames.xlsx")
%   DeviceName = A column with all the names of the devices (EL0001 in case of the ExpLab)
%   DeviceID =  A column with the actual ID of the device (A01201 for example)
%
%ParticipantData:
%An excel sheet with a row per participant, containing AT LEAST the
%following two columns
%   DeviceName = A column with all the names of the devices (during session, you wrote down you have device EL1, 1, EL0001)
%   DeviceID =  A column without any data, this column will be filled with
%               the required IDs
%
%cfg (mandatory)
%cfg.DeviceList = "EmpaticaNames.xlsx"; = String with path of devicelist
%cfg.ParticipantData = "ParticipantData.xlsx"; = String with path of participantdata
%cfg.DeviceNameColumn = 6; = Index of the row DeviceName in the participantdata
%cfg.DeviceIDColumn = 7; = Index of the row DeviceID in the participantdata
%
% Wilco 27/06/2022

%read the excel file with device names & ids
DeviceList = readtable(cfg.DeviceList);

%read and format the excel file with participant data
fileName = cfg.ParticipantData;
opts = detectImportOptions(fileName);
opts.VariableTypes{cfg.DeviceNameColumn} = 'string';
opts.VariableTypes{cfg.DeviceIDColumn} = 'string';
ParticipantData = readtable(fileName,opts);

%Set the correct fields to read and set the devicename/id in the ParticipantData
fields = fieldnames(ParticipantData);
DeviceNameField = fields{cfg.DeviceNameColumn};
DeviceIDField = fields{cfg.DeviceIDColumn};

%maintain a list with all devices that could not be properly placed
missing = 0;

%loop over all participants
for isamp=1:height(ParticipantData)
    
    %filter based on data type, and prefix, what the deviceName is expected
    %to be
    if isnumeric(ParticipantData.(DeviceNameField)(isamp))
        DeviceName = sprintf('EL%04d', ParticipantData.(DeviceNameField)(isamp));
    else 
        if isnan(str2double(ParticipantData.(DeviceNameField)(isamp)))
            if  regexp(ParticipantData.(DeviceNameField)(isamp),"(?i)^EL(?i)") == 1
                DeviceName = sprintf('EL%04d', str2num(extractAfter(ParticipantData.(DeviceNameField)(isamp),2)));
            elseif  regexp(ParticipantData.(DeviceNameField)(isamp),"(?i)^Z(?i)") == 1
                DeviceName = strcat('Z', str2num(extractAfter(ParticipantData.(DeviceNameField)(isamp),1)));
            else
                warning(strcat('DO NOT RECOGNIZE PREFIX, SKIPPING PARTICIPANT ON INDEX: ',num2str(isamp)));
                missing = missing+1;
                ParticipantData.(DeviceIDField)(isamp) = "unknown";
                continue
            end
        else
            DeviceName = sprintf('EL%04d', str2double(ParticipantData.(DeviceNameField)(isamp)));
        end
    end    

    %Go over all devices in the devicelist, and compare the devicename to find the corresponding id 
    for jsamp=1:height(DeviceList)
        if strcmp(DeviceName,DeviceList.DeviceName(jsamp))
            ParticipantData.(DeviceIDField)(isamp) = string(DeviceList.DeviceID{jsamp});
            break
        end
        if jsamp == height(DeviceList)
            warning(strcat('CAN NOT FIND DEVICE IN LIST, SKIPPING PARTICIPANT ON INDEX: ',num2str(isamp)));
            missing = missing+1;
            ParticipantData.(DeviceIDField)(isamp) = "unknown";
        end
    end
end

%Provide a warning about all missing / unrecognized devices
warning(strcat('COULD NOT FIND OR RECOGNIZE DEVICES FOR: ',num2str(missing), ' PARTICIPANTS!'));

%output the table with updated deviceID column
out = ParticipantData;
end