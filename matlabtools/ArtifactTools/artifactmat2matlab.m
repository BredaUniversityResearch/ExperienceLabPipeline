function out = artifactmat2matlab(cfg, data)
% This function outputs the provided empatica data (can be matlab-altered)
% and calls the artifact2matlab function to run the MIT artifact detection
% in python (see artifact2matlab for more info).
%
% configuration options are:
%
% cfg.datafolder    = string containing the full path folder in which the data file
%                     is stored, and pulled from, originally this is
%                     C:/temp as its a temporary data file
% data              = empatica e4 data, requires Conductance, temperature,
% acceleration, fsample, and initial_time_stamp
% Wilco Boode, 20-03-2020
%%
%check whether the datafolder is specified, if not throw an error
if ~isfield(cfg, 'datafolder')
    cfg.datafolder = 'C:/temp';
end

%Save current Folder Location
curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

%%
%export e4 data to csv files readable for the artifact package
%Create structure for eda data
eda = rot90(flip(data.conductance));
eda = [4.000000;eda];
eda = [data.initial_time_stamp;eda];

%create structure for temperature data
temp = data.temperature;
temp = [4.000000;temp];
temp = [data.initial_time_stamp;temp];

%create structure for Acc data
x = resample(data.acceleration(1:end,1),32,data.fsample);
y = resample(data.acceleration(1:end,2),32,data.fsample);
z = resample(data.acceleration(1:end,3),32,data.fsample);
acc = [x,y,z];
acc = [32.000000,32.000000,32.000000;acc];
acc = [data.initial_time_stamp,data.initial_time_stamp,data.initial_time_stamp;acc];

%Open the output folder
cd (cfg.datafolder)

%Write the table to the csv file in the currently open folder
writetable(array2table(eda),'EDA.csv','Delimiter',',','QuoteStrings',false, 'WriteVariableNames',false);
writetable(array2table(temp),'TEMP.csv','Delimiter',',','QuoteStrings',false, 'WriteVariableNames',false);
writetable(array2table(acc),'ACC.csv','Delimiter',',','QuoteStrings',false, 'WriteVariableNames',false);

%%

%call and store the data from the artifact2matlab function
artifactdata = artifact2matlab(cfg);

%if the artifactdata is longer/shorter than the e4 data (can happen since the
%edaextract obj has a 5-sec interfact, either remove the extra rows, or
%append NaN values at the end
if (length(artifactdata.time) > length(data.time))
    difference = length(data.time)-length(artifactdata.time);
    if difference > 0
        artifactdata.time = [artifactdata.time;NaN(difference,1)];
        artifactdata.binaryArtifacts = [artifactdata.binaryArtifacts;NaN(difference,1)];
        artifactdata.multiclassArtifacts = [artifactdata.multiclassArtifacts;NaN(difference,1)];
    end
    if difference < 0
        artifactdata.time = artifactdata.time(1:length(data.time),:);
        artifactdata.binaryArtifacts = artifactdata.binaryArtifacts(1:length(data.time),:);
        artifactdata.multiclassArtifacts = artifactdata.multiclassArtifacts(1:length(data.time),:);        
    end
end

%set output to the final artifactdata structure
out = artifactdata;
end