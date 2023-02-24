%% SEGMENT GENERIC
% function out = segment_generic (cfg,data)
%
%% DESCRIPTION
%This function allows you to segment LINEAR time-series data based on a time
%array, and a starttime & endtime/duration. The function can either cut
%pre-determined variables, or cut all variables with the same length as the
%time-series data, that are immediate fields (not subfields) of the provided
%structure.
%
%% INPUT
%Configuration Options
%cfg.time = (OPTIONAL) you can provide either the name of the variable
%           containing time-series data ('timearray'), or the full time-series
%           data itself [0 1 2 3 4 5 6]. Leaving this blank will use the
%           variable "time" in the "data" as the time-series.
%cfg.starttime = The time of the first datapoint to include in the
%           segmented section, can be indicated as datetime ("23-Feb-2022 11:29:23"),
%           as a value in the time-series data (250.5), or as "startfile"
%           to set the starttime to the start of the time-series data.
%cfg.endtime = The time of the last datapoint to include in the
%           segmented section, can be indicated as datetime ("23-Feb-2022 11:29:23"),
%           as a value in the time-series data (250.5), or as "endfile"
%           to set the endtime to the end of the time-series data.
%cfg.duration = (OPTIONAL) can be included instead of the endtime, in which case the
%           starttime + duration will be used to calculate the endtime. Is
%           only used in case cfg.endtime is not defined.
%cfg.variables = (OPTIONAL) an array of strings, containing the name of all
%           variables to analyze ["conductance";"phasic"]. If this is not
%           defined, then all variables with the same length as the
%           time-series data will be segmented.
%cfg.allowoutofbounds = (OPTIONAL) true , detemines whether data is allowed to
%           be segmented outside the actual time-range available, this will
%           by default use the last / first value in the array. And can be
%           customized
%cfg.outofboundsstring = overflow value used by string based out of bounds 
%           arrays    
%cfg.outofboundsnumeric = overflow value used by numeric based out of bounds 
%           arrays   
%
%Data Requirements
%data.time = an array with time-series data. does not need to be linear.
%           This can also be defined in the cfg. [0 1 2 3 4 5 6]
%data.{variables} = all variables with the same length as the time-series
%           data that must be segmented.
%data.initial_time_stamp_mat = must be there if a datetime is provided as
%           the starttime or endtime ("23-Feb-2022 11:29:23"). Will be
%           overwritten in the final output with the new starttime.
%data.initial_time_stamp = starttime in second based unix time. Will be
%           overwritten in the final output with the new starttime unix time.
%
%
%% OUTPUT
%This function outputs the same data structure as put in, with as major
%differentiator that the available arrays will be segmented based on the
%provided starttime and endtime.
%
%% NOTES
%
%% BY
% Wilco 27-06-2022
