function artifacts = get_potential_artifacts(cfg, data)
%% GET_POTENTIAL_ARTIFACTS
% function out = get_potential_artifacts (cfg,data)
%
% *DESCRIPTION*
%
% Artifact detection is based on computing z-values in a moving time window (subsegment) of the data
% When the z-value in a subsegment exceeds a threshold (both in negative and positive directions), data is shown.
% Both peaks and troughs are detected.
% User can decide whether to correct the artifact or to skip to the next.
%
% *INPUT*
% Configuration Options :
% cfg.timwin            : integer, time (in seconds) of the moving time window in which to detect artifacts. Default = 20
% cfg.threshold         : integer, zscore to be used as a threshiold for artifact detection. Default = 5;
% cfg.interp_method     : string ('spline' or 'linear'), determines which interpolation method is used for correcting artifacts. default = 'linear'.
% cfg.confirm           : string ('yes' or 'no'), visualize corrected artifacts and ask for confirmation. default = 'yes';
% cfg.artifactprepostvis: determines in seconds how much time should be shown around the artifact in the replacement app
% cfg.segment_identifier: string with the segment name and participant label, this is shown in the artifact correction window
%
% *OUTPUT*
% An array of potential artifacts structs with fields:
%  starttime : the start time of the potential artifact
%  endtime   : the end time of the potential artifact
%
% *NOTES*
% Very much developed around the EMPATICA data, might not work optimal with
% other data types
%
% *BY*
% Marcel, 29-12-2018
% Wilco, 21-02-2022


%% VARIABLE CHECK
if ~isfield(cfg, 'timwin')
    cfg.timwin = 20;
end
if ~isfield(cfg, 'threshold')
    cfg.threshold = 5;
end



%% ARTIFACT DETECTION, semi-automatic artifact detection and correction
artifact_detected = 0; % initialize artifact detection flag, no artifact found yet
timwin_samplesize = cfg.timwin * data.fsample; % the length of the window in amount of samples (e.g. 20s * 4Hz = 80 samples)
sample_i = 1; % start the timewindow at the first data sample

