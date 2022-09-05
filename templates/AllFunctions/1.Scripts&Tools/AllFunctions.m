%% DATA LOCATION
% This is one of the default ways for the experience lab to grab the
% location of your data. These 3 lines will take your currently active
% folder, and show the folder above it. Using the default Experience
% FolderTemplate, this would give you the location of the project on your
% computer.
mydir  = pwd;
idcs   = strfind(mydir,'\');
pdir = mydir(1:idcs(end)-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PARTICIPANT INFO
% Participant info is stored in an excel sheet, containing the participant
% number, start / duration / end time, the timezone, whether to include
% that participant, and other important information, excluding personally
% identifiable information

% Read the excel file as a table
participanttable = readtable([pdir,'\0.RawData\ParticipantData.xlsx'],"VariableNamingRule","preserve");

% Get the row, and then determine which participant is in that row.
participantIndex = 1;
participant = participanttable.Participant(participantIndex);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EMPATICA
% The ExperienceLab has developed several tools for importing, and editing
% empatica data to be used in your own project. The data required for
% loading E4 data consists of the files downloaded and extracted from the
% ZIP available via the Empatica Connect Website.

% set participant to 1, which contains the EDA data
participantIndex = 1;
participant = participanttable.Participant(participantIndex);

%% Fully Automatic Function (e4full2matlab)
% This function will, based on the parameters, import, segment, and
% resample the provided data. In this case it will automatically resample
% all data to 4hz as thats the sample rate of the empatica EDA data we use

cfg = []; %empty array for configuration settings
cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', participant)]; %the folder containing the data
cfg.trigger_time = participanttable.("Start Time")(participantIndex); %the datetime when the session should start
cfg.posttrigger = participanttable.Duration(participantIndex); %the duration (seconds) of the session
e4_full = e4full2matlab(cfg);

%% Separate
% You can also call these manually, say you only want to work with EDA
% data, then you can use the following functions to:

%1. Import the EDA files
raw_eda = e4eda2matlab(cfg);

%2. Segment to the correct time-frame
segmented_eda = segment_generic(cfg, raw_eda);

%3. Resample to the desired frequency
cfg.fsample = 16; %change the desired new sampling rate
resampled_eda = resample_eda(cfg, segmented_eda);

%% Artifact Correction
%EDA data is impacted by motion, this can cause spiking artifacts in the
%data related to sudden body movements, and touching of the sensors. The
%Artifact Correction function detects possible artifacts, and provides an
%interface to edit and remove these artifacts.

cfg = []; % empty any existing configuration settings.
cfg.timwin    = 20; % define the timewindow for artifact detection (default = 20)
cfg.threshold  = 4; % define the threshold for artifact detection (default = 5)
cfg.validationdata = e4_full.acceleration(1:end,3); %set the data used for checking core data agains
e4_corrected = artifact_eda(cfg, e4_full);

%% Deconvolution
%The deconvolve step takes the provided EDA data, and deconvolves the data
%using Ledalab, a process of separating the EDA into a phasic and tonic
%signal which can be used for a final analysis.

cfg = []; % empty any existing configuration settings.
cfg.tempdir = 'C:\Temp'; % define temporary directory for datafiles, C:/Temp = default
e4_deconvolved = deconvolve_eda(cfg, e4_corrected);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% INDOOR BEACON DATA
%Indoor data can be used to separate data based on the location of the
%user. By constantly recording the signal strength of nearby beacons we can
%approximate the location of users within indoor locations, with relative
%accuracy.

% set participant to 2, which contains the indoor data
participantIndex = 2;
participant = participanttable.Participant(participantIndex);

%% Import
%Get the folder containing the data for this participant, as well as the
%metadata containing info about all beacons, and their physical location
%The current version MUST included the MetaData, as it transforms the data
%into an understandable format

cfg = [];
cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', participant),'\']; %location of the participant phone data
cfg.beaconfile = "beacon.csv"; %name of the participant beacon data
cfg.beaconDataFolder = [pdir,'\0.RawData\']; %location of the beacondata, containing beaconmeta and beaconpositions
cfg.nullvalue = 10; %under which value (strength / power of beacon) should a beacon be discarded
raw_beacon = beacon2matlab_unix(cfg);

%% Weighted Positioning
% Use the strength of the beacon signals to generate position, based on the
% weighted values of the available beaon signals. A Lat & Long

cfg = [];
cfg.strengthmin = 40; %minimum strength required to include a beacon
cfg.strengthmax = 80; %maximum strength of a beacon
cfg.txpower = -62; %general txpower of a beacon, for Exp Lab, this is considered -62
cfg.usegeodata = false; %do you want to calculate the lat lon position of the data (only possible for meter based calculations, preferably in The Netherlands)
cfg.lat = 53.212143;  %starting lat position
cfg.lon = 6.566574; %starting lon position
positioned_beacon = position_beacon(cfg,raw_beacon);
disp("Calculated 'exact' beacon position from beacon data for subject: " + participant)

%% Nearest Positioning
% Use the strength of the beacon signals to determine which beacon is
% nearest to the participant, and provide this in the output.

cfg = [];
cfg.usegeodata = true; %do you want to calculate the lat lon position of the data (only possible for meter based calculations, preferably in The Netherlands)
cfg.lat = 53.212143;  %starting lat position
cfg.lon = 6.566574; %starting lon position
nearby_beacon = nearest_beacon (cfg,raw_beacon);
disp("Calculated 'exact' beacon position from beacon data for subject: " + participant)

%% Segment Positioned Data
% Segmenting the beacon data requires you to separately segment the beacon
% values, and the position data, as the current segmenter does not look
% inside nested structs.

cfg = [];
cfg.starttime  = participanttable.("Start Time")(participantIndex); %participanttable.('Start Time')(ptableindex);
cfg.duration = participanttable.Duration(participantIndex); %participanttable.('Duration')(ptableindex);
segmented_beacon = segment_generic(cfg,positioned_beacon);

% Segment Beacon Values in Nested Struct
beaconvalues = positioned_beacon.beaconvalues;
beaconvalues.time = positioned_beacon.time;
beaconvalues.initial_time_stamp_mat = positioned_beacon.initial_time_stamp_mat;
segmented_beaconvalues = segment_generic(cfg,beaconvalues);
segmented_beacon.beaconvalues = rmfield(segmented_beaconvalues,["time";"initial_time_stamp_mat";"initial_time_stamp"]);

%% Resample Data
% Resampling the data can bring the frequency it in line for direct comparison
% with the other data sources, specifically the EDA data.

cfg = [];
cfg.fsample = 4; %new sample rate to resample to
cfg.stringNames = vertcat(); %names of string based data, this could be used for nearestBeacon data
cfg.doubleNames = vertcat("x","y","z","z_inv"); %names of double / number data, these are the positions
cfg.beaconNames = vertcat(segmented_beacon.beaconnames);
resampled_beacon = resample_beacon(cfg,segmented_beacon);

%% Indoor POI
% Create POI data based on the previously calculated beacon positions. This
% function takes the provided map, and the POI info (colors matching POI
% names as well as info on the map size) and calculates where the

cfg = [];
cfg.datafolder = [pdir,'\0.RawData\']; %location of the participant phone data
cfg.poifile = "POIMeta.xlsx"; %name of the participant phone data
cfg.mapfile = "map.png";
cfg.mapmetafile = 'mapmeta.xlsx';
poi_beacons = getindoorpoi(cfg,resampled_beacon);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OUTDOOR TCX (STRAVA) DATA
% Various apps can gather GPS position from Mobile Phone apps. The
% following section shows the functions used to retrieve and process data
% gathered via the Strava App. We currently only support the Strava TCX
% files, however this should also allow for importing TCX files from other 
% sources

% set participant to 3, which contains the indoor data
participantIndex = 3;
participant = participanttable.Participant(participantIndex);

%% Import TCX (Strava) Data
cfg = [];
cfg.datafolder = [pdir,sprintf('\\0.RawData\\P%02d', participant)]; %location of the strava data of this participant
cfg.stravafile = 'strava.tcx'; %name of the strava data (default = 'strava.tcx'
raw_strava = stravatcx2matlab(cfg);

%% Segment TCX Data
% Cut the tcx data to the defined on/offset
cfg.allowoutofbounds = 'true';
cfg.starttime  = participanttable.("Start Time")(participantIndex); %participanttable.('Start Time')(ptableindex);
cfg.duration = participanttable.Duration(participantIndex); %participanttable.('Duration')(ptableindex);
segmented_strava = segment_generic(cfg,raw_strava);

%% Resample TCX Data
% Resample the Strava data to the defined sampling rate

cfg.fsample = 4; %sampling frequency used to resample the strava data,
resampled_strava = resample_strava(cfg, segmented_strava);

%% Get TCX based POI
% Get the POI based on the GeoJson data, compares the Lat/Long position to
% a predetermined geojson file containing POI areas
cfg = [];
cfg.datafolder = [pdir,'\0.RawData\'];
cfg.poifile = 'poi.geojson';
poi_strava = getoutdoorpoi(cfg, resampled_strava);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ARTIFACT CORRECTION APP
%The artifact correction app allows you to provide an array, validation
%array, and list of potential artifacts, to show a UI where the user can
%confirm, deny, add, remove and merge artifacts, which will then be
%resolved using the chosen method.

%Define all artifacts using starttime and endtime
artifacts(1) = struct('starttime',2,'endtime',5);
artifacts(2) = struct('starttime',11,'endtime',15);

artifactcfg = [];
artifactcfg.artifacts = artifacts; %put the artifacts in the cfg
%artifactcfg.time = e4_full.time; %add the time array to the cfg
artifactcfg.artifactprepostvisualization = 15; %define the time before and after the artifact that should be shown in the zoomed artifact visualization
%artifactcfg.validation = e4_full.directionalforce; %include data shown in a secondary plot for comparing against
ArtifactApp = ArtifactCorrectionApp(e4_full.conductance,artifactcfg);

waitfor(ArtifactApp,'closeapplication',1)

Corrected_Data = ArtifactApp.solution;
delete(ArtifactApp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%