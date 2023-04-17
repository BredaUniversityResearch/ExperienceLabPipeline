function out = beacon2matlab(cfg)
%Reads the beacon data as delivered by the museum volkenkunde.
%The data is loaded form the specified datafolder & positionfile (Defaults
%to beacondData.csv if the file is not specified.
%After reading the data it goes through a number of checks
%1. Has a data entry been made
%2. Is the current timestamp the same as the previous timestamp
%3. Is the current distance smaller than the previous distance
%this assures that the time will only occur once, and only the lowest entry
%is in the list

%Adds all old (phasic_data) to the current data struct
%out = data;
%Checks if info on the positionfile exists
if ~isfield(cfg, 'positionfile')
    cfg.positionfile = '002_export_1523977966814.csv';
end

%sets the current datafolder ot the correct datafolder
curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

%Reads the csv file
[num,str,pdata] = xlsread(cfg.positionfile);

%sets info for the loop
nsamp = size(pdata,1);
count = 1;

%loops through every line in the csv, starting at the second line since the
%first line is additional info
for isamp=2:nsamp 
    %the latest line
   t = pdata{isamp,1};
    
   %checks if the current line is NAN / Missing, if so all else is skipped
   if (isnan(t))
   else
       %splits the current line in seprarate cells, store the separate
       %cells in individual variables for easy access and a clear structure
       C = strsplit(string(pdata{isamp,1}),',');
       data.time = str2num(C{1,1});
       data.id = C(1,2);
       data.distance= str2num(C{1,3});
       data.major=str2num(C{1,4});
       data.minor=str2num(C{1,5});
       data.rssi=str2num(C{1,6});
       data.name=C(1,7);
       
       %checks if a data entry has been made
       if (count ~= 1)
            tt = data.time;
            tt2 = time(count-1);   
            %checks if the two specified numbers are the same(tt = current time, tt2 =
            %previous time) 
            if (tt == tt2)
                dd = data.distance;
                dd2 = beacondistance(count-1);
                %checks if the two specified numbers are the same(dd = current distance, dd2 =
                %previous distance) 
                if (dd < dd2)
                    %replaces the last line if current distance is lower
                    %than previous distance
                    id(count-1) = data.id;
                    beacondistance(count-1) = data.distance;
                    major(count-1) = data.major;                    
                    minor(count-1) = data.minor;
                    rssi(count-1) = data.rssi;
                    name(count-1) = data.name;
                end                
            else   
                %checks whether the time between the current and previous
                %time is larger than 1, if so then it adds a new row to
                %every array with NaN (and time = tt2+the current loop
                %position)
                if (tt-tt2 > 1)                    
                   ttd = tt-tt2;
                   ttd = ttd-1;
                   for jsamp=1:ttd
                        time = [time;tt2+jsamp];
                        id = [id;NaN];
                        beacondistance = [beacondistance;NaN];
                        major = [major;NaN];           
                        minor = [minor;NaN];
                        rssi = [rssi;NaN];
                        name = [name;NaN];
                        
                        count = count +1;
                   end   
                end
                %adds a line to the end of the array / matrix, then adds
                %one to the count
                time = [time;data.time];
                id = [id;data.id];
                beacondistance = [beacondistance;data.distance];
                major = [major;data.major];           
                minor = [minor;data.minor];
                rssi = [rssi;data.rssi];
                name = [name;data.name];
           
                count = count +1;   
            end
       else
           %creates a new varaible for every data type, then adds one to
           %the count
           time = data.time;
           id = data.id;
           beacondistance = data.distance;
           major = data.major;
           minor = data.minor;
           rssi = data.rssi;
           name = data.name;
           
           count = count +1;
       end
   end
end

initial_time_stamp = time(1,1);
initial_time_stamp_mat = datestr(unixmillis2datenum(initial_time_stamp*1000));

nsamp = size(time,1);
count = 1;
for isamp=1:nsamp
    time(count) = time(count)-initial_time_stamp;
    count = count +1;
end
    
%rotates all matrixes/arrays to be structured the same as the phasic_data
%data, then adds it to the output file
out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.fsample = 1;
out.time = rot90(time);
out.id = rot90(id);
out.distance = rot90(beacondistance);
out.major = rot90(major);
out.minor = rot90(minor);
out.rssi = rot90(rssi);
out.name= rot90(name);
out.datatype = "beaconposition";

end