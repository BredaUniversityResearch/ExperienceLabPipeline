function out = resample_temp(cfg, data)
%function out = resample_temp(cfg, data)
% function to resample the temperature data from the Empatica Devices (up or down)
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
    error('no sample frequency is defined for resample_temp');
end
%shape parameter of the Kaiser window used to design the lowpass filter
if ~isfield (cfg,'beta')
    cfg.beta = 0;
end

%uses the default Matlab resampling function to resample the data from the
%data fsample to the desired fsample rate
temperature = resample(data.temperature,data.time,cfg.fsample,1,1,cfg.beta);

%calculate the total duration of the data, then generate an array of time
%points
tFinal = data.time(length(data.time));
time = rot90(flip(linspace(0,tFinal,length(temperature))));

%only output the desired data
out = data;
out.time = time;
out.temperature = temperature;
out.fsample = cfg.fsample;
end