function out = clamp(x,bl,bu)
%function made to mimic the "Clamp" function in C#. Will bind the value x
%to fit between bl (lower) and bu (upper) value. And return the bound
%value.
%
% Required values are:
%
%x = the original value
%bl = the lowest value allowed
%bu = the highest value allowed
%
%Wilco Boode, 16-04-2021
  out=min(max(x,bl),bu);
end