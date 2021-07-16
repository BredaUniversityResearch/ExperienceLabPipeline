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
%Wilco, 16/76/2021
%
%WARNING
%Function is not yet extensively tested, and misses some documentation. Please consider this while
%working with the data.

%% Checks for cfg Values
if (~isfield(cfg,'inbeacons'))
    if (isfield(cfg,'outbeacons'))
        warning('no in beacons indicated, assuming in and out beacons are the same but flipped');
        cfg.inbeacons = flip(cfg.outbeacons);
    else
        error('no in/out beacons indicated')
    end
end
if (~isfield(cfg,'outbeacons'))
    if (isfield(cfg,'inbeacons'))
        warning('no out beacon indicated, assuming in and out beacon are the same but reversed');
        cfg.outbeacons = flip(cfg.inbeacons);
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

%Index and get data from in/out beacon (OLD)
%inbeaconIndex = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacon));
%outbeaconIndex = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacon));

%indata = beaconData.beaconvalues.(inbeaconIndex);
%outdata = beaconData.beaconvalues.(outbeaconIndex);


%Index and get data from beacons
beaconMap = containers.Map();

%Get the indexes of the incoming beacons
inbeaconsIndex = [];
for i =1 : length(cfg.inbeacons)
    inbeaconsIndex = [inbeaconsIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacons(i)))];
    beaconMap(string(cfg.inbeacons(i))) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.inbeacons(i)));
end

%Get the indexes of the outgoing beacons
outbeaconsIndex = [];
for i =1 : length(cfg.inbeacons)
    outbeaconsIndex = [outbeaconsIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacons(i)))];
    beaconMap(string(cfg.outbeacons(i))) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.outbeacons(i)));
end

%allbeaconsIndex = unique(vertcat(inbeaconsIndex,outbeaconsIndex));

%get the index of the middle beacons
midbeaconIndex = [];
midbeaconIndex = [midbeaconIndex ; beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.middlebeacon))];
beaconMap(string(cfg.middlebeacon)) = beaconData.beaconnames(find(beaconData.beaconMeta.('BeaconID') == cfg.middlebeacon));

%allbeaconsIndex = unique(vertcat(allbeaconsIndex,midbeaconIndex));

%Get the signal data from all indicated beacons
for k = keys(beaconMap)
    allbeaconsData.(beaconMap(k{1})) = beaconData.beaconvalues.(beaconMap(k{1}));
end

%% InOut Detection
repeatdetection = 'y';
while (repeatdetection == 'y')
    
    if exist('fig')
        if ishandle(fig)
            close(fig)
        end
    end
    
    %% Single In/Out beacon detection Will be disabled when multi-detection works
