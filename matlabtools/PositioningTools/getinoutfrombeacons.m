function out = getinoutfrombeacons(cfg)
%function out = getinoutfrombeacons(cfg)
%This function can provide the onset and offset (start_time and duration) from the participant's
%Beacon file.
%
%Explanation Necessary
%
%Configuration:
%   cfg.inbeacon = 3; %The value of the beacon triggering the In moment
%   cfg.outbeacon = 12; %The value of the beacon triggering the Out moment
%   cfg.datafolder = 'D:\EXP_Lab\ExperienceLabPipelineGit\templates\EmpaticaIndoor\0.RawData\P01\'; %The location of the beacondata of this participant
%   cfg.beaconDataFolder = 'D:\EXP_Lab\ExperienceLabPipelineGit\templates\EmpaticaIndoor\0.RawData\'; %The location of the BeaconMeta file
%   cfg.beaconfile = 'beacon.csv'; %The name of the beacondata file of this participant
%   cfg.getdatafromfile = true; %Whether the data should be retrieved from the
%   cfg.beacondata = []; %If beacondata is not from file, then you can define your own beacondata. Requires the same structure as given by beacon2matlab_unix
%   cfg.prominence = 0.5; %Defines the prominence level of the beacon for removing insensible peaks. Default = 0.5. https://nl.mathworks.com/help/signal/ug/prominence.html
%   cfg.nullvalue = 10; %Under which value (strength / power of beacon) should a beacon value be discarded
%   cfg.checkdata = true; %Do you wish to show and evaluate the data before accepting the in/out moments?
%   cfg.minstrength = 80; %What is the minimal strength required to be a valid start/endpoint. Lower = stronger signal required (as its signal delay)
%
%Wilco, 21/06/2021

%% Checks for cfg Values
if (~isfield(cfg,'inbeacon'))
    if (isfield(cfg,'outbeacon'))
        warning('no in beacon indicated, assuming in and out beacon are the same');
        cfg.inbeacon = cfg.outbeacon;
    else
        error('no in/out beacons indicated')
    end
end
if (~isfield(cfg,'outbeacon'))
    if (isfield(cfg,'inbeacon'))
        warning('no out beacon indicated, assuming in and out beacon are the same');
        cfg.outbeacon = cfg.inbeacon;
    else
        error('no in/out beacons indicated')
    end
end
if (~isfield(cfg,'getdatafromfile'))
    cfg.getdatafromfile = true;
end
if (cfg.getdatafromfile)
    if (~isfield(cfg,'datafolder'))
        error('No datafolder defined');
    end
    if (~isfield(cfg,'beaconfile'))
        warning('No beaconfile defined, using the default (beacon.csv)');
        cfg.beaconfile = 'beacon.csv';
    end
    if (~isfield(cfg,'beaconDataFolder'))
        error('No beaconDataFolder defined');
    end
else
    if (~isfield(cfg,'data'))
        error('No beacon data defined');
    end
end
if (~isfield(cfg,'prominence'))
    cfg.prominence = 0.5;
end
if (~isfield(cfg,'nullvalue'))
    cfg.nullvalue = 10;
end
if (~isfield(cfg,'checkdata'))
    cfg.checkdata = true;
end
if (~isfield(cfg,'minstrength'))
    warning('minstrength not defined, using the default (80)');
    cfg.minstrength = 80;
end

%% Import Data
if (cfg.getdatafromfile)
    beaconData = beacon2matlab_unix(cfg);
else
    beaconData = cfg.beacondata;
end

%Inex and get data from in/out beacon (OLD)
inbeaconIndex = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacon));
outbeaconIndex = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacon));

indata = beaconData.beaconvalues.(inbeaconIndex);
outdata = beaconData.beaconvalues.(outbeaconIndex);


%Index and get data from beacons
beaconMap = containers.Map();

inbeaconsIndex = [];
for i =1 : length(cfg.inbeacons)
    inbeaconsIndex = [inbeaconsIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacons(i)))];
    beaconMap(string(cfg.inbeacons(i))) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacons(i)))
end

outbeaconsIndex = [];
for i =1 : length(cfg.inbeacons)
    outbeaconsIndex = [outbeaconsIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacons(i)))];
    beaconMap(string(cfg.outbeacons(i))) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacons(i)))
end

allbeaconsIndex = unique(vertcat(inbeaconsIndex,outbeaconsIndex))

midbeaconIndex = [];
midbeaconIndex = [midbeaconIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.middlebeacon))];
beaconMap(string(cfg.middlebeacon)) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.middlebeacon))

allbeaconsIndex = unique(vertcat(allbeaconsIndex,midbeaconIndex))

for k = keys(beaconMap)
    k
    beaconMap(k{1})
    allbeaconsData.(beaconMap(k{1})) = beaconData.beaconvalues.(beaconMap(k{1}))
