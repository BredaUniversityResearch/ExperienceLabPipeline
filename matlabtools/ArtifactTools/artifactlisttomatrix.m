function out = artifactlisttomatrix(cfg,data)
%% ARTIFACT LIST TO MATRIX
% function out = artifactlisttomatrix (cfg,data)
%
% *DESCRIPTION*
%A function to turn a list of artifact locations into a x*2 matrix, where
%the first column contains the start-time, and the second column contains
%the end-time of an artifact.
%
% *INPUT*
%Configuration Options
%cfg.artifactvalue =   value identify as the artifactvalue, by default
%           this is set to -1 (default by EdaExplorer
%           (example: -1)
%cfg.time =   list of time-values, should be of the same
%           length as the data-list. Not defining this
%           value will create a 1hz list with same length
%           as the data (example: [0 0.25 0.5 0.75 1])
%
%Data Requirements
%data  =   list of artifactvalues (example: [1 1 -1 -1 1]
%
% *OUTPUT*
%a x*2 matrix, where the first column contains the start-time, and the 
%second column contains the end-time of an artifact.
%
% *NOTES*
%This function was originally developed to read artifact data retrieved by
%the EdaExplorer python function.
%
% *BY*
% Wilco Boode, 03-07-2020

%% DEV INFO
%The actual check can be optimized using the find== function, replace this
%to make the code more readable.

%% VARIABLE CHECK
%Check if artifactvalue is defined
if ~isfield(cfg, 'artifactvalue')
    cfg.artifactvalue = -1;
end
%check if time list is defined, if not a 1hz list is created
if ~isfield(cfg, 'time')
    cfg.time = transpose([1:length(data)]);
    warning ('ArtifactListToMatrix has no defined time, creating time list at 1hz');
end

%% DETECTION & RESTRUCTURING LOOP
%setup values needed for sorting
artifacts = [];
nextpos = 1;
lastvalue = -999;

%loop over data list
for x = 1: length(data)
    %define next value in list (necessary as we start with empty matrix)
    if ~isempty(artifacts)
        s = size(artifacts);
        nextpos = s(1)+1;
    end
    
    %Check if start of artifact is found
    if data(x) == cfg.artifactvalue && x == 1         
        artifacts(nextpos,1) = cfg.time(x);
    elseif data(x) == cfg.artifactvalue && lastvalue ~= cfg.artifactvalue
        artifacts(nextpos,1) = cfg.time(x);
        
    %Check if end of artifact is found
    elseif data(x) ~= cfg.artifactvalue && lastvalue == cfg.artifactvalue 
        artifacts(length(artifacts),2) = cfg.time(x);
    elseif data(x) == cfg.artifactvalue && x == length(data) 
        artifacts(length(artifacts),2) = cfg.time(x);
    end
    
    %Set the last value found in the data list
    lastvalue = data(x);     
end

%% FUNCTION END
%output the artifact matrix
out = artifacts;
end