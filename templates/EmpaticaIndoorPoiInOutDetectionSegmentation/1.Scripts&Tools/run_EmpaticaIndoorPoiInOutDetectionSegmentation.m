%% EmpaticaIndoorPoiInOutDetectionSegmentation
%script for analyzing Empatica & Indoor Beacon Data, where the In & Out
%moment are detected, Points of Interest are detected, and Data is
%automatically semented & output
%throughout the script, different functions are called and decribed.

%% DIRECTORY
%Remove all data currently in the workspace
clear;

%Get project directory, make sure the CURRENT FOLDER in MATLAB is the
%1.Scripts&Tools folder inside the PROJECT FOLDER
mydir  = pwd
idcs   = strfind(mydir,'\')
pdir = mydir(1:idcs(end)-1)

%% TIMES & PARTICIPANTDATA
% CHECK: Make sure that the ParticipantData.xlsx file is placed in the
% 0.RawData\ Directory
% Use above calculated directory is used to load the participant table
% including the data regarding start/end time and durations
participanttable = readtable([pdir,'\0.RawData\ParticipantData.xlsx'],"VariableNamingRule","preserve");

%% SETUP LOOP
% This loop checks the participanttable and performs pre-setup for the structure (to make upcoming
% loops smaller, and faster). This loop could later on also be used to already filter / check for
% issues in data files that are likely to break later loops. Another likely usecase will be to
% pre-setup starttime and duration etc, as to mitigate possible issues where the E4 is not in the
% project.
% CHECK: Make sure that the data per participant is placed in the
% \0.RawData\PARTICIPANTNUMBER(P09) directory. This must include all data
% used by the functions below (empatica, strava, beacon), using the correct
% naming convention and file structure

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = '';
loopname = 'data_setup';

for i=1:height(participanttable)
    
    %Get the number of this current participant
    participant = participanttable.Participant(i);
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if (participanttable.Include(i) == 1)
        if isfile([pdir,strcat('\2.ProcessedData\data_setup_',num2str(participant),'.mat')])
            p_data = load([pdir,strcat('\2.ProcessedData\data_setup_',num2str(participant),'.mat')]);
            if (exist('data_setup','var')==1)
                data_setup(length(data_setup)+1) = p_data.setup;
            else
                data_setup(1) = p_data.setup;
            end
        else
            addParticipant = true;
        end
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        %add the participant values. In this block we can also run per participant
        %checks and decide whether to add them or not based on the available data and folder
        %structure. For example, a pre-post check based on EDA data could be added
        setup.participant=participant;
        
        %DETECTED START_TIME and DURATION
        %For automatic detection of in-out times based on the beacon data
        cfg = []; 
        cfg.inbeacons = [14 16]; %The value of the beacons triggering the In moment, in correct order
        cfg.outbeacons = [23 14];%The value of the beacon striggering the Out moment, in correct order
        cfg.middlebeacon = 12; %A beacon largely viewed inside the 
        cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%03d', participant),'\'] %location of the participant phone data
        cfg.beaconDataFolder = [pdir,'\0.RawData\']; %location of the beacondata, containing beaconmeta and beaconpositions
        cfg.minstrength = 85; %lower = stronger signal (as its signal delay)  
        cfg.datagradient = colormap(jet);  
        cfg.prominence = 2.5;
        detectedinout = getinoutfrombeacons(cfg);
        setup.start_time = detectedinout.start_time;
        setup.duration = detectedinout.duration;
        
        %MANUAL START TIME AND DURATION
        %For manually setting in-out based on the ParticipantTable
        %setup.start_time = participanttable.('Start Time')(i);
        %setup.duration = participanttable.('Duration')(i);
        
        %add and sort the data to the combined output struct (AT LEAST 1 VARIABLE IS NECESSARY,
        %OTHERWISE THE SORT MIGHT NOT WORK AS INTENDED
        if (exist('data_setup','var')==1)
            data_setup(length(data_setup)+1) = setup;
        else
            data_setup(1) = setup;
        end
        data_setup = nestedSortStruct(data_setup,{'participant'});
        disp(strcat('Setup Data for subject:  ', num2str(participant)))
        
        % CLEAR AND SAVE
        % save current results to a separate file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants.
        save ([pdir,strcat('\2.ProcessedData\data_setup_',num2str(participant),'.mat')], 'setup');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_setup
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results of this block to a single .mat file
save ([pdir,'\2.ProcessedData\data_setup.mat'], 'data_setup'); % save all phasic and tonic data to matlab file
disp('Saved data_setup to .mat file')

%% IMPORT E4 LOOP
% This loop is used to import all relevant empatica data. in this step we also cut the empatica data
% to the desired length.
% CHECK: Make sure all empatica files are stored in the correct
% participant folders (ACC,BVP,EDA,HR,IBI,tags,TEMP)

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = loopname;
loopname = 'data_import';

if isfile([pdir,'\2.ProcessedData\data_setup.mat'])
    load([pdir,'\2.ProcessedData\data_setup.mat']);
else
    error('data_setup not Found, make sure you import before trying to edit data further');
end

% Loop over all participants that should be part of the final output, and
% perform the required actions
for i=1:length(data_setup)
    
    participant = data_setup(i).participant;
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if isfile([pdir,strcat('\2.ProcessedData\data_import_',num2str(participant),'.mat')])
        p_data = load([pdir,strcat('\2.ProcessedData\data_import_',num2str(participant),'.mat')]);
        data_import(i) = p_data.e4_full;
    else
        addParticipant = true;
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        % Import, Resample, and Segment all e4 data from empatica CSV files to matlab.
        cfg = []; % empty any existing configuration settings.
        cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%03d', participant)];
        cfg.trigger_time = data_setup(i).start_time;
        %cfg.trigger_time = participanttable.('Start Time')(ptableindex);
        cfg.pretrigger = 0;
        %cfg.posttrigger = participanttable.('Duration')(ptableindex);
        cfg.posttrigger = data_setup(i).duration;
        e4_full = e4full2matlab(cfg);
        
        %add the participant value to this field
        e4_full.participant=participant;
        e4_full.start_time = data_setup(i).start_time;
        e4_full.duration = data_setup(i).duration;
        
        %add the data to the combined output struct
        data_import(i) = e4_full;
        data_import = nestedSortStruct(data_import,{'participant'});
        
        disp(strcat('Imported E4 Data for subject:  ', num2str(participant)))
        
        % CLEAR AND SAVE
        % save current results to file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants.
        save ([pdir,strcat('\2.ProcessedData\data_import_',num2str(participant),'.mat')], 'e4_full');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_setup data_import
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results to file
save ([pdir,'\2.ProcessedData\data_import.mat'], 'data_import'); % save all phasic and tonic data to matlab file
disp('Saved data_import to .mat file')


%% E4 CORRECTION LOOP
%this loop only has to check if the data already exists, but does not need to check for the include
%tab, as that is arranged in the original import function
%
%In this loop the data from the e4 will be corrected

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = loopname;
loopname = 'data_corrected';

if isfile([pdir,'\2.ProcessedData\data_import.mat'])
    load([pdir,'\2.ProcessedData\data_import.mat']);
else
    error('data_import not Found, make sure you import before trying to edit data further');
end

for i=1:length(data_import)
    
    participant = data_import(i).participant;
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if isfile([pdir,strcat('\2.ProcessedData\data_corrected_',num2str(participant),'.mat')])
        p_data = load([pdir,strcat('\2.ProcessedData\data_corrected_',num2str(participant),'.mat')]);
        data_corrected(i) = p_data.e4_corrected;
    else
        addParticipant = true;
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        % Correct EDA data for motion artifacts
        cfg = []; % empty any existing configuration settings.
        cfg.timwin    = 20; % define the timewindow for artifact detection (default = 20)
        cfg.threshold  = 4; % define the threshold for artifact detection (default = 5)
        cfg.validationdata = data_import(i).acceleration(1:end,4); % data visualized under artifacts for validating the artifact (acceleration data)
        cfg.blockreplacement = "post"; % add replacement for blocks detected by the MIT EdaExplorer, can be "pre" "post" or "both"
        e4_corrected = artifact_eda(cfg, data_import(i));
        disp(strcat('Corrected Eda Data for subject: ', num2str(participant)))
        
        %add the data to the combined output struct
        data_corrected(i) = e4_corrected;
        data_corrected = nestedSortStruct(data_corrected,{'participant'});
        
        % CLEAR AND SAVE
        % save current results to file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants. Separate .mat files can later be combined by Marcel or
        % Wilco.
        save ([pdir,strcat('\2.ProcessedData\data_corrected_',num2str(participant),'.mat')], 'e4_corrected');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_setup data_import data_corrected
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results to file
save ([pdir,'\2.ProcessedData\data_corrected.mat'], 'data_corrected'); % save all phasic and tonic data to matlab file
disp('Saved data_corrected to .mat file')

%% E4 DECONVOLUTION LOOP
%this loop only has to check if the data already exists, but does not need to check for the include
%tab, as that is arranged in the original import function
%
%In this loop the data from the e4 will be corrected

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = loopname;
loopname = 'data_deconvolved';

if isfile([pdir,'\2.ProcessedData\data_corrected.mat'])
    load([pdir,'\2.ProcessedData\data_corrected.mat']);
else
    error('data_corrected not Found, make sure you import before trying to edit data further');
end

for i=1:length(data_corrected)
    
    participant = data_corrected(i).participant;
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if isfile([pdir,strcat('\2.ProcessedData\data_deconvolved_',num2str(participant),'.mat')])
        p_data = load([pdir,strcat('\2.ProcessedData\data_deconvolved_',num2str(participant),'.mat')]);
        data_deconvolved(i) = p_data.e4_deconvolved;
    else
        addParticipant = true;
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        cfg = []; % empty any existing configuration settings.
        cfg.tempdir = 'C:\Temp'; % define temporary directory for datafiles, C:/Temp = default
        e4_deconvolved = deconvolve_eda(cfg, data_corrected(i));
        disp(strcat('Deconvolved Eda Data for subject: ', num2str(participant)))
        
        %add the data to the combined output struct
        data_deconvolved(i) = e4_deconvolved;
        data_deconvolved = nestedSortStruct(data_deconvolved,{'participant'});
        
        % CLEAR AND SAVE
        % save current results to file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants. Separate .mat files can later be combined by Marcel or
        % Wilco.
        save ([pdir,strcat('\2.ProcessedData\data_deconvolved_',num2str(participant),'.mat')], 'e4_deconvolved');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_setup data_import data_corrected data_deconvolved
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results to file
save ([pdir,'\2.ProcessedData\data_deconvolved.mat'], 'data_deconvolved'); % save all phasic and tonic data to matlab file
disp('Saved data_deconvolved to .mat file')

%% POSITIONING LOOP
%this loop only has to check if the data already exists, but does not need to check for the include
%tab, as that is arranged in the original import function
%
%In this loop the data from the e4 will be corrected

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = loopname;
loopname = 'data_positioned';

if isfile([pdir,'\2.ProcessedData\data_deconvolved.mat'])
    load([pdir,'\2.ProcessedData\data_deconvolved.mat']);
else
    error('data_deconvolved not Found, make sure you import before trying to edit data further');
end

for i=1:length(data_deconvolved)
    
    participant = data_deconvolved(i).participant;
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if isfile([pdir,strcat('\2.ProcessedData\data_positioned_',num2str(participant),'.mat')])
        p_data = load([pdir,strcat('\2.ProcessedData\data_positioned_',num2str(participant),'.mat')]);
        data_positioned(i) = p_data.data_position;
    else
        addParticipant = true;
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        % Load beacon data from x file into matlab
        cfg = [];
        cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%03d', participant),'\']; %location of the participant phone data
        cfg.beaconfile = "beacon.csv"; %name of the participant phone data
        cfg.beaconDataFolder = [pdir,'\0.RawData\']; %location of the beacondata, containing beaconmeta and beaconpositions
        cfg.nullvalue = 10; %under which value (strength / power of beacon) should a beacon be discarded
        raw_beacon = beacon2matlab_unix(cfg);
        disp("imported beacon data for subject: " + participant)
        
        % Calculate position (x,y,x)
        cfg = [];
        cfg.strengthmin = 40; %minimum strength required to include a beacon
        cfg.strengthmax = 85; %maximum strength of a beacon
        cfg.txpower = -62; %general txpower of a beacon, for Exp Lab, this is considered -62
        cfg.usegeodata = false; %do you want to calculate the lat lon position of the data (only possible for meter based calculations, preferably in The Netherlands)
        cfg.lat = 53.212143;  %starting lat position
        cfg.lon = 6.566574; %starting lon position
        positioned_beacon = position_beacon(cfg,raw_beacon);
        disp("Calculated 'exact' beacon position from beacon data for subject: " + participant)
        
        % Segment Beacon Data
        cfg = [];
        cfg.onset = data_deconvolved(i).start_time %participanttable.('Start Time')(ptableindex);
        cfg.offset = data_deconvolved(i).duration %participanttable.('Duration')(ptableindex);
        cfg.usegeodata = false; %whether this data uses geodata or not
        segmented_beacon = segment_beacon(cfg,positioned_beacon);
        disp(strcat('segmented beacon for subject: ', num2str(participant)))
        
        % Resample beacon data to EDA data sample rate
        cfg = [];
        cfg.fsample = 4; %new sample rate to resample to
        cfg.stringNames = vertcat(); %names of string based data, this could be used for nearestBeacon data
        cfg.doubleNames = vertcat("x","y","z","z_inv"); %names of double / number data, these are the positions
        cfg.beaconNames = vertcat(segmented_beacon.beaconnames);
        resampled_beacon = resample_beacon(cfg,segmented_beacon);
        disp(strcat('Resampled beacon data for subject: ', num2str(participant)))
        
        % Create POI data based on the previously calculated datafiles
        cfg = [];
        cfg.datafolder = [pdir,'\0.RawData\']; %location of the participant phone data
        cfg.poifile = "POIMeta.xlsx"; %name of the participant phone data
        cfg.mapfile = "map.png";
        cfg.mapmetafile = 'mapmeta.xlsx';
        cfg.zname = 'z_inv';        
        poi_beacons = getindoorpoi(cfg,resampled_beacon);
        disp(strcat('Made POI of beacon data for subject: ', num2str(participant)))
        
        %Combine the data in a single structure, you can add or
        %remove data from these lists to change the output. data1names is the
        %default list for E4 Data, cfg.data2names is the default list for
        %outdoor data.
        cfg.data2names = {'initial_time_stamp';'initial_time_stamp_mat';'fsample';'time';'conductance';'conductance_z';'phasic';'phasic_z';'tonic';'tonic_z';'bvp';'heartrate';'temperature';'acceleration';'event';'orig';'analysis';'eventchan';'participant'};
        data_position = combine_data(poi_beacons, data_deconvolved(i), cfg);
        
        %add the data to the combined output struct
        data_positioned(i) = data_position;
        data_positioned = nestedSortStruct(data_positioned,{'participant'});
        
        % CLEAR AND SAVE
        % save current results to file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants. Separate .mat files can later be combined by Marcel or
        % Wilco.
        save ([pdir,strcat('\2.ProcessedData\data_positioned_',num2str(participant),'.mat')], 'data_position');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_setup data_import data_corrected data_deconvolved data_positioned
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results to file
save ([pdir,'\2.ProcessedData\data_positioned.mat'], 'data_positioned'); % save all phasic and tonic data to matlab file
disp('Saved data_positioned to .mat file')

%% EXTRA LOOP
%This is an extra loop, showing how we can plugin more data tools into our pipeline. In this case,
%we add an average for every participant, and add data from a predefined column in the
%ParticipantData sheet.

%define the data loop names, to (in the future) more easily add loops without manually altering the
%names everywhere.
p_loopname = loopname;
loopname = 'data_extra';

if isfile([pdir,'\2.ProcessedData\data_positioned.mat'])
    load([pdir,'\2.ProcessedData\data_positioned.mat']);
else
    error('data_positioned not Found, make sure you import before trying to edit data further');
end

for i=1:length(data_positioned)
    
    participant = data_positioned(i).participant;
    ptableindex = find(participanttable.('Participant') == participant);
    
    %Check if the participant has to be included in the project, if so, check if the data has
    %allready been processed (when its in the processeddata folder), if so, then its added to the
    %overall output file, if not, then it will be added later
    addParticipant = false;
    if isfile([pdir,strcat('\2.ProcessedData\data_extra_',num2str(participant),'.mat')])
        p_data = load([pdir,strcat('\2.ProcessedData\data_extra_',num2str(participant),'.mat')]);
        data_extra(i) = p_data.data_edited;
    else
        addParticipant = true;
    end
    
    if (addParticipant == true)
        disp(strcat('Current Participant: ',num2str(participant)));
        
        data_edited = data_positioned(i);
        
        %Grab the summary column from the participanttable, and add it to this participant
        data_edited.setting = cell2mat(participanttable.Setting(ptableindex));
        
        %Calculate the Average, and add it to the structure for this participant
        data_edited.average = mean(data_edited.phasic);
        data_edited.average_z = mean(data_edited.phasic_z);
        
        %add the data to the combined output struct
        data_extra(i) = data_edited;
        data_extra = nestedSortStruct(data_extra,{'participant'});
        
        % CLEAR AND SAVE
        % save current results to file, this is done to make sure that any
        % false participants do not cause a complete data loss for previous
        % participants. Separate .mat files can later be combined by Marcel or
        % Wilco.
        save ([pdir,strcat('\2.ProcessedData\data_extra_',num2str(participant),'.mat')], 'data_edited');
        disp(strcat('Saved Participant ', num2str(participant),' Data to .mat file'))
        
        %Clear the non-required data.
        clearvars -except pdir i loopname p_loopname participanttable data_extra data_setup data_import data_corrected data_deconvolved data_positioned
    end
end
% SAVE FINAL OUTPUT STRUCTURE
% save combined results to file
save ([pdir,'\2.ProcessedData\data_extra.mat'], 'data_extra'); % save all phasic and tonic data to matlab file
disp('Saved data_extra to .mat file')

%% GRAND AVERAGING
%Creating grand averages over the final output file. This adds a participant called -1, which
%contains the grand average over all participants in the provided data structure.
cfg = [];
cfg.datatypes = ["conductance" "phasic" "tonic" "conductance_z" "phasic_z" "tonic_z"];
data_averaged = getgrandaverages(data_extra,cfg);

%% AVERAGING


%% SAVE FINAL MAT
% save final results to a matlab file
data_final = data_averaged;
save ([pdir,'\2.ProcessedData\data_final.mat'], 'data_final'); % save all phasic and tonic data to matlab file
disp('Saved data_final to .mat file')

%% SAVE CSV
% Save the data into a long csv format
% Make sure all datanames are either single values, or arrays of the same
% length for the entire participant (example 1x4556, or 4556x1)
cfg = [];
cfg.savename = 'Template_EmpaticaIndoor.csv';
cfg.datanames = {'participant' 'initial_time_stamp' 'initial_time_stamp_mat' 'fsample' 'time'  'conductance' 'conductance_z' 'phasic' 'phasic_z' 'tonic' 'tonic_z' 'bvp' 'heartrate' 'temperature' 'setting' 'average' 'x' 'y' 'z' 'z_inv' 'currentpoi'};
cfg.savelocation = [pdir,'\2.ProcessedData'];
export2csv(cfg, data_final);
disp('Saved data to .csv file')

s = scatter(data_final(1).x,data_final(1).z, 2,data_final(1).time);
cb = colorbar();
