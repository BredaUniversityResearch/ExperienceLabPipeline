function out = e4full2matlab(cfg)
%function out = e4full2matlab(cfg)
%Function to read, segment and resample all data gathered in the E4
%Empatica files to matlab.
%
%Configuration Options Are
%cfg.fsample        =   Sample rate to which all data is resampled, by
%                       default this is set to 4hz, as we generally sample
%                       towards the EDA data source.
%cfg.datafolder     =   String containing the full path folder in which empatica files
%                       are stored. Note that for matlab-internal reasons you
%                       have to specify double backslashes in the path. For
%                       example 'c:\\data\\marcel\\europapark\\raw\\s01'
%cfg.trigger_time   =   Starting time of the participant / experiment, used
%                       for segmenting the whole dataset.
%cfg.pretrigger     =   Time in seconds seconds to start before the
%                       trigger_time. Used for altering the trigger_time on
%                       the entire dataset.
%cfg.posttrigger    =   Time in seconds defining the duration of the
%                       participant / experiment after the trigger_time.
%                       Used for segmenting the whole dataset.
% cfg.timezone      = string specifying the timezone the data was collected
%                     in, your local timezone will be used  if you dont
%                     specify anything. You can find all possible timezones
%                     by running the following command: timezones 
%cfg.exclude        =   Data files to exclude from this tool
%
%WARNING:
%- fsample can be changed to something other than 4hz, while tested, this
%could cause a mismatch in datapoints at the end of certain files, due to
%unintended behaviour in the matlab default resampling method. Please be
%carefull and check your datafiles when changing the fsample.
%- IBI and EVENT files can not be resampled due to their non-continuous
%nature. In the final output the length of this data will not be equal to
%the other datasets / arrays. This data will be segmented based on the
%provided triggers
%
% Wilco Boode, 11-07-2022

%Check all configuration options whether they are available, and if
%necessary, provide a warning, error, or define the configuration option as
%desired.
if ~isfield(cfg,'fsample')
    cfg.fsample = 4;
    warning('e4full resample; sample frequency not specified, using Exp Lab Default 4hz');
end
if ~isfield(cfg,'datafolder')
    error('e4full import; datafolder for participant not specified, stopping analysis');
end
if ~isfield(cfg,'trigger_time')
    error('e4full segment; start time not specified, stopping analysis');
end
if ~isfield(cfg,'pretrigger')
    cfg.pretrigger = 0;
end
if ~isfield(cfg,'posttrigger')
    warning('e4full segment; posttrigger undefined: will use entire file');
end
if ~isfield(cfg,'exclude')
    cfg.exclude = {''};
end
if ~isfield(cfg, 'timezone')
    cfg.timezone = datetime('now', 'TimeZone', 'local').TimeZone;
    warning(strcat('TimeZone not specified. Using local TimeZone: ',cfg.timezone));
end

