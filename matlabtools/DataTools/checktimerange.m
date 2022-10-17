function out = checktimerange(file1, file2)
%this function can check whether file 1 is within range of file 2 or not,
%it provides an integer value determining the
%
%INPUT
%file1.start    = start time (unix) of file 1
%file1.end      = end time (unix) of file 1
%file2.start    = start time (unix) of file 2
%file2.end      = end time (unix) of file 2
%
%OUTPUT
% 0 = unknown
% 1 = file 1 is within file 2
% 2 = file 1 starts before, but ends within file 2
% 3 = file 1 starts within but ends after file 2
% 4 = file 1 starts before and ends after file 2
% 5 = file 1 end before file 2 starts
% 6 = file 1 starts after file 2 ends
%
%Wilco Boode, 17-10-2022

out = 0;

if file1.start > file2.start
    if file1.start < file2.end
        if file1.end < file2.end
            out = 1;
        else
            out = 3;
        end
    end
else
    if file1.start < file2.end
        if file1.end < file2.end
            out = 2;
        else
            out = 4;
        end
    end
end

if file1.end < file2.start
    out = 5;
end
if file1.start > file2.end
    out = 6;
end

end
