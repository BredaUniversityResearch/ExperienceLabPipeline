function out = artifact_eda(cfg, data)
% function out = artifact_eda(cfg, data);
% detects and corrects motion artifacts in EDA data.
%
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
% configuration options are:
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

% Marcel, 29-12-2018
% Wilco, 21-02-2022

% set defaults
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

if ~isfield(cfg, 'blockreplacement')
    cfg.blockreplacement = "none";
end

%value to track whether artifact removal should be repeated entirely after
%being done
repeatremoval = 'y';

while (repeatremoval == 'y')
    %% PRE BLOCK REPLACEMENT
    %section for pre-correction block replacement
    if (cfg.blockreplacement == "pre" || cfg.blockreplacement == "both")
        %check if there is an existing artifact list, if not, then create a new
        %one using the python package and the provided data
        if ~isfield(cfg, 'replacementartifacts')
            pcfg = [];
            artifacts = artifactmat2matlab(pcfg,data);
            cfg.replacementartifacts = artifacts.binaryArtifacts;
            warning("Got Artifacts");
        end
        %check if there are configurations set for the replacement function, if
        %not, create an empty config
        if ~isfield(cfg, 'replacementarticfg')
            cfg.replacementcfg = [];
            warning("Made CFG");
        end
        %store original conductance in separate variable for safekeeping and
        %probible later use
        data_orig = data;

        %create structure for replacement function
        rdata.artifacts = cfg.replacementartifacts;
        rdata.original = data.conductance;
        rdata.time = data.time;

        %run replacement function, and replace conductance data
        replacementdata = artifact_replacement(cfg.replacementcfg, rdata);
        warning("Did a replace");

        data.conductance = replacementdata.corrected;
    end

    %% MANUAL IDENTIFICATION
    if strcmpi(cfg.manual, 'yes') % no artifact detection necessary, artifact is manually defined and corrected
        detected = 1; %flag for keeping track of artifacts, used here for compatibility with the detection part of the function
        if (~isfield(cfg,'manual_starttime') || ~isfield(cfg,'manual_endtime'))
            error('manual artifact correction has been selected, but cfg.manual_starttime or cfg.manual_endtime have not been defined. Check input');
        end

        if ~exist('data_orig', 'var')
            data_orig = data;
        end

        data.conductance(cfg.manual_starttime*data.fsample+2:cfg.manual_endtime*data.fsample) = NaN; % replace artifact by NaNs; not sure why the +2 needs to be there, but it doesn't work well otherwise
        if strcmpi(cfg.interp_method, 'spline') %spline interpolation
            data.conductance = inpaint_nans(data.conductance, 1);
        elseif strcmpi(cfg.interp_method, 'linear') % linear interpolation
            data.conductance = inpaint_nans(data.conductance, 4);
        else
            error('interpolation method incorrectly specified. Check input');
        end



        %plot the resulting corrected data and ask for confirmation, if user wants this
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


        %% ARTIFACT DETECTION
        % semi-automatic artifact detection and correction
    else % perform artifact detection and correction
        detected = 0;
        data_orig = data; %keep track of original data for final plot
        %move over data in subsegment intervals and z-transform
        isample = (cfg.timwin*data.fsample/2)+2; % skip the first sample to avoid array indexing issues while plotting
        while isample < numel(data.conductance)-((cfg.timwin*data.fsample/2)+1)

            timewindow = data.conductance(isample-(cfg.timwin*data.fsample/2):isample+((cfg.timwin*data.fsample/2)));
            [zvalues, ~, ~] = zscore(timewindow);
            [peak, peakindex] = max(zvalues); %determine the peak z-value, and its index relative to the start of the time window (isamp -41)
            [trough, troughindex] = min(zvalues); %determine the trough z-value, and its index relative to the start of the time window (isamp - 41)
            peaksample = isample - ((cfg.timwin*data.fsample/2)+1) + peakindex;
            troughsample = isample - ((cfg.timwin*data.fsample/2)+1) + troughindex;

            %% PEAK DETECTION
            if peak > cfg.threshold %detected possible artifact in terms of peaks
                detected =1;

                %determine the extent of the possible artifact, within the 20-second time window
                %find left-hand border
                leftindex = peakindex;
                while leftindex > 1
                    if zvalues(leftindex-1) < zvalues(leftindex)
                        leftindex = leftindex-1;
                    else
                        leftborder = isample - ((cfg.timwin*data.fsample/2)+1) + leftindex; % left border is now indexed in real datasamples, not in samples of the smaller time window
                        break
                    end
                end

                %find right-hand border
                rightindex = peakindex;
                while rightindex < cfg.timwin*data.fsample+1
                    if zvalues(rightindex+1) < zvalues(rightindex)
                        rightindex = rightindex+1;
                    else
                        rightborder = isample - ((cfg.timwin*data.fsample/2)+1) + rightindex; % left border is now indexed in real datasamples, not in samples of the smaller time window
                        break
                    end
                end

                %sometimes the peak or border of the artifact is foundf at the left-hand side of the time window. In this case, it is a sudden
                %drop in the signal, not a motion artifact: a motion artifact also entails a sudden rise in the signal, which should have been
                %detected in earlier time windows. Move forward the time window to one sample beyond the peak and continue to the next iteration
                if (leftindex ==1 || peakindex ==1)
                    isample = isample+peakindex+1;
                    continue
                end

                %sometimes the peak or border of the artifact is found at the right-hand side of teh time window. In this case, we have not
                %captured the full extent of the artifact yet. Move forward one sample and continue to the next iteration
                if (rightindex == cfg.timwin*data.fsample+1 || peakindex == cfg.timwin*data.fsample+1)
                    isample = isample+1;
                    continue
                end

                artifact = struct('starttime',data.time(leftborder),'endtime',data.time(rightborder));

                if exist('artifacts','var')
                    artifacts(length(artifacts)+1) = artifact;
                else
                    artifacts(1) = artifact;
                end

                %done with the current potential artifact. Jump to the end of it and go to the next iteration
                isample = rightborder+((cfg.timwin*data.fsample/2)+1);

            else % no potential artifact detected
                isample = isample;
            end

            %% THROUGH DETECTION
            if trough < cfg.threshold*-1 %detected possible artifact
                detected =1;

                %determine the extent of the possible artifact, within the 20-second time window
                %find left-hand border
                leftindex = troughindex;
                while leftindex > 1
                    if zvalues(leftindex-1) > zvalues(leftindex)
                        leftindex = leftindex-1;
                    else
                        leftborder = isample - ((cfg.timwin*data.fsample/2)+1) + leftindex; % left border is now indexed in real datasamples, not in samples of the smaller time window
                        break
                    end
                end

                %find right-hand border
                rightindex = troughindex;
                while rightindex < cfg.timwin*data.fsample+1
                    if zvalues(rightindex+1) > zvalues(rightindex)
                        rightindex = rightindex+1;
                    else
                        rightborder = isample - ((cfg.timwin*data.fsample/2)+1) + rightindex; % left border is now indexed in real datasamples, not in samples of the smaller time window
                        break
                    end
                end

                %sometimes the trough or border of the artifact is found at the left-hand side of the time window. In this case, it is a sudden
                %rise in the signal, not a motion artifact: a trough motion artifact also entails a sudden drop in the signal, which should have been
                %detected in earlier time windows. Move forward the time window to one sample beyond the trough and continue to the next iteration
                if (leftindex ==1 || troughindex ==1)
                    isample = isample+troughindex+1;
                    continue
                end

                %sometimes the trough or border of the artifact is found at the right-hand side of teh time window. In this case, we have not
                %captured the full extent of the artifact yet. Move forward one sample and continue to the next iteration
                if (rightindex == cfg.timwin*data.fsample+1 || troughindex == cfg.timwin*data.fsample+1)
                    isample = isample+1;
                    continue
                end

                artifact = struct('starttime',data.time(leftborder),'endtime',data.time(rightborder));

                if exist('artifacts','var')
                    artifacts(length(artifacts)+1) = artifact;
                else
                    artifacts(1) = artifact;
                end

                %done with the current potential artifact. Jump to the end of it and go to the next iteration
                isample = rightborder+((cfg.timwin*data.fsample/2)+1);

            else % no potential artifact detected
                isample = isample+1;
                continue
            end

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
    %section for pre-correction block replacement
    if (cfg.blockreplacement == "post" || cfg.blockreplacement == "both")
        %create new artifact list using the python function using the corrected
        %data
        pcfg = [];
        artifacts = artifactmat2matlab(pcfg,data);
        cfg.replacementartifacts = artifacts.binaryArtifacts;

        %check if there are configurations set for the replacement function, if
        %not, create an empty config
        if ~isfield(cfg, 'replacementarticfg')
            cfg.replacementcfg = [];
        end

        %store original conductance in separate variable for safekeeping and
        %probible later use
        originalconductance = data.conductance;

        %create structure for replacement function
        rdata.artifacts = cfg.replacementartifacts;
        rdata.original = data.conductance;
        rdata.time = data.time;

        %run replacement function, and replace conductance data
        replacementdata = artifact_replacement(cfg.replacementcfg, rdata);
        data.conductance = replacementdata.corrected;
    end

    %% HOUSEKEEPING AND RE-CALCULATE OPTION
    out = data; % copy corrected data to output struct
    out.conductance_z = zscore(out.conductance); % replace old z-transformed data to new (after correction) z-transformed data
    close;%(99);

    if strcmp(cfg.manual,'no')
        if detected ==1
            figure;
            subplot(graphCount,1,1), plot(data_orig.time, data_orig.conductance, out.time, out.conductance) % the original data
            title('Original data (blue = before artifact correction, red = after artifact correction)');
            subplot(graphCount,1,2), plot(out.time, out.conductance); % the corrected data
            title('Data after artifact correction.');
            if isfield(cfg, 'validationdata')
                subplot(graphCount,1,3), plot(data.time, cfg.validationdata, 'Color', [0.1, 0.5, 0.1])
                title('Validation Data');
            end
        else
            warning('No artifacts detected. Consider lowering the threshold.');
            pause;
        end


        prompt = 'Do you want repeat the removal process? y/n [n]: ';
        repeatremoval = input(prompt,'s');
        if isempty(repeatremoval)
            repeatremoval = 'n';
        end

        if repeatremoval == 'y'
            prompt = 'Do you want change the treshold? y/n [n]: ';
            changetreshold = input(prompt,'s');
            if isempty(changetreshold)
                changetreshold = 'n';
            end

            if changetreshold == 'y'
                disp(strcat("Original Treshold: ", num2str(cfg.threshold)));
                prompt = 'Set new Threshold: ';
                newthreshold = input(prompt);

                prompt = strcat('Do you want change the treshold from: ', num2str(cfg.threshold), ' to: ',num2str(newthreshold), '? y/n [y]: ');
                acceptnewthreshold = input(prompt,'s');
                if isempty(acceptnewthreshold)
                    acceptnewthreshold = 'y';
                end

                if acceptnewthreshold == 'y'
                    cfg.threshold = newthreshold;
                    disp(strcat('Threshold changed to: ', num2str(cfg.threshold)));
                else
                    disp("Threshold Unchanged");
                end
            end

            data = out;

            disp("Restarting Artifact Removal");
        else
            disp("Finishing Artifact Removal");
        end
    end
end
