function corrected_data = open_artifact_correction_window(cfg, data)
%% OPEN_ARTIFACT_CORRECTION_WINDOW
% function out = open_artifact_correction_window (cfg,data)
%
% *DESCRIPTION*
% A new window is opened that lets you evaluate potential artifacts
% You can also modify and add artifacts.
%
% *INPUT*
% Configuration Options :
% cfg.artifacts         : An array of potential artifacts structs with fields starttime and endtime
%                         This array is the output of function GET_POTENTIAL_ARTIFACTS(cfg, data)
% cfg.interp_method     : string ('spline' or 'linear'), determines which interpolation method is used for correcting artifacts. default = 'linear'.
% cfg.artifactprepostvis: determines in seconds how much time should be shown around the artifact in the replacement app
% cfg.segment_identifier: string with the segment name and participant label, this is shown in the artifact correction window
%
% *OUTPUT*
% corrected data
%

%% VARIABLE CHECK
if ~isfield(cfg, 'default_solution')
    cfg.default_solution = 'linear';
end
if ~isfield(cfg, 'segment_identifier')
    cfg.segment_identifier = '';
end
if ~isfield(cfg, 'prepostduration')
    cfg.prepostduration = 20;
end
if ~isfield(cfg, 'artifacts')
    cfg.artifacts = [];
end
cfg.time = data.time;

% cfg.artifacts = artifacts;
% cfg.segment_identifier = cfg.segment_identifier;
% cfg.default_solution = cfg.default_solution;
% cfg.prepostduration = cfg.artifactprepostvis;

ArtifactApp = BeltArtifactCorrectionApp(data.conductance_raw, cfg); % <== calling the new BELT app here

waitfor(ArtifactApp,'closeapplication',1)

try
    waitfor(ArtifactApp,'closeapplication',1)
    if strcmp(ArtifactApp.conclusion, 'Accept')
        corrected_data = ArtifactApp.solution;
    elseif strcmp(ArtifactApp.conclusion, 'Cancel')
        % if cancel was pressed, do not save the solution
        % then the 'corrected_data' has no 'conductance_artifact_corrected'
        % field. Check for this in before saving.
        corrected_data = [];
    end

    delete(ArtifactApp);
catch ME
    % user has probably closed the app
end 




end % artifact_eda(cfg, data)

