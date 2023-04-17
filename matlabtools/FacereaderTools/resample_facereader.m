function out = resample_facereader (cfg, data)
%% RESAMPLE FACEREADER
%function out = resample_facereader (cfg, data)
%
% *DESCRIPTION*
%This function can resample the Facereader data, currently it can only
%downlsample, not upsample. But the final version will resample according
%to the original / new sample rate, this allows for 1 resample script,
%instead of an upsample/downsample script (since we dont always know the
%sample rate)
%This script counts up all Samples closest to the new Sample Time, and
%grabs the mean value of this combination of samples.
%The Upsample should fill up the spaces with the nearest Sample Time. This
%is already done with some of the data (beacon)
%
% *INPUT*
%Configuration Options
%cfg.fsample = the desired sample frequency
%           default = 4;
% *OUTPUT*
%resampled structure
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode

%% DEV INFO
%This function was developed as a test and needs extensive reworking to be
%functional in a production setting.
%The current resampling is done manually, creating a linear frequency and
%then using the default resample (or resample_generic) would be preferred
%in the future


%% START
%clearvars -except segmented_facereader_e segmented_facereader_e_resegmented
%data = segmented_facereader_e;
%clearvars -except out out_original
%out = out_original;
%data = out;
%cfg = [];
%cfg.fsample = 4;
%cfg.duration = 59;
%clearvars -except cfg segmented_facereader 
%data = segmented_facereader;
if (cfg.fsample <  data.fsample)
    newtime = [];
    oldneutral = [];
    
    %Due to pre-allocation of arrays, it is necessary to perform this check in
    %segment_facereader, making it redundant in the resample function.
    %for i=1: length(data.neutral)
    %                if ~strcmp(data.neutral(i), 'FIT_FAILED')
    %                    oldneutral = [oldneutral,str2double(data.neutral(i))];
    %                else
    %                    oldneutral = [oldneutral,NaN];
    %                end
    %end
    
    for i = 0: cfg.fsample * cfg.duration
        newtime = [newtime, i*(1/cfg.fsample)];
    end
    
    newneutral = zeros(length(newtime),1);
    newhappy = zeros(length(newtime),1);
    newsad= zeros(length(newtime),1);
    newangry= zeros(length(newtime),1);
    newsurprised= zeros(length(newtime),1);
    newscared= zeros(length(newtime),1);
    newdisgusted= zeros(length(newtime),1);
    newvalence= zeros(length(newtime),1);
    newarousal= zeros(length(newtime),1);
    countval1 = [];
    countval2 = [];
    count = 1;
    for i = 1: length(newtime)
        %countstr = [];   
        thistime = [];
        thisneutral = [];
        thishappy = [];
        thissad= [];
        thisangry= [];
        thissurprised= [];
        thisscared= [];
        thisdisgusted= [];
        thisvalence= [];
        thisarousal= [];
        
        if i < length(newtime)
            time1 = [newtime(i), data.time(count)];
            time2 = [data.time(count),newtime(i+1)];
            timediff1 = diff(time1);
            timediff2 = diff(time2);
            while timediff1 < timediff2
                %countstr = [countstr,count];
                %If statement is redundant after adding segment_facereader
                %if ~strcmp(data.neutral(count), 'FIT_FAILED')
                if ~isnan(data.neutral(count))
                    thisneutral = [thisneutral,data.neutral(count)];
                    thishappy = [thishappy,data.happy(count)];
                    thissad = [thissad,data.sad(count)];
                    thisangry = [thisangry,data.angry(count)];
                    thissurprised = [thissurprised,data.surprised(count)];
                    thisscared = [thisscared,data.scared(count)];
                    thisdisgusted = [thisdisgusted,data.disgusted(count)];
                    thisvalence = [thisvalence,data.valence(count)];
                    thisarousal = [thisarousal,data.arousal(count)];   
                end
                %end
                thistime = [thistime,data.time(count)];
                count = count + 1;
                time1 = [newtime(i), data.time(count)];
                time2 = [data.time(count),newtime(i+1)];
                timediff1 = diff(time1);
                timediff2 = diff(time2);
            end
        else
            time1 = [newtime(i), data.time(count)];
            timediff1 = diff(time1);
            while timediff1 <  0
                %countstr = [countstr,count];
                %if ~strcmp(data.neutral(count), 'FIT_FAILED')
                 if ~isnan(data.neutral(count))
                    thisneutral = [thisneutral,data.neutral(count)];
                    thishappy = [thishappy,data.happy(count)];
                    thissad = [thissad,data.sad(count)];
                    thisangry = [thisangry,data.angry(count)];
                    thissurprised = [thissurprised,data.surprised(count)];
                    thisscared = [thisscared,data.scared(count)];
                    thisdisgusted = [thisdisgusted,data.disgusted(count)];
                    thisvalence = [thisvalence,data.valence(count)];
                    thisarousal = [thisarousal,data.arousal(count)];
                 end
                %end
                time1 = [newtime(i), data.time(count)];
                timediff1 = diff(time1);
                count = count + 1;
            end
        end
        newneutral(i) = mean(thisneutral);
        newhappy(i) = mean(thishappy);
        newsad(i)= mean(thissad);
        newangry(i)= mean(thisangry);
        newsurprised(i)= mean(thissurprised);
        newscared(i)= mean(thisscared);
        newdisgusted(i)= mean(thisdisgusted);
        newvalence(i)= mean(thisvalence);
        newarousal(i)= mean(thisarousal);
    end
    
    out = data;
    out.fsample = cfg.fsample;
    out.time = rot90(fliplr(newtime));
    out.neutral = newneutral;
    out.happy = newhappy;
    out.sad = newsad;
    out.angry = newangry;
    out.surprised = newsurprised;
    out.scared = newscared;
    out.disgusted = newdisgusted;
    out.valence = newvalence;
    out.arousal = newarousal;
else
    disp('resample_facereader can currently only Downsample, not Upsample FaceReader Data')
end
end