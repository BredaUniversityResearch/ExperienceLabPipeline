function out = beacon2matlab(cfg, data)

%need to read a position file, in this case a CSV
%need to make 1 struct with 2 variables
%position_data / time & beacon
out = data;

if ~isfield(cfg, 'beacondata')
    cfg.beacondata = 'beaconData.csv';
end

curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder)); %change to datafolder

[~,~,pdata] = xlsread('beaconData.csv');

nsamp = size(pdata,1);
count = 1;

for isamp=2:nsamp 
   t = pdata{isamp,1};

   if (isnan(t))
   else
       count = count +1;    
       C = strsplit(string(pdata{isamp,1}),',');
       if (exist('time'))
           time = [time;string(C{1,1})];
           id = [id;string(C{1,2})];
           distance = [distance;string(C{1,3})];
           major = [major;string(C{1,4})];           
           minor = [minor;string(C{1,5})];
           rssi = [rssi;string(C{1,6})];
           name = [name;string(C{1,7})];
       else
           time = string(C{1,1});
           id = string(C{1,2});
           distance = string(C{1,3});
           major = string(C{1,4});
           minor = string(C{1,5});
           rssi = string(C{1,6});
           name = string(C{1,7});
       end
   end
end

out.position.time = rot90(time);
out.position.id = rot90(id);
out.position.distance = rot90(distance);
out.position.major = rot90(major);
out.position.minor = rot90(minor);
out.position.rssi = rot90(rssi);
out.position.name= rot90(name);

end