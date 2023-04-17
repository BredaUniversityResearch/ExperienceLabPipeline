function out = calculate_hrv(cfg, data)

% set defaults
if ~isfield(cfg, 'tempdir')
    cfg.tempdir = 'C:\Temp';
end

out = data;% keep track of data, is overwritten by ledalab later

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

out.phasic = analysis.phasicData;
out.tonic = analysis.tonicData;
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
if ~isfield(data, 'conductance_z')
    disp('data does not contain z-transformed conductance. Cannot compute phasic z-transformed conductance. Phasic_z and tonic_z not added to output');
else
    data.conductance = data.conductance_z; % use z-transformed conductance data 
    save(strcat(cfg.tempdir, '\matData'), 'data'); % write temporary file that Ledalab needs to read the data
    Ledalab(strcat(cfg.tempdir, '\'), 'open', 'mat', 'analyze', 'CDA', 'optimize', 6, 'export_scrlist', [0.05 1]);
    load(strcat(cfg.tempdir, '\matData')) %load analysis results into workspace
    out.phasic_z = analysis.phasicData;
    out.tonic_z = analysis.tonicData;
    eval(sprintf('delete %s\\matData.mat', cfg.tempdir));
    eval(sprintf('delete batchmode_protocol.mat'));
    eval(sprintf('delete matData_scrlist.mat'));
    clear analysis fileinfo;
end


%% create an event channel, useful for plotting
out.eventchan = zeros(1, numel(out.phasic));
for i=1:numel(out.eventchan)
    if ~isfield(out, 'event') %check if there are any events in the file
        for j=1:numel(out.event) % for all events in the file
            if (out.event(j).time == out.time(i))
                out.eventchan(i) = 1; % arbitrary value, anything nonzero defines an event
            end
        end
    end
end


