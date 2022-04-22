function out = beacon_distance(rssi, txpower, coefficients)
%This function calculates the distance from a beacon based on the beacon
%RSSI, TXPOWER, and COEFFICIENTS. The formula for this function has been
%taken from: https://altbeacon.github.io/android-beacon-library/distance-calculations2.html

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