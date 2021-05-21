function out = resample_eda(cfg, data)
%function out = resample_eda(cfg, data)
% function to resample the conductance data from the Empatica Devices (up or down)
%
% configuration options are:
%
% cfg.fsample       =   desired fsample, must be provided
% cfg.beta          =   shape parameter of the Kaiser window used to design the
%                       lowpass filter, default = 0;
%
% recommended is to use the default value for cfg.beta, before changing the
% value read through its descriptions on:
% https://nl.mathworks.com/help/signal/ref/resample.html#bumhz33-beta
%
% Wilco Boode, 14-01-2020

%Check whether the desired fsample is defined, this value is mandatory
if ~isfield (cfg,'fsample')
    error('no sample frequency is defined for resample_eda');
end
%shape parameter of the Kaiser window used to design the lowpass filter
if ~isfield (cfg,'beta')
    cfg.beta = 0;
end

%uses the default Matlab resampling function to resample the data from the
%data fsample to the desired fsample rate
conductance = resample(data.conductance,data.time,cfg.fsample,1,1);
if isfield(data, 'conductance_z');conductance_z = resample(data.conductance_z,data.time,cfg.fsample,1,1);end
if isfield(data, 'phasic');phasic = resample(data.phasic,data.time,cfg.fsample,1,1);end
if isfield(data, 'phasic_z');phasic_z = resample(data.phasic_z,data.time,cfg.fsample,1,1);end
if isfield(data, 'tonic');tonic = resample(data.tonic,data.time,cfg.fsample,1,1);end
if isfield(data, 'tonic_z');tonic_z = resample(data.tonic_z,data.time,cfg.fsample,1,1);end

%calculate the total duration of the data, then generate an array of time
%points
tFinal = data.time(length(data.time));
time = rot90(flip(linspace(0,tFinal,length(conductance))));

%only output the desired data
out = data;
out.time = time;
out.conductance = conductance;
if numel(conductance_z) > 0; out.conductance_z = conductance_z; end
if isfield(data, 'phasic'); out.phasic = phasic; end
if isfield(data, 'phasic_z'); out.phasic_z = phasic_z; end
if isfield(data, 'tonic'); out.tonic = tonic; end
if isfield(data, 'tonic_z'); out.tonic_z = tonic_z; end
if isfield(data, 'eventchan'); out.eventchan = data.eventchan; end
out.fsample = cfg.fsample;
end