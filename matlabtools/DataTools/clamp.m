function out = clamp(x,bl,bu)
%% CLAMP
% function out = clamp(x,bl,bu)
%
% *DESCRIPTION*
%function made to mimic the "Clamp" function in C#. Will bind the value x
%to fit between bl (lower) and bu (upper) value. And return the bound
%value.
%
% *INPUT*
%x = the original value
%bl = the lowest value allowed
%bu = the highest value allowed
%
% *OUTPUT*
%The clamped value
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode, 16-04-2021

out=min(max(x,bl),bu);
end