function out = segment_facereader(cfg, data)
%% SEGMENT FACEREADER
%function out = segment_facereader(cfg, data)
%
% *DESCRIPTION*
%function to segment the facereader data
%
% *INPUT*
%Configuration Options
%cfg.pretrigger = 1;
%cfg.posttrigger = 60;
%cfg.trigger_time = '24-Oct-2017 09:12:40'
%
% *OUTPUT*
%Structure containing the segmented facereader data 
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode

%% DEV INFO
%This function was partially developed, but never fully implemented in a
%project, need some cleanup and a sensibility check.
%Probably beter to completely deprecate this function and move to
%segment_generic

%clearvars -except out
%clearvars -except data data2 data3 cfg
%data = data3;
%cfg = [];
%cfg.pretrigger = 0;
%cfg.posttrigger = 60;
%cfg.trigger_time = '24-Oct-2017 09:12:40'


if ~isfield(data, 'initial_time_stamp_mat')
    data.initial_time_stamp_mat = cfg.trigger_time;
end

triggertime = etime(datevec(cfg.trigger_time),datevec(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;

if isnumeric(cfg.posttrigger)
    posttrigger = triggertime+cfg.posttrigger;
elseif strcmpi('EOF', cfg.posttrigger)
   posttrigger = data.time(numel(data.time));
else
    error('segment_facereader: cfg.posttrigger is not correctly specified. Type help segment_facereader for options');
end
disp('Made Triggers')        


count = 1;
for  i = 1:numel(data.time)
    if (data.time(i) >= triggertime) && (data.time(i) <=  posttrigger)
        count = count+1;
    end
end        
disp('Made Count')        

newtime = zeros(length(count),1);
newneutral = zeros(length(count),1);
newhappy = zeros(length(count),1);
newsad = zeros(length(count),1);
newangry = zeros(length(count),1);
newsurprised = zeros(length(count),1);
newscared = zeros(length(count),1);
newdisgusted = zeros(length(count),1);
newvalence = zeros(length(count),1);
newarousal = zeros(length(count),1);

%neutral = cellfun(@str2num,data.neutral);
%happy = cellfun(@str2num,data.happy);
%sad = cellfun(@str2num,data.sad);
%angry = cellfun(@str2num,data.angry);
%surprised = cellfun(@str2num,data.surprised);
%scared = cellfun(@str2num,data.scared);
%disgusted = cellfun(@str2num,data.disgusted);
%valence = cellfun(@str2num,data.valence);
%arousal = cellfun(@str2num,data.arousal);

disp('Preallocated Arrays')        

for  i = 1:numel(data.time)
    if (data.time(i) >= triggertime) && (data.time(i) <=  posttrigger)
        newtime(i) = data.time(i)-triggertime;
        %if isnumeric(data.neutral(i))
         if strcmp(data.neutral(i), 'FIT_FAILED') ||strcmp(data.neutral(i), 'FIND_FAILED')
            newneutral(i) = NaN;
            newhappy(i) = NaN;
            newsad(i) = NaN;
            newangry(i) = NaN;
            newsurprised(i) = NaN;
            newscared(i) = NaN;
            newdisgusted(i) = NaN;
            newvalence(i) = NaN;
            newarousal(i) = NaN;
        else
            newneutral(i) = str2double(data.neutral(i));
            newhappy(i) = str2double(data.happy(i));
            newsad(i) = str2double(data.sad(i));
            newangry(i) = str2double(data.angry(i));
            newsurprised(i) = str2double(data.surprised(i));
            newscared(i) = str2double(data.scared(i));
            newdisgusted(i) = str2double(data.disgusted(i));
            newvalence(i) = str2double(data.valence(i));
            newarousal(i) = str2double(data.arousal(i));
        end
    end
end

disp('Assigned Data')        

out = data;
out.time = rot90(fliplr(newtime));
out.neutral = rot90(fliplr(newneutral));
out.happy = rot90(fliplr(newhappy));
out.sad = rot90(fliplr(newsad));
out.angry = rot90(fliplr(newangry));
out.surprised = rot90(fliplr(newsurprised));
out.scared = rot90(fliplr(newscared));
out.disgusted = rot90(fliplr(newdisgusted));
out.valence = rot90(fliplr(newvalence));
out.arousal = rot90(fliplr(newarousal));
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time));

end