function out = checktimerange(time1, time2)
%% CHECK TIME RANGE
% function out = checktimerange (time1, time2)
%
% *DESCRIPTION*
%this function can check whether time1 is inside time2 or not,
%it then outputs an integer value defining the outcome.
%
%Can also be used to check for non time values, but this is what it was
%originally meant for.
%
% *INPUT*
%time1.start    = start time (unix) of time1
%time1.end      = end time (unix) of time1
%time2.start    = start time (unix) of time2
%time2.end      = end time (unix) of time2
%
% *OUTPUT*
%A single integer determining the outcome of the check
% 0 = unknown
% 1 = time1 is within time2
% 2 = time1 starts before, but ends within time2
% 3 = time1 starts within but ends after time2
% 4 = time1 starts before and ends after time2
% 5 = time1 end before time2 starts
% 6 = time1 starts after time2 ends
%
% *NOTES*
%This function does not work with 
%
% *BY*
%Wilco Boode, 17-10-2022


%% DEV INFO
%add option for datetimes as start/end
%add option for duration
%make generic CompareRange???

%% THE CHECK
out = 0;

if time1.start > time2.start
    if time1.start < time2.end
        if time1.end < time2.end
            out = 1;
        else
            out = 3;
        end
    end
else
    if time1.start < time2.end
        if time1.end < time2.end
            out = 2;
        else
            out = 4;
        end
    end
end

if time1.end < time2.start
    out = 5;
end
if time1.start > time2.end
    out = 6;
end

end
