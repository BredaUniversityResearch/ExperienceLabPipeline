function out = artifact_replacement(cfg,data)
%This function allows you to provide an original dataset (array), array of
%artifacts, and time, to visualize and replace the indicated artifact
%periods by a series of options. This function is meant to work well with
%the artifact2matlab, or artifactmat2matlab function, which provide an
%array of possible artifacts using a python package. This function will
%return a dataset containing the original data, the corrected data, and the
%array of time.
%
%Required is:
%data.artifacts         An array (preferred -1 for artifacts items, and 0 or 1 for non-artifacts)
%data.original          The original array of data, likely the original conductance file, however this can be any array
%data.time              An array with timestamps to visualize the artifact time
%
%Configuration Options:
%cfg.autocorrect = false;   %Do you want the script to automatically use the selected method to correct? or use the GUI to correct?
%cfg.fillmethod = "linear"; %Linear, NaN, custom, startpos, endpos, then autocorrect is false, then this will determine the default slected fillmethod
%cfg.customvalue = 0;       %Determines the default custom value used when setting fillmethod to custom
%cfg.artifactvalue = -1;    %Determines which value in artifact file is the artifact, by default this is (and should be) -1
%cfg.duration = 5;          %Not active at the moment, used for future expansion where sections of time can be corrected

%%
%Set non-determined configuration options
if ~isfield(cfg, 'autocorrect')
    cfg.autocorrect = false;
end
if ~isfield(cfg, 'fillmethod')
    cfg.fillmethod = "linear";
end
if ~isfield(cfg, 'customvalue')
    cfg.customvalue = 0;
end
if ~isfield(cfg, 'artifactvalue')
    cfg.artifactvalue = -1;
end
if ~isfield(cfg, 'duration')
    cfg.duration = 5;
end

%Provide errors when default data is not provided
if ~isfield(data, 'artifacts')
    error('artifact_replacement: artifacts not specified');
end
if ~isfield(data, 'original')
    error('artifact_replacement: original data not specified');
end
if ~isfield(data, 'time')
    data.time = linspace(1,(length(data.original)-1)/4,length(data.original));
    warning('artifact_replacement: time not specified, assuming 4hz');
end
%%
%This section cuts up the artifacts in blocks, allowing the correction to
%replace all between a pre-set start and end point.

%set empty start and end pos of detected artifact
endpositions = int16.empty;
startpositions = int16.empty;

%go through entire artifact
i = 1;
while i < length(data.artifacts)
    %if start of artifact detected set the startpos & look for end
    if (data.artifacts(i) == cfg.artifactvalue)
        startpos = i;
        %look for end of artifact
        for j=i:length(data.artifacts)
            %if end of artifact is detected, or end of file, then store
            %endpost and break the loop
            if data.artifacts(j) ~= cfg.artifactvalue
                endpos = j-1;
                break;
            end
            if j==length(data.artifacts)
                endpos = j;
                break;
            end
        end
        %change the startposition for searching for the next artifact to
        %the endposition of the previous artifact
        i = endpos+1;
        
        %store start and end in array for later processing of data
        startpositions = [startpositions;startpos];
        endpositions = [endpositions;endpos];
    else
        %if there is no artifact on this point, then just increase the loop
        i=i+1;
    end
end

%%
%This section will create an array for the corrected data, and replace the
%artifact sections if the user indicates this is necessary.

correcteddata = data.original;
%cycle through all endposition, and create a separate array to replace the
%possible artifact
workspace

for i=1:length(endpositions)
    startpos = startpositions(i);
    endpos = endpositions(i);
    clearvars artifactarray;
    
    %if autocorrect is true, then set the artifactarray to the array
    %belonging to that fill method
    if cfg.autocorrect == true
        if (cfg.fillmethod == "NaN")
            artifactarray = NaN(1,(endpos-startpos)+1);
        elseif (cfg.fillmethod == "linear")
            artifactarray = linspace(correcteddata(startpos),correcteddata(endpos),(endpositions(i)-startpos)+1);
        elseif (cfg.fillmethod == "startpos")
            artifactarray(1:1,1:(endpos-startpos)+1) = correcteddata(startpos);
        elseif (cfg.fillmethod == "endpos")
            artifactarray(1:1,1:(endpos-startpos)+1) = correcteddata(endpos);
        elseif (cfg.fillmethod == "custom")
            artifactarray(1:1,1:(endpos-startpos)+1) = correcteddata(cfg.customvalue);
        end
    else %if autocorrect is false, then show the app, and provide options for artifact correction
        openApp(data.time, data.original, correcteddata, startpos, endpos,num2str(i),num2str(length(endpositions)), cfg.fillmethod, cfg.customvalue);
        %ArtifactReplacementWindow(data.time, data.original, correcteddata, startpos, endpos,num2str(i),num2str(length(endpositions)), cfg.fillmethod, cfg.customvalue);
    end
    
    %if artifactarray exists, then correct the indicated section, if not,
    %then this will not be corrected (if the fillmethod is wrong, or
    %correction is skipped.
    if exist ('artifactarray', 'var')
        correcteddata(startpositions(i):endpositions(i)) = artifactarray;
    end
end

%%
%Set output to provide the original data, the timeseries, and the corrected
%data
out.original = data.original;
out.time = data.time;
out.corrected = correcteddata;
end

function openApp(time,original,correcteddata,startpos,endpos,current,total,method,value)
myApp = (ArtifactReplacementWindow(time,original,correcteddata,startpos,endpos,current,total,method,value));
    while(myApp.resumetofunction == false)
        pause(1);
    end
    
    if (myApp.correctdata == true)
        assignin('caller','artifactarray',myApp.artifactarray);
    end
    myApp.Close();
end