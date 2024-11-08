function out = deconvolve_eda(cfg, data)
%% DECONVOLVE EDA
% function out = deconvolve_eda(cfg, data);
%
% *DESCRIPTION*
% reads matlab-format SCR data (e.g. output from empatica2matlab, or from segment_empatica)
% and decomposes this into tonic and phasic components by using the toolbox
% Ledalab. Current implementation is a continuous decomposition analysis,
% so for continuous, not event-related data. Output contains both phasic
% and tonic data, and their z-transformed equivalents (that is, phasic and tonic components 
% computed from the z-transformed conductance data
% More output details are stored in the analysis field
% (see Ledalab documentation at http://www.ledalab.de for details)
% error messages that say 'unable to open file' can be ignored, Ledalab
% tries to read all files in cfg.tempdir but shouldn't (and can't)
%
% *INPUT*
%Configuration Options
%cfg.tempdir   = string specifying location where temporary datafiles are stored (default = C:\temp)
%
% *OUTPUT*
%The original data structure, including new variables for:
%phasic, phasic_z, tonic, tonic_z, analysis
%
% *NOTES*
%NA
%
% *BY*
% Marcel Bastiaansen, 07-04-2018

%% DEV INFO
%tempdir is not checked, should check if its there, otherwise ledalab will
%crash when folder is not available
%Z score is currently running ledalab a second time. Should check if there
%is any difference in z-scoring pre or post, perhaps we can NOT run ledalab
%twice!

%% VARIABLE CHECK
% set defaults
if ~isfield(cfg, 'tempdir')
    cfg.tempdir = 'C:\Temp';
end
if ~isfield(cfg, 'analyze')
    cfg.analyze = 'CDA';
end
if ~isfield(cfg, 'optimize')
    cfg.optimize = 6;
end
if ~isfield(cfg, 'export_scrlist')
    cfg.export_scrlist = [0.05 1];
end
if ~isfield(cfg, 'conductance') % for backward compatibility
    cfg.conductance = 'conductance';   
end
if ~isfield(cfg, 'conductance_z') % for backward compatibility
    cfg.conductance = 'conductance_z';   
end

% create the dataset that ledalab needs
% create dummy event field if it doesn't exist
if ~isfield(data, 'event')
    data.event.time = 0;
    data.event.nid = 1;
    data.event.name = 'dummy_event';
    data.event.userdata = [];
end
if ~isfield(data, 'timeoff') % and add a dummy offset if it isn't there
    data.timeoff = 0;
end


%% Deal with NaNs in the data
%  Ledalab does not like NaNs, but our data may contain them if the
%  artifact solution 'replace with NaNs' was chosen during the artifact
%  correction step.
%  To solve this issue, NaN parts are replace by inear interpolation first.
%  After the deconvolution process, the NaNs are reinserted into the data.

out = data; % data is overwritten by ledalab later, so make a backup to restore

% make sure the data to be deconvolved is stored in data.conductance 
data.conductance = data.(cfg.conductance);
data.conductance_z = data.(cfg.conductance_z);


% store which timepoints contained NaNs
nan_booleans = isnan(data.conductance);

% check for NaN parts 
if sum(isnan(data.conductance)) > 0
    disp('Temporarily replacing NaN parts with linear interpolation for the deconvolution.');
    % create backup of the NaN-containing data
    conductance_with_NaNs = data.conductance;

    % extract NaN segments and replace these with linear interpolation
    for i=1:length(data.conductance)
        % find the next NaN
        if isnan(data.conductance(i))
            % NaN found, keep track of the index
            starttime = i;
            % move up the timeline until a non-NaN is found or the end of
            % the interval is reached
            while true
                % if this value is not a NaN, break out of the for loop
                if (~isnan(data.conductance(i)))
                    break;
                end
                % update the endtime of the NaN segment
                endtime = i;
                % If the end of the data is reached, break the for loop
                if i==length(data.conductance)
                    break;
                end
                % still a NaN, move to the next timepoint
                i=i+1; % Yes, I know, changing the index within a for loop, the horror ...
            end
            % The end of the NaN segment has been reached,
            % now replace it with linear interpolation.
            % For special cases that include the very first or last timepoint
            % linear interpolation is not possible, so use a fixed value
            if starttime==1
                data.conductance(starttime:endtime)   = data.conductance(endtime+1);
                data.conductance_z(starttime:endtime) = data.conductance_z(endtime+1);
            elseif endtime == length(data.conductance)
                data.conductance(starttime:endtime)   = data.conductance(starttime-1);
                data.conductance_z(starttime:endtime) = data.conductance_z(starttime-1);
            else
                data.conductance(  starttime-1:endtime+1) = linspace(data.conductance(  starttime-1),data.conductance(  endtime+1),(endtime-starttime+3));
                data.conductance_z(starttime-1:endtime+1) = linspace(data.conductance_z(starttime-1),data.conductance_z(endtime+1),(endtime-starttime+3));
            end
        end
    end
end



tmpdata = data; % to be used for deconvolution on z-transformed data.
save(strcat(cfg.tempdir, '\matData'), 'data'); % write temporary file that Ledalab needs to read the data

%% deconvolve data with ledalab and write phasic and tonic data to struct.
% arguments are as follows (for full config options, see documentation page 
% on http://www.ledalab.de

% 1st argument: string containing directory path, has to end with \ (backslash
% 2nd and 3rd argument: open datafile of type matlab
% 4th and 5th argument: we want to perform a continuous decomposition 
% analysis (CDA, useful for continuous, or DDA for event-related data
% analysis)
% 6th and 7th argument: optimization of tau parameters of individual 
% response function for each ppt separately
% 8th and 9th arguments: create a list of SCRs defined with 0.05uS
% threshold, and export this to matlab format
Ledalab(strcat(cfg.tempdir, '\'), 'open', 'mat', 'analyze', 'CDA', 'optimize', 6, 'export_scrlist', [0.05 1]);
load(strcat(cfg.tempdir, '\matData')) %load analysis results into workspace
%curdir = pwd;
%eval(sprintf('cd %s', cfg.tempdir));
load batchmode_protocol.mat; % automatically-generated file (by Ledalab) with analysis settings

%% add phasic SCR data to data struct. 
%eval(sprintf('cd %s', curdir));

out.phasic = analysis.phasicData';
out.phasicDriver = analysis.driver';
out.tonic = analysis.tonicData';
out.analysis = analysis; % keep analysis info and all other output details
out.analysis.fileinfo = fileinfo; % keep file generation log
out.analysis.batchmode_protocol = protocol;

%remove temporary files created by Ledalab)
eval(sprintf('delete %s\\matData.mat', cfg.tempdir));
eval(sprintf('delete batchmode_protocol.mat'));
eval(sprintf('delete matData_scrlist.mat'));
clear analysis fileinfo protocol;

%% now repeat everything but for z-transformed conductance, if present in the data
clear data;
data = tmpdata; %re-read original input struct

if ~isfield(data, cfg.conductance_z)
    disp('data does not contain z-transformed conductance. Cannot compute phasic z-transformed conductance. Phasic_z and tonic_z not added to output');
else
    data.conductance = data.conductance_z; % use z-transformed conductance data 
    save(strcat(cfg.tempdir, '\matData'), 'data'); % write temporary file that Ledalab needs to read the data
    Ledalab(strcat(cfg.tempdir, '\'), 'open', 'mat', 'analyze', 'CDA', 'optimize', 6, 'export_scrlist', [0.05 1]);
    load(strcat(cfg.tempdir, '\matData')) %load analysis results into workspace
    out.phasic_z = analysis.phasicData';
    out.phasicDriver_z = analysis.driver';
    out.tonic_z = analysis.tonicData';
    eval(sprintf('delete %s\\matData.mat', cfg.tempdir));
    eval(sprintf('delete batchmode_protocol.mat'));
    eval(sprintf('delete matData_scrlist.mat'));
    clear analysis fileinfo;
end


%% create an event channel, useful for plotting
out.eventchan = zeros(1, numel(out.phasic))';
for i=1:numel(out.eventchan)
    if ~isfield(out, 'event') %check if there are any events in the file
        for j=1:numel(out.event) % for all events in the file
            if (out.event(j).time == out.time(i))
                out.eventchan(i) = 1; % arbitrary value, anything nonzero defines an event
            end
        end
    end
end


%% Put the NaNs back in place

% first, let's make a copy of the interpolated data
% out.phasic_interpolated   = out.phasic;
% out.tonic_interpolated    = out.tonic;
% out.phasic_z_interpolated = out.phasic_z;
% out.tonic_z_interpolated  = out.tonic_z;
% out.conductance_interpolated  = out.conductance;
% out.conductance_z_interpolated  = out.conductance_z;

% set all timepoints that originally contained NaNs back to NaN
out.phasic(nan_booleans)         = NaN;
out.phasicDriver(nan_booleans)   = NaN;
out.tonic(nan_booleans)          = NaN;
out.phasic_z(nan_booleans)       = NaN;
out.phasicDriver_z(nan_booleans) = NaN;
out.tonic_z(nan_booleans)        = NaN;

