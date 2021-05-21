function out = unixmillis2datenum(in)
% convert unix milliseconds to Matlab datenum
% unix ms are in UTC, Matlab datenums are output in local time zone
datenum_utc = datenum(1970, 1, 1, 0, 0, 0) + double(in)/86400000;

% adjust for time zone
time1 = java.util.GregorianCalendar();
time1.setTimeInMillis(in(1));
tz1 = time1.getTime.getTimezoneOffset; % in minutes
if numel(in) == 1
    % shortcut for scalar input
    out = datenum_utc - tz1/1440;
    return
end

% non-scalar input, check time zones and vectorize if possible
timeend = java.util.GregorianCalendar();
timeend.setTimeInMillis(in(end));
tzend = timeend.getTime.getTimezoneOffset;
if tz1 == tzend && (abs(in(end) - in(1)) < 90*86400000) && ...
        (min(in([1, end])) <= min(in)) && (max(in([1, end])) >= max(in))
    % vectorize if all input times are in the same time zone
    % max time interval of 3 months to be on the safe side with dst
    out = datenum_utc - tz1/1440;
else
    % for loop if time zone changes
    tz = zeros(size(in)); % preallocate
    tz(1) = tz1;
    tz(end) = tzend;
    for i=2:numel(in)-1
        timeend.setTimeInMillis(in(i));
        tz(i) = timeend.getTime.getTimezoneOffset;
    end
    out = datenum_utc - tz/1440;
end
