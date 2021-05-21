function out = combine_structs(cfg, datastruct1, datastruct2)
% function out = combine_structs(cfg, datastruct1, datastruct2)
% combines two different datatypes - currently eda and beacon position data
% into one output struct
%
% All signals are resampled to the data type with the highest sampling frequency 
%
% note that both datasets need to have an IDENTICAL initial time stamp!
% use segment_eda or segment_position for that.
% Wilco (and a bit of Marcel) - 21-05-2018

%The combine_structs function is meant to be an ongoing workingscript in
%which new functions for upscaling data can be added as new datatypes are
%added to our pipeline.
%The script starts with retrieving all variable names, then copying the
%data over to a separate data struct.
%After this it will calculate the correct new sample rates
%After calculating the new rates, it will upscale the required datastructs,
%and combine all outcomes together into one struct.

%the function requires 3 structs as input
%datastruct1 = the first struct
%datastruct2 = the second struct
%cfg doesnt need any additional variables, but we need at least an empty
%cfg. You can add 3 other fields. varnames, datastruct1varnames, and datastruct2varnames 


%checks if there is an array of general / per datastruct varnames, if not
%then it will generate a list. This list should be extended as more
%datasources are added. Current Sources:
%beaconposition,phasic,eda


% initial check on whether initial tme stamps and length of data segments
% are equal. If not, throw an error

if ~strcmpi(datastruct1.initial_time_stamp_mat, datastruct1.initial_time_stamp_mat)
    error('initial time stamps of input data do not match. use segment_xxx to solve this');
end


% Wilco, better to first do a check on which datatype it is (using struct
% element 'datatype') and on that basis determine what needs to be included
% in varnames

if ~isfield(cfg, 'varnames')
        cfg.varnames = ["id","distance","major","minor","rssi","name","conductance","conductance_z","phasic","phasic_z","tonic","tonic_z","eventchan"];
end
if ~isfield(cfg, 'datastruct1varnames')
        cfg.datastruct1varnames = cfg.varnames;
end
if ~isfield(cfg, 'datastruct2varnames')
        cfg.datastruct2varnames = cfg.varnames;
end


%separate data in correct structs, make varnames arrays, and create
%structnames for later automated for loops
data.struct1 = datastruct1;
data.struct2 = datastruct2;
data.varnames = cfg.varnames;
data.struct1.varnames = cfg.datastruct1varnames;
data.struct2.varnames = cfg.datastruct2varnames;
data.structnames =  ["struct1","struct2"];

%We start with checking what is the highest sample rate of the two structs
highNum = data.struct1.fsample;
if data.struct2.fsample > highNum
    lowNum = highNum;
    highNum = data.struct2.fsample;
else
    lowNum = data.struct2.fsample;
end    

%Then we check what the new sample rate has to be (if the highest
%samplerate can be divided by the lowest then the highest is the new sample
%rate, otherwise the new samplerate is the highest samplertae * the
%lowest)
newSample = highNum;
if mod(highNum/lowNum,1)
    newSample = highNum*lowNum;
    disp("Decimal")
else
    disp("Round")
end

%Create a new list of timestamps, based on the new samplerate
maxTime = data.struct1.time(end);
newTime = 0;
for isamp=1:(maxTime*newSample) 
    newTime = [newTime;newTime(end)+(1/newSample)];
end

%Copy the initial time stamp, mat time stamp, samplerate and timestamps to 
%the out datastructure
out.initial_time_stamp = data.struct1.initial_time_stamp;
out.initial_time_stamp_mat = data.struct1.initial_time_stamp_mat;
out.fsample = newSample;
out.time = rot90(newTime);

%For both data structs (For Loop 1), 
%If the fsample rate is not the same as the new sample rate, then move to check for upsample, otherwise dont (optimization reasons) 
%If the field dataType exists, check whether the datatype corresponds to a
%yet presented one, and upsample the data (currently only for Beacon Data).
%It also copies and pastes the varnames over to the new datastruct since
%the varnames are removed in the upsample function
%check all Variables (For Loop2) if the variable is in the datastruct, 
%then copy it over to the out data
for i = 1:length(data.structnames)
    if isfield(data.(data.structnames{i}),'datatype')     
        if data.(data.structnames{i}).fsample ~= newSample
            if data.(data.structnames{i}).datatype == "beaconposition"
                vars = data.(data.structnames{i}).varnames;
                data.(data.structnames{i}) = upsample_beacon(data.(data.structnames{i}),newSample);
                data.(data.structnames{i}).varnames = vars;
            end
        end
    end
    for j = 1:length(data.(data.structnames{i}).varnames) 
        if isfield(data.(data.structnames{i}),data.(data.structnames{i}).varnames{j})            
           out.(data.varnames{j}) = data.(data.structnames{i}).(data.(data.structnames{i}).varnames{j});
        end
    end
end

end