end

%% InOut Detection
repeatdetection = 'y';
while (repeatdetection == 'y')
    
    %% Single In/Out beacon detection
    
    innandata = indata;
    innandata(innandata > cfg.minstrength) = NaN;
    [peaks,peakloc] = findpeaks(-innandata,'MinPeakProminence',cfg.prominence);
    if height(peakloc) == 0
        warning('No Input Peaks Found, using first timepoint');
        inpeak = beaconData.time(1)+1;
        cfg.checkdata = true;
    else
        inpeak = peakloc(1);
    end
    
    outnnandata = outdata;
    outnnandata(outnnandata > cfg.minstrength) = NaN;
    [peaks,peakloc] = findpeaks(-outnnandata,'MinPeakProminence',cfg.prominence);
    if height(peakloc) == 0
        warning('No Output Peaks Found, using last time point');
        outpeak = beaconData.time(height(beaconData.time))+1;
        cfg.checkdata = true;
    else
        outpeak = peakloc(height(peakloc));
    end
    
    if (outpeak < inpeak)
        warning('Out Time is before In Time');
        cfg.checkdata = true;
    end
    
    
    %% NEW SECTION / Multi beacon Detection
    % instead of just one beacon, we can take the seqence of nearestbeacons with values under the
    % threshold, we then check at what moments beacon 1, followed by beacon 2 was triggered, and
    % when beacon 2, followed by 1 were triggered. Then we checked whether middle-beacon was
    % triggered in between. This list can be regexped to check where this is the case.
    
    %121111233212111
    %The target sequence here is quite simple actually
    %12
    %Any numbers except 1, with minimal one 3
    %21
    %https://nl.mathworks.com/help/matlab/ref/regexp.html
    
    %0. make NaN list of size of beacons duration
    %1. make lists of all peak moments
    %2. combine, putting the peaks for all in/out beacons after another
    %3.
    
    %allbeaconsData
    
    fields = fieldnames (allbeaconsData);
    allpeaks = NaN(1,length(allbeaconsData.(string(fields(1)))));
    for k = keys(beaconMap)
        allbeaconsData.(beaconMap(k{1}))(allbeaconsData.(beaconMap(k{1})) > cfg.minstrength) = NaN;
        [peaks,peakloc] = findpeaks(-allbeaconsData.(beaconMap(k{1})),'MinPeakProminence',cfg.prominence);
        allpeaks(peakloc) = cellfun(@str2num,k);
    end
    
    allpeaksnonan = allpeaks
    allpeaksnonan(isnan(allpeaksnonan)) = [];
    %allbeaconsData
    
    %GetInPeak
    
    
    %GetOutPeak    
    
    %% In Out Visualization
    if (cfg.checkdata == true)
        
        fig = figure;
        
        hold on
        
        xmin = 0;
        xmax = length(beaconData.time);
        yrange = max(indata)-min(indata);
        ymin = clamp(min(indata) - (yrange/10),0,min(indata));
        ymax = max(indata) + (yrange/10);
        
        xlim([xmin xmax])
        ylim([ymin ymax])
        
        rectangle('Position',[xmin ymin xmax-xmin cfg.minstrength-ymin], 'FaceColor', '#d4ffe0');
        
        if (inbeaconIndex == outbeaconIndex)
            plot(beaconData.time,indata,'-k')
        else
            plot(beaconData.time,indata,'-b')
            plot (beaconData.time,outdata,'-r')
        end
        xline(inpeak,'--b')
        xline(outpeak,'--r')
        
        text(inpeak+1, max(indata), 'In', 'Color', 'blue');
        text(outpeak+1, max(indata), 'Out', 'Color', 'red');
        
        hold off
        
        %% In Out Threshold Change Option
        repeatset = 0;
        while repeatset == 0
            
            prompt = 'Do you want to change the threshold? y/n [n]: ';
            repeatdetection = strtrim(input(prompt,'s'));
            if isempty(repeatdetection)
                repeatdetection = 'n';
            end
            
            if repeatdetection == 'y'
                disp(strcat("Original Treshold: ", num2str(cfg.minstrength)));
                prompt = 'Set new Threshold: ';
                cfg.minstrength = input(prompt);
                disp("Restarting Detection");
                repeatset = 1;
                
            elseif repeatdetection == 'n'
                disp("Finishing Detection");
                repeatset = 1;
                
            else
                disp("Invalid Input, ");
                
                repeatset = 0;
            end
        end
        
        if ishandle(fig)
            close(fig)
        end
        
    else
        repeatdetection = 'n';
    end
end

%% Set Out Values based on Inpeak and Outpeak
out.duration = beaconData.time(outpeak)-beaconData.time(inpeak);
out.start_time = char(beaconData.initial_time_stamp_mat + seconds(beaconData.time(inpeak)));

end


