function out = hexfromcolormap(map,min,max,cur)
%% HEXFROMCOLORMAP
% function out = hexfromcolormap (map,min,max,cur)
%
% *DESCRIPTION*
%This function calculates an RGB code from a colormap, based on the
%location of a value in a determined range, and converts this rgb code to a
%HEX code.
%
% *INPUT*
% map = colormap to take the RGB code from
% min = minimum of the range
% max = maximum of the range
% cur = value you want to check versus the provided range
%
% *OUTPUT*
%A HEX code (#000000)
%
% *NOTES*
%
% *BY*
%Wilco Boode 05-06-2023

%% VARIABLE CHECK
if cur < min || cur > max
    error("current value is outside of min max range, this is not allowed!")
end

%% GET CODE FROM RANGE
%Determine the position of the cur value in the indicated reange, and use
%this to get the correct rgb value from the colormap
range = max-min;
pos = (cur-min)/range;
loc = int32(length(map)*pos);
if loc == 0
    loc = 1;
end
rgb = map(loc,:);

out = rgb2hex(rgb);
