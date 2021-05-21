function out = beacon_distance(rssi, txpower, coefficients)

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