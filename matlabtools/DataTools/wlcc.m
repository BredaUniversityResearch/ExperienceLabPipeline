function out = wlcc(cfg, data1, data2)
% function out = wlcc(cfg, data1, data2)
% computes windowed lagged cross-correlation between two EDA signals (data1 and data2
% Output is one time series of correlation values
%
% configuration options are:
%
% cfg.window       = int, length in s of the sliding time windows (default = 8)
% cfg.lag          = int, max lag in s (in both directions; default = 4)
% cfg.deltawindow  = int, increment in s when moving to next window (determines 'sampling rate'  of output (time series of correlations; default = 2) 
% cfg.deltalag     = int or float, size in s of the steps between time lag (default = 0.25)
% cfg.datatype      = string specifying which EDA data to take from file. Can be 'conductance', 'conductance_z', 'phasic', 'phasic_z', 'tonic' or 'tonic_z' (default = phasic)
%
% wndowed cross-lagged correlation, smooting and local maximum peak-picking (cfg.selectmax = localmax) implementation from: Boker SM, Xu M, Rotondo JL, King K (2002). Psychol Methods 7(3):338–55
% default settings for wlcc are based on Prochazkova, E., Sjak-Shie, E., Behrens, F., Lindh, D., & Kret, M. E. (2022). Nature human behaviour, 6(2), 269-278.
% 31-05-2022 by Marcel.

% undocumented option for selecting local maximum, doesn't work wel;l enough yet:
% cfg.selectmax =   string specifying how the maximum correlation is chosen at each cross-lag. Can be either:
%                   'max' , simply take the maximum correlation across all cross-lags (default)
%                   'localmax', (under construction) find the local maximum that is closest to a zero-lag. Local maximum is defined as a peak flanked by cfg.localmaxnsmp (default = 2) sample points on either side. 
% cfg.localmaxnsmp = int, number of 'flanker' samples used in identifying a local maximum when selecting option cfg.selectmax = 'localmax'. Default = 2
% cfg.localmaxwin  = int, size in seconds of the window used to search for a local maximum peak (cfg.selectmax = localmax). Default = 2

%% select proper data, set defaults and do some checks

% set defaults for parameters
if ~isfield(cfg, 'window')
    cfg.window = 8;
end
if ~isfield(cfg, 'lag')
    cfg.lag = 4;
end
if ~isfield(cfg, 'deltawindow')
    cfg.deltawindow = 2;
end
if ~isfield(cfg, 'deltalag')
    cfg.deltalag = 0.25;
end
if ~isfield(cfg, 'datatype')
    cfg.datatype = 'phasic';
end
if ~isfield(cfg, 'selectmax')
    cfg.selectmax = 'max';
end
if ~isfield(cfg, 'localmaxnsmp')
    cfg.localmaxnsmp = 2;
end
if ~isfield(cfg, 'localmaxwin')
    cfg.localmaxwin = 2;
end

% check if sampling frequency is identical
if data1.fsample ~= data2.fsample
    error('sampling frequency is different for %s and %s', data1, data2)
else
    fsample = data1.fsample;
end

% select the right data
if (~isfield(data1, cfg.datatype)) | (~isfield(data2, cfg.datatype))
    error('field %s is not present in the data', cfg.datatype);
end
signal1=data1.(cfg.datatype);
signal2=data2.(cfg.datatype);
    
% make data segments of equal length (based on shortest, truncate right side of longest
if numel(signal1) < numel(signal2)
    signal2=signal2(1:numel(signal1));
    time = data1.time;
elseif numel(signal2) < numel(signal1)
    signal1=signal1(1:numel(signal2));
    time = data2.time;
else  % already equal, do nothing
    time = data1.time;  % could also have been data2.time
end

%% select windows and correlate: window 1 is base window, window 2 is shifted from -lag to +lag relative to window 1
% define a left edge, base window 1 on that (add lag to left edge and lag+window length to right edge of window 1 
left_edge = 0.25; %left edge of window 1
ileft_edge=1; %iterates over shifting of window1
ilag=0; %iterates over lags of window 2
while(left_edge*fsample + 2*cfg.lag*fsample + cfg.window*fsample < numel(signal1)) % while right side of window 1 +2x lag is within bounds of data
    window1 = signal1(left_edge*fsample +cfg.lag*fsample : left_edge*fsample + cfg.lag*fsample + cfg.window*fsample);
    % move window 2 from left edge to left edge +2 times the lag (so from negative lag to positive lag)
    while(left_edge*fsample + ilag*cfg.deltalag*fsample + cfg.window*fsample < left_edge*fsample + 2*cfg.lag*fsample + cfg.window*fsample) %while window 2 hasn't reached the right side of window 1 + lag
        window2 = signal2(left_edge*fsample + ilag*cfg.deltalag*fsample: left_edge*fsample + ilag*cfg.deltalag*fsample + cfg.window*fsample);
        r = corrcoef(window1, window2);
        correlation = r(1,2);
        ilag=ilag+1;
        cor_samplepoint(ilag) = correlation;
    end

    % we now have a series of correlation coefficients (one for each lag) for the sample point left_edge. Now apply smmoothign and find maximum
    cor_samplepoint = movmean(cor_samplepoint, 5); % apply smooting to correlation to mitigate risk of spurious maxima (see Boker et al., I use movemean instead of loess here to avoid strange results (e.g. correlations > 1))
    out.time(ileft_edge) = time(left_edge*fsample + cfg.lag*fsample + cfg.window*fsample/2); %time for this window-1 position is defined as midpoint of window 1
    if strcmp(cfg.selectmax, 'max') % if selected, just take max correlation value for this samplepoint at each time lag
        out.cor(ileft_edge) = max(cor_samplepoint);
        ilag=0;
        left_edge=left_edge+cfg.deltawindow;
        ileft_edge=ileft_edge+1;
    end
    if strcmp(cfg.selectmax, 'localmax') %if selected, use the Boker et al peakfinding algoritm
        %define initial search windows
        midpoint = round(numel(cor_samplepoint)/2);
        leftleft = midpoint-cfg.localmaxwin/cfg.deltalag; %left edge of left window; cfg.deltalag is currently the time resolutuion / sampling rate
        leftright = midpoint; %right edge of left window
        rightleft = midpoint; %left edge of right window
        rightright = midpoint+cfg.localmaxwin/cfg.deltalag; %right edge of right window
        leftwindow = cor_samplepoint(leftleft:leftright);
        rightwindow = cor_samplepoint(rightleft:rightright);
        [maxleft, imaxleft] = max(leftwindow);
        [maxright, imaxright] = max(rightwindow);
        %shift windows away from zero lag until one of them has max in midpoint
        while (imaxleft ~= round(numel(leftwindow)/2)) || (imaxright ~= round(numel(rightwindow)/2)) %while the max is not in the center of one of the two windows
%             figure;subplot(3,1,1);plot(cor_samplepoint);
%             subplot(3,1,2);plot(leftwindow);
%             subplot(3,1,3);plot(rightwindow);
%             pause;
%             close all;
            leftleft   = leftleft-1;
            leftright  = leftright-1;
            rightleft  = rightleft+1;
            rightright = rightright+1;
            if leftleft <= 0
                sprintf('no local maximum found at time %i', time(left_edge*fsample + cfg.lag*fsample + cfg.window*fsample/2))
                out.cor(ileft_edge) =NaN;
                break
            end
            leftwindow = cor_samplepoint(leftleft:leftright);
            rightwindow = cor_samplepoint(rightleft:rightright);
            [maxleft, imaxleft] = max(leftwindow);
            [maxright, imaxright] = max(rightwindow);
            if imaxleft == round(numel(leftwindow)/2) % max is centered at left window
                subwin = leftwindow(imaxleft-cfg.localmaxnsamp:imaxleft+cfg.localmaxnsamp);
                [~, imaxsubwin] = max(subwin);
                if imaxsubwin == (cfg.localmaxnsamp/2 + 1) %local maximum detected, write it down and break out of while loop
                    out.cor(ileft_edge) =maxleft;
                    break
                end
            end
            if imaxright == round(numel(rightwindow)/2) % max is centered at right window
                subwin = rightwindow(imaxright-cfg.localmaxnsamp:imaxright+cfg.localmaxnsamp);
                [~, imaxsubwin] = max(subwin);
                if imaxsubwin == (cfg.localmaxnsamp + 1) %local maximum detected, write it down and break out of while loop
                    out.cor(ileft_edge) =maxright;
                    break
                end
            end
        end
        ilag=0;
        left_edge=left_edge+cfg.deltawindow;
        ileft_edge=ileft_edge+1;
    end
end
out.cor = movmax(out.cor,5);





























