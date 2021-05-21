function out = datenum2unixmillis(in)
% convert Matlab datenum to unix milliseconds
% Matlab datenums are assumed to be in local time zone, unix ms are in UTC
[year, month, day, hour, minute, second] = datevec(in);

% java.util.GregorianCalendar constructor uses zero-based months and
% rounds seconds down to an integer, so handle seconds separately
time1 = java.util.GregorianCalendar(year(1), month(1)-1, ...
    day(1), hour(1), minute(1), 0);
ms1 = time1.getTimeInMillis;
if numel(in) == 1
    % shortcut for scalar input
    out = ms1 + second(1)*1000;
    return
end

% non-scalar input, check time zones and vectorize if possible
tz1 = time1.getTime.getTimezoneOffset; % in minutes
timeend = java.util.GregorianCalendar(year(end), month(end)-1, ...
    day(end), hour(end), minute(end), 0);
msend = timeend.getTimeInMillis;
tzend = timeend.getTime.getTimezoneOffset;
if tz1 == tzend && (abs(msend - ms1) < 90*86400000) && ...
        (min(in([1, end])) <= min(in)) && (max(in([1, end])) >= max(in))
    % vectorize if all input times are in the same time zone
    % max time interval of 3 months to be on the safe side with dst
    out = ms1 + second(1)*1000 + (in - in(1))*86400000;
else
    % for loop if time zone changes
    ms = zeros(size(in)); % preallocate
    ms(1) = ms1;
    ms(end) = msend;
    for i=2:numel(in)-1
        ms(i) = java.util.GregorianCalendar(year(i), month(i)-1, ...
            day(i), hour(i), minute(i), 0).getTimeInMillis;
    end
    out = ms + second*1000;
end
