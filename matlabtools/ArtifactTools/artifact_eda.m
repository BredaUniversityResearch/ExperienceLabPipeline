function out = artifact_eda(cfg, data)
%% ARTIFACT EDA
% function out = artifact_eda (cfg,data)
%
% *DESCRIPTION*
% If cfg.manual is set to 'yes', artifact detection is skipped, and only a correction is performed (see the configuration options below.
% If cfg.manual is not set to 'yes, both detection and correction is performed
%
% Artifact detection is based on computing z-values in a moving time window (subsegment) of the data
% When the z-value in a subsegment exceeds a threshold (both in negative and positive directions), data is shown.
% NB both peaks and troughs are detected.
% User can decide whether to correct the artifact or to skip to the next.
% Artifact correction is done through using Matlab's built-in function inpaint_nans
% Input data are matlab-format EDA data (e.g. the output from empatica2matlab)
%
% If z-transformed EDA data is present in input data, a new z-transform is
% performed after artifact correction, and added to the output data
%
% Additional artifact detection and replacement can be called using the
% ReplacementArtifacts function. You can specify whether you want to run an
% additional Python Package (EdaExplorer) to identify and replace
%
% *INPUT*
% Configuration Options :
% cfg.timwin            : integer, time (in seconds) of the moving time window in which to detect artifacts. Default = 20
% cfg.threshold         : integer, zscore to be used as a threshiold for artifact detection. Default = 5;
% cfg.interp_method     : string ('spline' or 'linear'), determines which interpolation method is used for correcting artifacts. default = 'linear'.
% cfg.confirm           : string ('yes' or 'no'), visualize corrected artifacts and ask for confirmation. default = 'yes';
% cfg.manual            : string ('yes' or 'no'). If yes, artifact detection is skipped, then the user can define a time interval
%                         in which artifact correction will be done.
%                         start and end times of the user-defined artifact should then be defined by cfg.manual_starttime and cfg.manual_endtime.
%                         Default = 'no';
% cfg.manual_starttime  : integer defining start of user-defined artifact(in seconds from beginning of file).
% cfg.manual_endtime    : integer defining end of user-defined artifact(in seconds from beginning of file).
%
% cfg.validationdata    : data used for checking or proving the validity or accuracy of the eda signal. Must be an array of number values of the same sample length as the EDA data file
% cfg.artifactprepostvis: determines in seconds how much time should be shown around the artifact in the replacement app
% cfg.blockreplacement  : determines whether block based artifact replacement should be conducted, can be set to "pre", "post", "both"
% cfg.replacementartifacts  : the data array containing the artifactdata used for pre - correction replacement. Post-correction replacement, and non-existing replacement data require the python package and connection to be functional
% cfg.replacementcfg    : option so set custom cfg options for blockreplacement function (must adhere to the cfg options of the artifact_replacement function)
% cfg.participant       : string with participant number to show in the artifact correction window
%
%
% *OUTPUT*
% The same as the input structure, but with the corrected conductance array
%
% *NOTES*
% Very much developed around the EMPATICA data, might not work optimal with
% other data types
%
% *BY*
% Marcel, 29-12-2018
% Wilco, 21-02-2022

% FEATURE REQUESTS
% 1. Option to check if theres NaN data at the end, if so, segment all data
% to the moment up until the NaN data begins

%% VARIABLE CHECK
if isfield (cfg, 'validationdata')
    graphCount = 3;
else
    graphCount = 2;
end

if ~isfield(cfg, 'timwin')
    cfg.timwin = 20;
end

if ~isfield(cfg, 'threshold')
    cfg.threshold = 5;
end

if ~isfield(cfg, 'confirm')
    cfg.confirm = 'yes';
end

if ~isfield(cfg, 'manual')
    cfg.manual = 'no';
end

if ~isfield(cfg, 'interp_method')
    cfg.interp_method = 'linear';
    disp('Interpolation method has not been defined. Assuming linear interpolation for artifact correction');
end

if ~isfield(cfg, 'blockreplacement')
    cfg.blockreplacement = "none";
end

if ~isfield(cfg, 'participant')
    cfg.participant = '';
end


% value to track whether artifact removal should be repeated entirely after
% being done
repeatremoval = 'y';

while (repeatremoval == 'y')
    %% PRE BLOCK REPLACEMENT
    % section for pre-correction block replacement
    if (cfg.blockreplacement == "pre" || cfg.blockreplacement == "both")
        % check if there is an existing artifact list, if not, then create a new
        % one using the python package and the provided data
        if ~isfield(cfg, 'replacementartifacts')
            pcfg = [];
            artifacts = artifactmat2matlab(pcfg,data);
            cfg.replacementartifacts = artifacts.binaryArtifacts;
            warning("Got Artifacts");
        end
        % check if there are configurations set for the replacement function, if
        % not, create an empty config
        if ~isfield(cfg, 'replacementarticfg')
            cfg.replacementcfg = [];
            warning("Made CFG");
        end
        % store original conductance in separate variable for safekeeping and
        % probible later use
        data_orig = data;

        % create structure for replacement function
        rdata.artifacts = cfg.replacementartifacts;
        rdata.original = data.conductance;
        rdata.time = data.time;

        % run replacement function, and replace conductance data
        replacementdata = artifact_replacement(cfg.replacementcfg, rdata);
        warning("Did a replace");

        data.conductance = replacementdata.corrected;
    end

    % MANUAL IDENTIFICATION, artifact is manually defined and corrected
    if strcmpi(cfg.manual, 'yes')
        artifact_detected = 1; % artifact detection flag
        if (~isfield(cfg,'manual_starttime') || ~isfield(cfg,'manual_endtime'))
            error('manual artifact correction has been selected, but cfg.manual_starttime or cfg.manual_endtime have not been defined. Check input');
        end

        if ~exist('data_orig', 'var')
            data_orig = data;
        end

        data.conductance(cfg.manual_starttime*data.fsample+2:cfg.manual_endtime*data.fsample) = NaN; % replace artifact by NaNs; not sure why the +2 needs to be there, but it doesn't work well otherwise
        if strcmpi(cfg.interp_method, 'spline') % spline interpolation
            data.conductance = inpaint_nans(data.conductance, 1);
        elseif strcmpi(cfg.interp_method, 'linear') % linear interpolation
            data.conductance = inpaint_nans(data.conductance, 4);
        else
            error('interpolation method incorrectly specified. Check input');
        end



        % plot the resulting corrected data and ask for confirmation, if user wants this
        if strcmpi(cfg.confirm, 'yes')
            figure(99);
            subplot(graphCount,1,1), plot(data.time, data.conductance, data_orig.time, data_orig.conductance) % the entire data
            title('Entire data interval');
            subplot(graphCount,1,2), plot(data.time(cfg.manual_starttime*data.fsample - 5*data.fsample:cfg.manual_endtime*data.fsample + 5*data.fsample), data.conductance(cfg.manual_starttime*data.fsample - 5*data.fsample:cfg.manual_endtime*data.fsample + 5*data.fsample), data_orig.time(cfg.manual_starttime*data.fsample - 5*data.fsample:cfg.manual_endtime*data.fsample + 5*data.fsample), data_orig.conductance(cfg.manual_starttime*data.fsample - 5*data.fsample:cfg.manual_endtime*data.fsample + 5*data.fsample)); % a 10-second windw around the corected artifact
            title('Zoom view: Red = original data, blue = corrected data if correction accepted');
            if isfield(cfg, 'validationdata')
                subplot(graphCount,1,3), plot(data.time, cfg.validationdata, 'Color', [0.1, 0.5, 0.1])
                title('Validation Data');
            end
            keep = uicontrol('Style','radiobutton','String','Correction OK. Keep it', 'position', [50 5 220 15]);
            undo = uicontrol('Style','radiobutton','String','Correction not OK. revert to original.', 'position', [200 5 320 15]);
            keep.Value = 1;
            undo.Value = 0;
            pause;
            if keep.Value ==1
                fprintf('Artifact between time %.2f and %.2f corrected. Proceeding to the next artifact\n', cfg.manual_starttime, cfg.manual_endtime);
                clf(99);
            elseif undo.Value == 1
                data = data_orig; % revert to the uncorrected data if correction is not accepted
                disp('Artifact correction has been undone.');
                clf(99);
            else
                disp('wrong input! Select one of the two options (radiobuttons) in the Figure.');
                data = data_orig; % revert to the uncorrected data if correction is not accepted
                disp('Artifact correction has been undone.');
                clf(99);
            end
        end


    % ARTIFACT DETECTION, semi-automatic artifact detection and correction
    else 
        artifact_detected = 0; % initialize artifact detection flag, no artifact found yet
        data_orig = data; % keep track of original data for final plot
        timwin_samplesize = cfg.timwin * data.fsample; % the length of the window in amount of samples (e.g. 20s * 4Hz = 80 samples)
        sample_i = 1; % start the timewindow at the first data sample
        
        while sample_i < numel(data.conductance) - timwin_samplesize

            timwin_data = data.conductance(sample_i : sample_i + timwin_samplesize - 1); % get the data of the current window
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
                    if zvalues(leftindex - 1) < zvalues(leftindex) % the left value was smaller than the current value
                        leftindex = leftindex - 1; % so move (further) to the left
                    else % until the left value is not smaller than the current value
                        break
                    end
                end

                % find right-hand border of this artifact by finding the
                % datasample to the right of the peak where the decline stops, within the 20-second time window
                rightindex = peakindex; % start at the peak
                while rightindex < timwin_samplesize % stay within the current window
                    if zvalues(rightindex + 1) < zvalues(rightindex) % the right value is smaller than the current value
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
                        artifacts(length(artifacts) + 1) = artifact;
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
                    if zvalues(leftindex - 1) > zvalues(leftindex) % the left value was larger than the current value
                        leftindex = leftindex - 1; % so move (further) to the left
                    else % until the left value is not larger than the current value
                        break
                    end
                end

                % find right-hand border of this artifact by finding the
                % datasample to the right of the peak where the incline stops, within the 20-second time window
                rightindex = troughindex; % start at the peak
                while rightindex < timwin_samplesize % stay within the current window
                    if zvalues(rightindex +1 ) > zvalues(rightindex) % the right value is larger than the current value
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
    end

    %% ARTIFACT CORRECTION
    % Open the correction app, and allow user to select artifacts to correct
    if exist('artifacts','var')
        appcfg = [];
        if isfield(cfg, 'prepostvisualization')
            appcfg.prepostduration = cfg.prepostvisualization;
        end

        artifactcfg = [];
        artifactcfg.artifacts = artifacts;
        artifactcfg.time = data.time;
        artifactcfg.participant = cfg.participant;
        
        if isfield(cfg, 'validationdata')
            artifactcfg.validation = cfg.validationdata;
        end
        if isfield(cfg, 'artifactprepostvis')
            artifactcfg.prepostduration = cfg.artifactprepostvis;
        end
        ArtifactApp = ArtifactCorrectionApp(data.conductance,artifactcfg);

        waitfor(ArtifactApp,'closeapplication',1)

        data.conductance = ArtifactApp.solution;
        delete(ArtifactApp);
    end

    %% POST BLOCKREPLACEMENT
    % section for pre-correction block replacement
    if (cfg.blockreplacement == "post" || cfg.blockreplacement == "both")
        % create new artifact list using the python function using the corrected
        % data
        pcfg = [];
        artifacts = artifactmat2matlab(pcfg,data);
        cfg.replacementartifacts = artifacts.binaryArtifacts;

        % check if there are configurations set for the replacement function, if
        % not, create an empty config
        if ~isfield(cfg, 'replacementarticfg')
            cfg.replacementcfg = [];
        end

        % store original conductance in separate variable for safekeeping and
        % probible later use
        originalconductance = data.conductance;

        % create structure for replacement function
        rdata.artifacts = cfg.replacementartifacts;
        rdata.original = data.conductance;
        rdata.time = data.time;

        % run replacement function, and replace conductance data
        replacementdata = artifact_replacement(cfg.replacementcfg, rdata);
        data.conductance = replacementdata.corrected;
    end

    %% HOUSEKEEPING AND RE-CALCULATE OPTION
    out = data; % copy corrected data to output struct
    out.conductance_z = normalize(out.conductance); % replace old z-transformed data to new (after correction) z-transformed data
    close;%(99);

    if strcmp(cfg.manual,'no')
        if artifact_detected ==1  % if an artifact was found
            if strcmp(cfg.confirm, 'yes')
                figure;
                subplot(graphCount,1,1), plot(data_orig.time, data_orig.conductance, out.time, out.conductance) % the original data
                title('Original data (blue = before artifact correction, red = after artifact correction)');
                subplot(graphCount,1,2), plot(out.time, out.conductance); % the corrected data
                title('Data after artifact correction.');
                if isfield(cfg, 'validationdata')
                    subplot(graphCount,1,3), plot(data.time, cfg.validationdata, 'Color', [0.1, 0.5, 0.1])
                    title('Validation Data');
                end
            end
        else
            warning('No artifacts detected. Consider lowering the threshold.');
            % pause; 
        end

        if false % repeating does not seem to be necessary anymore, let's bypass it for now

            % Ask if removal process should be repeated
            dlgtitle = 'Repeat removal process';
            prompt = 'Do you want to repeat the removal process?';
            opts.Default = 'No';
            answer_repeatremoval = questdlg(prompt, dlgtitle, 'Yes','No', opts.Default);

            % Handle response
            switch answer_repeatremoval
                case 'Yes'
                    repeatremoval = 'y';

                    % Ask if treshold should be changed
                    opts.Default = 'No';
                    dlgtitle = 'Change treshold';
                    prompt = strcat('Do you want change the treshold? (current treshold=', num2str(cfg.threshold) , ')');
                    changetreshold = questdlg(prompt, dlgtitle, 'Yes','No', opts.Default);

                    % Handle response
                    switch changetreshold
                        case 'Yes'
                            cfg.threshold = get_new_treshold(cfg.threshold);

                    end

                    data = out;

                    disp("Restarting Artifact Removal");

                otherwise
                    repeatremoval = 'n'; % specify to end the artefact removal procedure
                    disp("Finishing Artifact Removal");
            end
        else
            repeatremoval = 'n'; % specify to end the artefact removal procedure
            disp("Finishing Artifact Removal");
        end
    end
end
end % artifact_eda(cfg, data)

% Function to get a new treshold value
function new_treshold = get_new_treshold(current_treshold)
    % Ask for the new treshold value
    prompt = strcat('Set new threshold: (current treshold=', num2str(current_treshold), ')');
    dlgtitle = 'Treshold';
    fieldsize = [1 45];
    definput = {num2str(current_treshold)};

    while 1  % loop indefinetly until a value is entered

        newtreshold_str = inputdlg(prompt,dlgtitle,fieldsize,definput);

        % Handle the response
        if isempty(newtreshold_str) % user has pressed 'Cancel', so return
            disp("Threshold Unchanged");
            new_treshold = current_treshold;
            return;
        else
            % treshold has changed
            newtreshold_double = str2double(newtreshold_str); % convert input to a number if possibe
            % check whether the new value is a positive numer
            if isnan(newtreshold_double) % this is a NaN if the entered value was not a number
                prompt = strcat(' Error: ''', newtreshold_str , ''' is not a valid treshold value. Treshold should be a positive number. Set new threshold: (current treshold=', num2str(current_treshold), ')');
            elseif newtreshold_double <= 0 % the entered value is negative or zero
                prompt = strcat(' Error: ''', newtreshold_str , ''' is not a valid treshold value. Treshold should be a positive number. Set new threshold: (current treshold=', num2str(current_treshold), ')');
            else % the entered value is a positive number, so return this value
                disp(strcat('Threshold changed to: ', newtreshold_str));
                new_treshold = newtreshold_double;
                return;
            end
        end
    end
end % get_new_treshold(current_treshold)