function out = extract_eda_measure(cfg, data)
% function out = extract_eda_measure(cfg, data);
% this function extracts single-value measures from matlab-format EDA data
% which can then be read into a statistics package, e.g. SPSS
% output measures are extracted based:
%   - on an interval around a to-be-detected peak (use cfg.peak = 'yes') 
%   - on a user-defined interval(use cfg.interval = 'yes');
%   - on a beacon location (use cfg.beacon = 'yes')
%
% output measures are interval latency (start, end), average amplitude, and area
% under curve (AuC).
% 
% configuration options are:
% cfg.eda_type                  = string specifying which type of data to extract: (default = conductance)
%                                 'phasic' (for phasic component of EDA data),
%                                 'tonic' (for tonic component of EDA data),
%                                 'conductance' (for non-deconvolved EDA data).
%                                 'phasic_z' (for z-transformed phasic component of EDA data),
%                                 'tonic_z' (for z-transformed tonic component of EDA data),
%                                 'conductance_z' (for z-transformed non-deconvolved EDA data).
%                                 note that phasic and tonic options are only available
%                                 after use of the function deconvolve_eda. 
% cfg.peak                      = string specifying whether the peak (maximum value) needs to be
%                                 detected in EDA data. default = 'no'.
%                                 if 'no': no peak detection is done. 
%                                 if 'yes': peak will be detected. Then additionally 
%                                 cfg.peak_startsearch, cfg.peak_endsearch, cfg.peak_window 
%                                 need to be defined
% cfg.peak_startsearch:         = integer specifying in seconds the starting time 
%                                 (from the beginning of the eda epoch) of the window in
%                                 which to search for a peak
% cfg.peak_endsearch:           = integer specifying in seconds the end time 
%                                 (from the beginning of the eda epoch) of the window in
%                                 which to search for a peak
% cfg.peak_window:              = integer specifying in seconds the time window
%                                 around the detected peak for which to extract output measures.
%                                 e.g. if 2 is specified, output measures are based on a time window 
%                                 of 1 second before to 1 second after the detected peak.
% cfg.interval                  = string specifying whether output measures have to be based on a 
%                                 user-defined interval. default = 'no'.
%                                 if set to 'yes', then cfg.interval_starttime and
%                                 cfg.interval_endtime need to be specified
% cfg.interval_starttime        = integer specifying in seconds (from beginning of eda epoch) the starting 
%                                 time of the interval on which output measures are based
% cfg.interval_endtime          = EITHER integer specifying in seconds (from beginning of eda epoch) the end 
%                                 time of the interval on which output measures are based,
%                                 OR string 'eof' for defining the interval as running to the end of the file.
% cfg.beacon                    = string specifying whether output measures should be based on beacon location data
%                                 default = 'no'. If set to yes, beacon data should be present in file and cfg.beacon_number should be specified
% cfg.beacon_number             = array of numbers specifying on which beacon(s) the output should be based. 
%                                 e.g. cfg.beacon_number = [1234 1235 1236] will base output on proximity to beacons 1234, 1235 and 1236

%                                 
%
% Marcel Bastiaansen, 09-04-2018

%% set defaults and do an argument check
if ~isfield(cfg, 'eda_type')
    cfg.eda_type = 'conductance';
end
if ~isfield(cfg, 'peak')
    cfg.peak = 'no';
end
if ~isfield(cfg, 'interval')
    cfg.interval = 'no';
end
if ~isfield(cfg, 'beacon')
    cfg.beacon = 'no';
end

if strcmpi(cfg.peak, 'no') && strcmpi(cfg.interval, 'no') && strcmpi(cfg.beacon, 'no')
    error('extract_eda_measure: neither peak nor interval nor beacon methods have been defined. Check configuration');
end
%% select data to work with
if strcmpi(cfg.eda_type, 'conductance')
    selecteddata = data.conductance;
end
if strcmpi(cfg.eda_type, 'conductance_z')
    selecteddata = data.conductance_z;
end
if strcmpi(cfg.eda_type, 'phasic')
    selecteddata = data.phasic;
end    
if strcmpi(cfg.eda_type, 'phasic_z')
    selecteddata = data.phasic_z;
end    
if strcmpi(cfg.eda_type, 'tonic')
    selecteddata = data.tonic;
end    
if strcmpi(cfg.eda_type, 'tonic_z')
    selecteddata = data.tonic_z;
end    
%% determine interval (in time and in samples) over which to compute interval measures.
if strcmpi(cfg.interval, 'yes') 
        
    intervalstarttime = cfg.interval_starttime; %simply copy interval start time
    intervalstartsamp = intervalstarttime*data.fsample;
    if intervalstartsamp == 0; intervalstartsamp = 1; end % in case intervalstarttime is defined as zero
    
    if strcmpi(cfg.interval_endtime, 'eof') % for selection until end of file
      intervalendtime = data.time(numel(data.time));
    else
      intervalendtime = cfg.interval_endtime;
    end
      intervalendsamp = intervalendtime*data.fsample;
end

%% detect peak and determine interval (in time and in samples) over which to compute peak measures.
if strcmpi(cfg.peak, 'yes') % find interval start and end times based on peak
    searchstartsamp = cfg.peak_startsearch*data.fsample; % compute start sample
    searchendsamp = cfg.peak_endsearch*data.fsample; % based on 4hz sampling frequency
    
    [maxval, maxlat] = max(selecteddata(searchstartsamp:searchendsamp)); % determine peak latency in search interval
    maxlat = maxlat + searchstartsamp -1; % express latency as nsamples from beginning of EDA epoch
    intervalstartsamp = maxlat - ((cfg.peak_window / 2) * data.fsample); % take off half the window from peak latency
    intervalendsamp = maxlat + ((cfg.peak_window / 2) * data.fsample); % add half the window from peak latency
    intervalstarttime = data.time(intervalstartsamp); 
    intervalendtime = data.time(intervalendsamp); 
end

    
% compute output measures and store in output struct - peak and interval options only
if strcmpi(cfg.peak, 'yes') || strcmpi(cfg.interval, 'yes')
    out.latency = [intervalstarttime intervalendtime];
    out.average = mean(selecteddata(intervalstartsamp:intervalendsamp));
    out.AuC = sum(selecteddata(intervalstartsamp:intervalendsamp));
    out.variance = var(selecteddata(intervalstartsamp:intervalendsamp));
    out.cfg = cfg; % store config with output for documentation 
end
    
%% determine output measures based on beacon position data
if strcmpi(cfg.beacon, 'yes') % select data based on beacon proximity
    i=1;
    eda(i) = NaN;
    beacon(i) = NaN;
    for isamp = 1:numel(data.time)
        if ismember(data.minor(isamp), cfg.beacon_number) %found sample that is in beacon list
            eda(i) = selecteddata(isamp); % i is the index for the array under construction)
            beacon(i) = data.minor(isamp);
            i=i+1;
        end
    end
    % copy data to output struct
    out.average = mean(eda);
    out.AuC = sum(eda);
    out.variance = var(eda);
    out.cfg = cfg;
    out.nsec = i/data.fsample; % number of samples in which beacon(s) was detected
    %determine for which beacon the peak was found
    [maxval, maxlat] = max(eda);
    out.peak_beacon = beacon(maxlat);
    out.peak_value = maxval;
end
            


    
    
    
    
    
