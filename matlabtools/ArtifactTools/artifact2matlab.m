function out = artifact2matlab(cfg)
%% NAME OF FUNCTION
% function out = default_structure (cfg,data)
%
% *DESCRIPTION*
%function to read in Artifact data from the MIT Artifact detection function.
%This function calles the edaexplorer Artifact detection function using
%the Matlab to Python connection, and asks for the artifact detection
%function to detect artifacts within a 5-second window. This output
%provides: binaryArtifacts, which are artifact (-1), or no artifact (1), or multiclassArtifacts,
%which can be a n artifact (-1) possible artifact (0) or no artifact (1)
%
% *INPUT*
%Configuration Options
% cfg.artifactfile  = string specifying file that contains Artifact data in csv
%                     format
% cfg.datafolder    = string containing the full path folder in which the data file
%                     is retrieved and stored by the python library
% cfg.fsample  =      sample frequency desired for the artifact data, will
%                     set the artifactdata at the correct frequency,
%                     default = 4
% cfg.artifactName  = name of the datafile containing the artifacts, will
%                     output a json and csv file, default = ARTIFACT
% cfg.artifactType  = device the data is from, 'e4','biosemi','q','misc',
%                     default = e4
%
% *OUTPUT*
%Description of the output this function provides, both type of data, and
%potentialy the format it outputs
%
% *NOTES*
% Note that it is recommended to use the default configuration options for 
% cfg.artifactfile unless you have a good reason to deviate from that.
% Citation for Artifact Classification: Taylor, S., Jaques, N., Chen, W., Fedor, S., Sano, A., & Picard, R. Automatic identification of artifacts in electrodermal activity data. In Engineering in Medicine and Biology Conference. 2015
%
% *BY*
% Wilco Boode, 20-03-2020

%% VARIABLE CHECK
%Save current Folder Location
curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    error('empatica2matlab: datafolder not specified');
end
%check whether the samplerate is specified, if not set the defaults
if ~isfield(cfg, 'fsample')
    cfg.fsample = 4;
end
%check whether name for the artifactfile exists
if ~isfield(cfg, 'artifactName')
    cfg.artifactName = 'ARTIFACTS';
end
%check whether name for the artifactfile exists
if ~isfield(cfg, 'artifactType')
    cfg.artifactType = 'e4';
end

%% PYTHON CONNECTION & START PYTHON FUNCTION
%Load Python Classes
mod = py.importlib.import_module('edaexplorer.ArtifactDetection_matlab');
py.importlib.reload(mod);

%%retrieve artifact json from python function
artifactData = py.edaexplorer.ArtifactDetection_matlab.GetArtifactDataFromFolder(cfg.datafolder,cfg.artifactName,cfg.artifactType);

%% DECOODE AND STRUCTURE RETRIEVED ARTIFACTS
%decode json into matlab structure
artifactRaw = jsondecode(char(artifactData));

%decode cell arrays into double arrays
artifactRaw.StartTime = cell2mat(struct2cell(artifactRaw.StartTime));
artifactRaw.EndTime = cell2mat(struct2cell(artifactRaw.EndTime));
artifactRaw.BinaryLabels = cell2mat(struct2cell(artifactRaw.BinaryLabels));
artifactRaw.MulticlassLabels = cell2mat(struct2cell(artifactRaw.MulticlassLabels));

%set start an end time
initial_time_stamp = artifactRaw.StartTime(1);
initial_time_stamp_mat = datetime(datestr(unixmillis2datenum(initial_time_stamp)));
startTime = datetime(initial_time_stamp_mat);
endTime = datetime(datestr(unixmillis2datenum(artifactRaw.EndTime(length(artifactRaw.EndTime)))));

%get duration of artifact data, then create time array
totalSeconds = seconds(endTime-startTime);
totalSamples = totalSeconds * cfg.fsample;
time = rot90(flip(linspace(0,totalSeconds-(1/cfg.fsample),totalSamples)));

%create empty arrays for artifact arrays
binaryArtifacts = zeros(totalSamples,1);
multiclassArtifacts = zeros(totalSamples,1);

%resample / retarget the artifact data from original format to indicated
%sample rate
curArtifact = 1;
for i=1:totalSamples    
    cTime = time(i);
    artifactStart = (artifactRaw.StartTime(curArtifact)-artifactRaw.StartTime(1))/1000;
    artifactEnd = (artifactRaw.EndTime(curArtifact)-artifactRaw.StartTime(1))/1000;
    
    if artifactStart <= cTime && artifactEnd > cTime
        binaryArtifacts(i) = artifactRaw.BinaryLabels(curArtifact);
        multiclassArtifacts(i) = artifactRaw.MulticlassLabels(curArtifact);
    else        
        curArtifact = curArtifact + 1;
        binaryArtifacts(i) = artifactRaw.BinaryLabels(curArtifact);
        multiclassArtifacts(i) = artifactRaw.MulticlassLabels(curArtifact);
    end    
end

%% FUNCTION END
%output all data to the out structure
out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.fsample = cfg.fsample;
out.binaryArtifacts = binaryArtifacts;
out.multiclassArtifacts = multiclassArtifacts;
out.time = time;
out.timeoff = 0;
out.orig = cfg.datafolder;
out.datatype = "artifacts";
end 