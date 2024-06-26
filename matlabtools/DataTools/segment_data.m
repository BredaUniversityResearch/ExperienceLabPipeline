function out = segment_data(cfg,data)
%function out = segment_data(cfg,data)
%This function can take a structure, and separate / run calcualations over
%the indicated arrays based on categories, part of a separate array.
%
%Beware
%- If the category array is defined, but the individual categoryvalues are
%not, then the function will automatically generate categoryvalues from the
%unique elements in the array
%- If the category array is not defined, then no categories will be used
%- You can include multiple segments into a single call (Not fully tested yet)
%- The segment struct must be pre-defined, as indicated in the Example CFG
%
% Configuration options are:
% cfg.segments                      : structure containing the segment values shown in the example cfg
% cfg.segments.value                : The name of the value array (for example, "phasic"), this array will be used segment to calculate the output of this
% cfg.segments.type                 : The type of calculation you wish to perform over the segment, options are listed at the bottom of this page. If no type is provided, then mean is used as default
% cfg.segments.category             : The name of the category array (for example, "current_poi"), this array is used to filter the value array and must be of the same length as the value array
% cfg.segments.categoryvalues       : The individual values used to filter the category array. If this is not defined, then a list is created based on the unique values of the category array
% cfg.segments.categorycalculation  : Whether the calculation should check if values are equal, or within a range
%
% Example CFG: The struct required all variables, pre-setup is therefore recommended
% segment=struct('category',"",'categoryvalues',[],'value',"",'type',"");
% segment.category = "color";
% segment.categorycalculation = "equals"
% segment.categoryvalues = ["red" "blue" "green"];
% segment.value = "phasic";
% segment.type = "mean";
% cfg.segments(1) = segment;
%
% Types:
% mean = the average value of the segmented value array (default)
% median = the median of the segmented value array
% length = the total amount of indices in the segmented value array
% unique = the total amount of unique values in the segmented value array
% sum = the sum of the segmented value array
% max = the highest value in the segmented value array
% min = the lowest value in the segmented value array
% peaks = the amount of peaks found in the segmented value array (min .1 prominence)
%
% CategoryType:
% equals = ["value1" "value2"  "value3"]= checking for the same string in the category
% range = ["0|300";"300|600";"600|900"] = range between two numeric values, separated with a pipe symbol
%
% Wilco -7=-2-2022
% Hans 20-12-2012 added cfg option to use unix timestamps as start and endtime

%% Check Values
% This sections checks if the necessary top level data is available
if ~isfield(cfg, 'segments')
    error('SEGMENTS are not defined');
end
if isempty(data)
    error('DATA is empty');
end

%% Validate Segments and Categories
%This section goes over all segments, and based on their category, value,
%type etc evaluates whether the segment should be viable. It then creates a
%struct with all the runs (individiual calculations) to perform.

%setup runs
runs = [];
%define values that do not require a numerical datatype
nonnumtypes = ["length" "unique"];
for i=1:length(cfg.segments)
    %Check if necessary data exists, if not, use the default options
    if ~isfield(cfg.segments(i),'categorycalculation')
        cfg.segments(i).categorycalculation = "equals";
    end
    if ~isfield(cfg.segments(i),'type')
        cfg.segments(i).type = "mean";
    end
    
    value = cfg.segments(i).value;
    type = cfg.segments(i).type;
    categorycalculation = cfg.segments(i).categorycalculation;
    
    %check if data exists
    if isfield(data,(value))
        %check if data is an actual array of values
        if ~isscalar(data.(value)) && (length(data.(value)) > 1) && ~ischar(data.(value))
            %check if data is accidentally non-numeric, but with a numeric type
            if ~isnumeric(data.(value)) && ~ismember(type,nonnumtypes)
                warning(strcat('Value (',value,') and Type (',type,') is not a valid combination, SEGMENT WILL BE SKIPPED'));
            else
                run = [];
                run.value = value;
                run.type = type;
                run.categorycalculation = categorycalculation;
                
                % check if category exists. If not then skip
                if cfg.segments(i).category ~= ""
                    if isfield(data,cfg.segments(i).category)
                        run.category = cfg.segments(i).category;
                        
                        
                        % check if the categorycalculation is  range or equal
                        switch categorycalculation
                            case "range"
                                if isempty(cfg.segments(i).categoryvalues)
                                    cfg.segments(i).categoryvalues = unique(data.(cfg.segments(i).category));
                                    warning('categoryvalues not provided, skipping segment');
                                    break;
                                end
                                
                                for j=1:length(cfg.segments(i).categoryvalues)
                                    run.categoryvalue = str2double(split(cfg.segments(i).categoryvalues(j),'|'));
                                    run.name = strcat(run.value,'_',run.type,'_',run.category,'_',string(j));
                                    runs = [runs;run];
                                end
                                
                            otherwise
                                %check if the categoryvalues are defined, if not then use all unique values of this category
                                if isempty(cfg.segments(i).categoryvalues)
                                    cfg.segments(i).categoryvalues = unique(data.(cfg.segments(i).category));
                                    warning('categoryvalues not provided, using unique values in category');
                                end
                                
                                %create a run element with the value to use, and name of the run
                                for j=1:length(cfg.segments(i).categoryvalues)
                                    run.categoryvalue = cfg.segments(i).categoryvalues(j);
                                    run.name = strcat(run.value,'_',run.type,'_',run.category,'_',string(j));
                                    runs = [runs;run];
                                end
                        end
                    else
                        warning(strcat('Category (',cfg.segments(i).category,') does not exist, SEGMENT WILL BE SKIPPED'));
                    end
                end
            end
        else
            warning(strcat('Value (',value,') is not a valid variable, segmenting non-array values or character arrays is not possible, SEGMENT WILL BE SKIPPED'));
        end
    else
        warning(strcat('Value (',value,') does not exist, SEGMENT WILL BE SKIPPED'));
    end
end

%% Run Calculations
%Run all of the runs that should be viable
for i=1:length(runs)
    
    %Get the full list of data for this run
    valuedata = data.(runs(i).value);
    
    %If there is a category defined, then filter the valuedata
    if (runs(i).category ~= "")
        categorydata = data.(runs(i).category);
        
        switch runs(i).categorycalculation
            case "range"
                inlist = find(categorydata>=runs(i).categoryvalue(1) & categorydata<=runs(i).categoryvalue(2));                
            otherwise
                inlist = find(categorydata == runs(i).categoryvalue);                
        end
        
        valuedata = valuedata(inlist);
    end
    
    if isempty(valuedata)
        warning(strcat('Run (',runs(i).name,') is empty, RUN WILL OUTPUT NAN'));
        runs(i).type = NaN;
        break;
    end
    
    %Run the required calculation type over the value data
    switch runs(i).type
        case "mean"
            runs(i).result = mean(valuedata);
        case "median"
            runs(i).result = median(valuedata);
        case "length"
            runs(i).result = length(valuedata);
        case "unique"
            runs(i).result = length(unique(valuedata));
        case "sum"
            runs(i).result = sum(valuedata);
        case "max"
            runs(i).result = max(valuedata);
        case "min"
            runs(i).result = min(valuedata);
        case "peaks"
            runs(i).result = length(findpeaks(valuedata,'MinPeakProminence',0.1));
        otherwise
            runs(i).result = NaN;
            warning(strcat('RunType (',runs(i).type,') is not a valid type, RUN WILL OUTPUT NAN'));
    end
end

out = runs;