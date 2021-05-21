function out = shimmer2matlab(cfg)

curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

data = readtable('shimmer.csv','HeaderLines', 2);
samples = height(data);

timestamps = table2array(data(:,1:1));
initial_time_stamp = timestamps(1)/1000;
initial_time_stamp_mat = datestr(unixmillis2datenum(initial_time_stamp*1000));
acc = table2array(data(:,2:4));
conductance = table2array(data(:,9:9));
ppg = table2array(data(:,11:11));
fsample = uint8(((timestamps(samples)/1000)-(timestamps(1)/1000))/samples);

acceleration = zeros([samples 4]);

for isamp=1:samples
    acceleration(isamp,1) = acc(isamp,1);
    acceleration(isamp,2) = acc(isamp,2);
    acceleration(isamp,3) = acc(isamp,3);
    acceleration(isamp,4) = sqrt(acc(isamp,1)^2+acc(isamp,2)^2+acc(isamp,3)^2);
    directionalforce(isamp,1) = sqrt(acc(isamp,1)^2+acc(isamp,2)^2+acc(isamp,3)^2);
end

time = rot90(flip(linspace(0,(samples/20)-(1/20),samples)));

out.initial_time_stamp = initial_time_stamp;
out.initial_time_stamp_mat = initial_time_stamp_mat;
out.time = time;
out.timeoff = 0;
out.conductance = conductance;
out.ppg = ppg;
out.acceleration = acceleration;
out.directionalforce = directionalforce;
out.fsample = fsample;
out.datatype = "shimmer_eda_acc";
out.orig = cfg.datafolder;
end