%     innandata = indata;
%     innandata(innandata > cfg.minstrength) = NaN;
%     [peaks,peakloc] = findpeaks(-innandata,'MinPeakProminence',cfg.prominence);
%     if height(peakloc) == 0
%         warning('No Input Peaks Found, using first timepoint');
%         inpeak = beaconData.time(1)+1;
%         cfg.checkdata = true;
%     else
%         inpeak = peakloc(1);
%     end
%     
%     outnnandata = outdata;
%     outnnandata(outnnandata > cfg.minstrength) = NaN;
%     [peaks,peakloc] = findpeaks(-outnnandata,'MinPeakProminence',cfg.prominence);
%     if height(peakloc) == 0
%         warning('No Output Peaks Found, using last time point');
%         outpeak = beaconData.time(height(beaconData.time))+1;
%         cfg.checkdata = true;
%     else
%         outpeak = peakloc(height(peakloc));
%     end
%     
%     if (outpeak < inpeak)
%         warning('Out Time is before In Time');
%         cfg.checkdata = true;
%     end
    
    
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
    
    beaconsData = allbeaconsData;
    fields = fieldnames (beaconsData);
    allpeaks = NaN(1,length(beaconsData.(string(fields(1)))));
    allinpeaks = NaN(1,length(beaconsData.(string(fields(1)))));
    alloutpeaks = NaN(1,length(beaconsData.(string(fields(1)))));
    
    for k = keys(beaconMap)
        beaconsData.(beaconMap(k{1}))(beaconsData.(beaconMap(k{1})) > cfg.minstrength) = NaN;
        [peaks,peakloc] = findpeaks(-beaconsData.(beaconMap(k{1})),'MinPeakProminence',cfg.prominence);
        allpeaks(peakloc) = cellfun(@str2num,k);        
        if max(ismember(cfg.inbeacons,cellfun(@str2num,k))) == 1
            allinpeaks(peakloc) = cellfun(@str2num,k);            
        end        
        if max(ismember(cfg.outbeacons,cellfun(@str2num,k))) == 1
            alloutpeaks(peakloc) = cellfun(@str2num,k);            
        end       
    end
    
    %allpeaksnonan = allpeaks;
    %allpeaksnonan(isnan(allpeaksnonan)) = [];
    
    %GetInPeaks
    inpeaks = [];
    for i = 1:length(allinpeaks)
        if allinpeaks(i) == cfg.inbeacons(1)
            comingpeaks = allinpeaks(i:length(allinpeaks));
            comingpeaks(isnan(comingpeaks)) = [];
            if length(comingpeaks) - length(cfg.inbeacons) >= 0
                if comingpeaks(1:length(cfg.inbeacons)) == cfg.inbeacons
                    inpeaks = [inpeaks;i];
                end
            end
        end
    end
    
    %GetOutPeaks
    outpeaks = [];
    for i = 1:length(alloutpeaks)
        if alloutpeaks(i) == cfg.outbeacons(length(cfg.outbeacons))
            pastpeaks = alloutpeaks(1:i);
            pastpeaks(isnan(pastpeaks)) = [];
            if length(pastpeaks) - length(cfg.outbeacons) >= 0
                if pastpeaks(length(pastpeaks)-(length(cfg.outbeacons)-1):length(pastpeaks)) == cfg.outbeacons
                    outpeaks = [outpeaks;i];
                end
            end
        end
    end
    
    %Filter In Peaks
    finalinpeaks = [];
    for i = 1:length(inpeaks)
        remove = false;
        
        if (max(outpeaks)<inpeaks(i))
            remove = true;
        end
        
        comingpeaks = allpeaks(i:length(allpeaks));
        if ~any(comingpeaks(:) == cfg.middlebeacon)
            remove = true;
        end
        
        if remove == false
            %inpeaks(i) = [];
            finalinpeaks = [finalinpeaks;inpeaks(i)];
        end
    end
    inpeaks = finalinpeaks;
    
    %Filter Out Peaks
    finaloutpeaks = [];
    for i = 1:length(outpeaks)
        remove = false;
        
        if (min(inpeaks)>outpeaks(i))
            remove = true;
        end
        
        pastpeaks = allpeaks(1:outpeaks(i));
        if ~any(pastpeaks(:) == cfg.middlebeacon)
            remove = true;
        end
        
        if remove == false
            finaloutpeaks = [finaloutpeaks;outpeaks(i)];
        end
    end
    outpeaks = finaloutpeaks;
    
    %% In Out Visualization
    if (cfg.checkdata == true)
        
        fig = figure;
        
        hold on
        
        dataMin = min(cell2mat(struct2cell(beaconsData)));
        dataMax = max(cell2mat(struct2cell(beaconsData)));

        xmin = 0;
        xmax = length(beaconData.time);
        yrange = dataMax-dataMin;
        ymin = clamp(dataMin - (yrange/10),0,dataMin);
        ymax = dataMax + (yrange/10);
        
        xlim([xmin xmax]);
        ylim([ymin ymax]);
        
        rectangle('Position',[xmin ymin xmax-xmin cfg.minstrength-ymin], 'FaceColor', '#d4ffe0');        
        
        %Visualize beacons in figure
        names = fieldnames(beaconsData);
        for i = 1:length(names)
            plot(beaconData.time,beaconsData.(names{i}));
        end
        for i = 1:length(allpeaks)
            if allpeaks(i) == cfg.middlebeacon
                xline(i,'--g');
            end
        end
        
        %Visualize In / Out Text
        t=[];
        for i = 1:length(inpeaks)
            t(length(t)+1) = text(inpeaks(i), dataMax, "In", 'Color', 'blue');
            xline(inpeaks(i),'--b');
        end
        for i = 1:length(outpeaks)
            t(length(t)+1) = text(outpeaks(i), dataMax, "Out ", 'Color', 'red');
            xline(outpeaks(i),'--r');
        end
        
        
        %t(2) = text(outpeak+1, max(indata), 'Out', 'Color', 'red');
        
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
                disp("Invalid Input");
                
                repeatset = 0;
            end
        end
    else
        repeatdetection = 'n';
    end