%%
%Check whether all Empatica Data files are present, if not, provide error
%regarding that datafile
if max(contains(cfg.exclude,'ACC')) == 0
    if ~exist(cfg.datafolder+"\\"+"ACC.csv", 'file')
        error ("ACC DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'BVP')) == 0
    if ~exist(cfg.datafolder+"\\"+"BVP.csv", 'file')
        error ("BVP DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'EDA')) == 0
    if ~exist(cfg.datafolder+"\\"+"EDA.csv", 'file')
        error ("EDA DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'HR')) == 0
    if ~exist(cfg.datafolder+"\\"+"HR.csv", 'file')
        error ("HR DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'IBI')) == 0
    if ~exist(cfg.datafolder+"\\"+"IBI.csv", 'file')
        error ("IBI DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'TEMP')) == 0
    if ~exist(cfg.datafolder+"\\"+"TEMP.csv", 'file')
        error ("TEMP DATA DOES NO EXIST")
    end
end
if max(contains(cfg.exclude,'EVENTS')) == 0
    if ~exist(cfg.datafolder+"\\"+"tags.csv", 'file')
        error ("EVENTS DATA DOES NO EXIST")
    end
end
%%
%Import all data from the specified datafolder
if max(contains(cfg.exclude,'ACC')) == 0
    raw_acc = e4acc2matlab(cfg);
    disp("imported ACC")
end

if max(contains(cfg.exclude,'BVP')) == 0
    raw_bvp  = e4bvp2matlab(cfg);
    disp("imported BVP")
end

if max(contains(cfg.exclude,'EDA')) == 0
    raw_eda = e4eda2matlab(cfg);
    disp("imported EDA")
end

if max(contains(cfg.exclude,'HR')) == 0
    raw_hr  = e4hr2matlab(cfg);
    disp("imported HR")
end

if max(contains(cfg.exclude,'IBI')) == 0
    raw_ibi  = e4ibi2matlab(cfg);
    disp("imported IBI")
end

if max(contains(cfg.exclude,'TEMP')) == 0
    raw_temp  = e4temp2matlab(cfg);
    disp("imported TEMP")
end

if max(contains(cfg.exclude,'EVENTS')) == 0
    raw_events = e4event2matlab(cfg);
    disp("imported EVENTS")
end

%%
%FIRST DO RESAMPLE, THEN DO SEGMENT
%CALCULATE MIN/MAX START/END TIME FROM ALL OTHER DATA, IN CASE ITS NOT
%DEFINED, BUT ALSO TO ALREADY CALCULATE WHETHER THE RANGE IS EVEN POSSIBLE

if max(contains(cfg.exclude,'ACC')) == 0
    segmented_acc = segment_generic(cfg,raw_acc);
    disp("segmented ACC")
end

if max(contains(cfg.exclude,'BVP')) == 0
    segmented_bvp  = segment_generic(cfg, raw_bvp);
    disp("segmented BVP")
end

if max(contains(cfg.exclude,'EDA')) == 0
    segmented_eda = segment_generic(cfg, raw_eda);
    disp("segmented EDA")
end

if max(contains(cfg.exclude,'HR')) == 0
    segmented_hr  = segment_generic(cfg, raw_hr);
    disp("segmented HR")
end

if max(contains(cfg.exclude,'IBI')) == 0
    segmented_ibi  = segment_ibi(cfg, raw_ibi);
    disp("segmented IBI")
end

if max(contains(cfg.exclude,'TEMP')) == 0
    segmented_temp  = segment_generic(cfg, raw_temp);
    disp("segmented TEMP")
end

if max(contains(cfg.exclude,'EVENTS')) == 0
    segmented_events  = segment_event(cfg, raw_events);
    disp("segmented EVENTS")
end

%%
%Resample all segmented data
if max(contains(cfg.exclude,'ACC')) == 0
    resampled_acc = resample_acc(cfg,segmented_acc);
    disp("resampled ACC")
end

if max(contains(cfg.exclude,'BVP')) == 0
    resampled_bvp  = resample_bvp(cfg, segmented_bvp);
    disp("resampled BVP")
end

if max(contains(cfg.exclude,'EDA')) == 0
    resampled_eda = resample_eda(cfg, segmented_eda);
    disp("resampled EDA")
end

if max(contains(cfg.exclude,'HR')) == 0
    resampled_hr  = resample_hr(cfg, segmented_hr);
    disp("resampled HR")
end

%disp("IBI CANNOT BE RESAMPLED")

if max(contains(cfg.exclude,'TEMP')) == 0
    resampled_temp  = resample_temp(cfg, segmented_temp);
    disp("resampled TEMP")
end
%disp("EVENTS CANNOT BE RESAMPLED")

%% Create final output file
%general values, derived from EDA file
out.initial_time_stamp = resampled_eda.initial_time_stamp;
out.initial_time_stamp_mat = resampled_eda.initial_time_stamp_mat;
out.fsample = resampled_eda.fsample;
out.orig = resampled_eda.orig;
out.time = resampled_eda.time;
out.timeoff = resampled_eda.timeoff;

%Signal Files
if max(contains(cfg.exclude,'EDA')) == 0
    out.conductance = resampled_eda.conductance;
    out.conductance_z = resampled_eda.conductance_z;
end
if max(contains(cfg.exclude,'TEMP')) == 0
    out.acceleration = resampled_acc.acceleration;
    out.directionalforce = resampled_acc.directionalforce;
end
if max(contains(cfg.exclude,'BVP')) == 0
    out.bvp = resampled_bvp.bvp;
end
if max(contains(cfg.exclude,'HR')) == 0
    out.heartrate = resampled_hr.heartrate;
end
if max(contains(cfg.exclude,'IBI')) == 0
    out.ibi = segmented_ibi.ibi;
end
if max(contains(cfg.exclude,'TEMP')) == 0
    out.temperature = resampled_temp.temperature;
end
if max(contains(cfg.exclude,'EVENT')) == 0
    out.event = segmented_events.event;
end

%Data Types
out.datatype = "eda_acc_bvp_hr_ibi_temp_events"

end