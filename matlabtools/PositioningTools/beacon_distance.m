function out = beacon_distance(rssi, txpower, coefficients)
%% NAME OF FUNCTION
% function out = beacon_distance(rssi, txpower, coefficients)
%
% *DESCRIPTION*
%Get the estimated distance from a beacon based on the current signal strength
%
% *INPUT*
%rssi = current power of the beacon
%txpower = the original signal transmission strength
%coefficients = the coeffficients calculated based on the beacons and
%phones we use in the lab
%
% *OUTPUT*
%a single power value
%
% *NOTES*
%This function calculates the distance from a beacon based on the beacon
%RSSI, TXPOWER, and COEFFICIENTS. The formula for this function has been
%taken from: https://altbeacon.github.io/android-beacon-library/distance-calculations2.html
%
% *BY*
%Wilco Boode


A = coefficients(1);
B = coefficients(2);
C = coefficients(3);

if rssi == 0
    out = -1.0;
else
    ratio = rssi*1.0/txpower;
    double distance;
    if ratio < 1.0
        distance = power(ratio,10);
    else
        distance =  (A)*power(ratio,B) + C;
    end    
    out = distance;
end

end