while sample_i < height(data.conductance_raw) - timwin_samplesize

    timwin_data = data.conductance_raw(sample_i : sample_i + timwin_samplesize - 1); % get the data of the current window
    zvalues = normalize(timwin_data); % calculate zscores (ignoring NaNs)
    [peak,   peakindex]   = max(zvalues); % determine the peak z-value, and its index relative to the start of the time window
    [trough, troughindex] = min(zvalues); % determine the trough z-value, and its index relative to the start of the time window
    next_sample_jump = sample_i; % if artifacts are found, we want to jump ahead

    % PEAK DETECTION
    if peak > cfg.threshold % if the peak zscore exceeds the provided threshold

        % find left-hand border of this artifact by finding the
        % datasample to the left of the peak where the incline started, within the 20-second time window
        leftindex = peakindex; % start at the peak
        while leftindex > 1 % stay within the current window
            if zvalues(leftindex - 1) <= zvalues(leftindex) % the left value was smaller than the current value
                leftindex = leftindex - 1; % so move (further) to the left
            else % until the left value is not smaller than the current value
                break
            end
        end

        % find right-hand border of this artifact by finding the
        % datasample to the right of the peak where the decline stops, within the 20-second time window
        rightindex = peakindex; % start at the peak
        while rightindex < timwin_samplesize % stay within the current window
            if zvalues(rightindex + 1) <= zvalues(rightindex) % the right value is smaller than the current value
                rightindex = rightindex + 1; % so move (further) to the right
            else % until the right value is not smaller than the current value
                break
            end
        end

        % sometimes the peak or border of the artifact is found at the left-hand side of the time window. In this case, it is a sudden
        % drop in the signal, not a motion artifact: a motion artifact also entails a sudden rise in the signal, which should have been
        % detected in earlier time windows. Move forward the time window to one sample beyond the peak and continue to the next iteration
        if (leftindex == 1)
            sample_i = sample_i + peakindex + 1;
            continue
        end

        % sometimes the peak or border of the artifact is found at the right-hand side of the time window. In this case, we have not
        % captured the full extent of the artifact yet. Move forward one sample and continue to the next iteration
        if (rightindex == timwin_samplesize)
            sample_i = sample_i + 1;
            continue
        end

        if (leftindex < rightindex)
            % translate the window indices to the data indices
            leftborder  = sample_i + leftindex  - 1;
            rightborder = sample_i + rightindex - 1;
            % make sure the border is always within the time domain / datapoint count to mitigate index issues (should not be possible)
            % leftborder  = clamp(leftborder, 1,length(data.time));
            % rightborder = clamp(rightborder,1,length(data.time));

            % create a structure to hold the artifact start and end times
            artifact = struct('starttime',data.time(leftborder),'endtime',data.time(rightborder));
            artifact_detected = 1; % artifact detection flag, artifact found

            % add the current artifact to the end of the artifact list
            if exist('artifacts','var')
                artifacts(end + 1) = artifact;
            else
                artifacts(1) = artifact;
            end
        end

        % done with the current potential artifact. Jump to the end of it and go to the next iteration
        % but first check the trough
        next_sample_jump = rightborder;
    end

    %% TROUGH DETECTION
    if trough < cfg.threshold * -1 % if the peak zscore exceeds the provided threshold in the negative direction

        % find left-hand border of this artifact by finding the
        % datasample to the left of the peak where the decline started, within the 20-second time window
        leftindex = troughindex; % start at the peak
        while leftindex > 1 % stay within the current window
            if zvalues(leftindex - 1) >= zvalues(leftindex) % the left value was larger than the current value
                leftindex = leftindex - 1; % so move (further) to the left
            else % until the left value is not larger than the current value
                break
            end
        end

        % find right-hand border of this artifact by finding the
        % datasample to the right of the peak where the incline stops, within the 20-second time window
        rightindex = troughindex; % start at the peak
        while rightindex < timwin_samplesize % stay within the current window
            if zvalues(rightindex +1 ) >= zvalues(rightindex) % the right value is larger than the current value
                rightindex = rightindex + 1; % so move (further) to the right
            else % until the right value is not larger than the current value
                break
            end
        end

        % sometimes the trough or border of the artifact is found at the left-hand side of the time window. In this case, it is a sudden
        % rise in the signal, not a motion artifact: a trough motion artifact also entails a sudden drop in the signal, which should have been
        % detected in earlier time windows. Move forward the time window to one sample beyond the trough and continue to the next iteration
        if (leftindex == 1)
            sample_i = sample_i + troughindex +  1;
            continue
        end

        % sometimes the trough or border of the artifact is found at the right-hand side of the time window. In this case, we have not
        % captured the full extent of the artifact yet. Move forward one sample and continue to the next iteration
        if (rightindex == timwin_samplesize)
            sample_i = sample_i + 1;
            continue
        end

        if (leftindex < rightindex)
            % translate the window indices to the data indices
            leftborder  = sample_i + leftindex  - 1;
            rightborder = sample_i + rightindex - 1;
            % make sure the border is always within the time domain / datapoint count to mitigate index issues (should not be possible)
            % leftborder  = clamp(leftborder, 1,length(data.time));
            % rightborder = clamp(rightborder,1,length(data.time));

            % create a structure to hold the artifact start and end times
            artifact = struct('starttime',data.time(leftborder),'endtime',data.time(rightborder));
            artifact_detected = 1; % artifact detection flag, artifact found

            % add the current artifact to the end of the artifact list
            if exist('artifacts','var')
                artifacts(length(artifacts) + 1) = artifact;
            else
                artifacts(1) = artifact;
            end
        end

        % done with the current potential artifact. Jump to the end of it and go to the next iteration
        % TODO: changing sample_i here while it is used in the trough section?
        % TODO: can we assume there is only one artifact in a given timwin?
        next_sample_jump = rightborder;

    end

    % jump ahead in time (increase sample_i)
    sample_i = next_sample_jump + 1;
end

%% RETURN POTENTIAL ARTIFACTS
if ~exist('artifacts','var')
    artifacts = [];
end


% RETURN RAW DATA WITH ARTIFACTS !!!!!!!!!!!!!!!!!!!!!!!!!!

end % artifact_eda(cfg, data)