end

%% Check and Ask Multiple In / Out
%Get rid of old text on figure
for i = 1:length(t)
    delete(t(i))
end
t = [];

%Check In Peaks
if length(inpeaks) > 1
    for i = 1:length(inpeaks)
        t(length(t)+1) = text(inpeaks(i), dataMax, strcat("In ",string(i)), 'Color', 'blue');
    end
    
    repeatset = 0;
    while repeatset == 0
        
        prompt = 'Click on the plot to select the IN that you want to use?';
        warning(prompt);
        [x,y] = ginput(1);
        [~,pickedpeak] = (min(abs(inpeaks - x)));
        
        li = xline(inpeaks(pickedpeak),'--b', 'LineWidth', 2);
        
        prompt = 'Is this the correct IN peak? y/n [n]: ';
        peakcorrect = strtrim(input(prompt,'s'));
        if isempty(peakcorrect)
            peakcorrect = 'n';
        end
        
        if peakcorrect == 'y'
            disp('Using Indicated Peak');
            repeatset = 1;
            inpeak = inpeaks(pickedpeak);
        elseif peakcorrect == 'n'
            disp("Let's try this again");
            delete(li)
            repeatset = 0;
        else
            disp("Let's try this again");
            delete(li)
            repeatset = 0;
        end
    end
elseif isempty(inpeaks)
    error('No in peak found, stopping this run to mitigate future issues.');
else
    inpeak = inpeaks(1);
end

for i = 1:length(t)
    delete(t(i))
end
t = [];

%Check Out Peaks
if length(outpeaks) > 1
    for i = 1:length(outpeaks)
        t(length(t)+1) = text(outpeaks(i), dataMax, strcat("Out ",string(i)), 'Color', 'red');
    end
    
    repeatset = 0;
    while repeatset == 0
        
        prompt = 'Click on the plot to select the OUT that you want to use?';
        warning(prompt);
        [x,y] = ginput(1);
        [~,pickedpeak] = (min(abs(outpeaks - x)));
        
        lo = xline(outpeaks(pickedpeak),'--r', 'LineWidth', 2);
        
        prompt = 'Is this the correct OUT peak? y/n [n]: ';
        peakcorrect = strtrim(input(prompt,'s'));
        if isempty(peakcorrect)
            peakcorrect = 'n';
        end
        
        if peakcorrect == 'y'
            disp('Using Indicated Peak');
            repeatset = 1;
            outpeak = outpeaks(pickedpeak);
        elseif peakcorrect == 'n'
            disp("Let's try this again");
            delete(lo)
            repeatset = 0;
        else
            disp("Let's try this again");
            delete(lo)
            repeatset = 0;
        end
    end
elseif isempty(inpeaks)
    error('No in peak found, stopping this run to mitigate future issues.');
else
    outpeak = outpeaks(1);
end


%Close the final figure and return the values
if ishandle(fig)
    close(fig)
end

%% Set Out Values based on Inpeak and Outpeak
out.duration = beaconData.time(outpeak)-beaconData.time(inpeak);
out.start_time = char(beaconData.initial_time_stamp_mat + seconds(beaconData.time(inpeak)));

end


