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
%- You can include multiple segments into a single call
%- The segment struct must be pre-defined, as indicated in the Example CFG
%
% Configuration options are:
% cfg.segments           : structure containing the segment values shown in
% the example cfg
% cfg.segments.value           : The name of the value array (for example,
% "phasic"), this array will be used to calculate the output of this
% segment
% cfg.segments.type            : The type of calculation you wish to
% perform over the segment, options are listed at the bottom of this page.
% If no type is provided, then mean is used as default
% cfg.segments.category        : The name of the category array (for
% example, "current_poi"), this array is used to filter the value array and
% must be of the same length as the value array
% cfg.segments.categoryvalues  : The individual values used to filter the
% category array. If this is not defined, then a list is created based on
% the unique values of the category array
%
% Example CFG: The struct required all variables, pre-setup is therefore
% recommended
% segment=struct('category',"",'categoryvalues',[],'value',"",'type',"");
% segment.category = "color";
% segment.categoryvalues = ["red" "blue" "green"];
% segment.value = "phasic";
% segment.type = "mean";
% cfg.segments(1) = segment;
%
% Types:
% mean = the average value of the segmented value array (default)
% median = the median of the segmented value array
% amount = the total amount of indices in the segmented value array
% unique = the total amount of unique values in the segmented value array
% sum = the sum of the segmented value array
% max = the highest value in the segmented value array
% min = the lowest value in the segmented value array
%
% Wilco 05-07-2021

%%
% Check Values
if ~isfield(cfg, 'segments')
    error('SEGMENTS are not defined');
end

%% Check If Segments Are Viable
%This section goes over all segments, and based on their category, value,
%type etc evaluates whether the segment should be viable. It then creates a
%long struct with all the runs to perform

nonnumtypes = ["amount" "unique"];
for i=1:length(cfg.segments)
    value = cfg.segments(i).value;
    type = cfg.segments(i).type;
    
    if (type == "")
        type = "mean"
    end
    
    if isfield(data,(value))
        %if max(contains(fieldnames(data),value))
        if ~isscalar(data.(value)) && (length(data.(value)) > 1) && ~ischar(data.(value))
            if isnumeric(data.(value)) || ismember(type,nonnumtypes)
                run = [];
                run.value = value;
                run.type = type;
                if cfg.segments(i).category ~= ""
                    if isfield(data,cfg.segments(i).category)
                        run.category = cfg.segments(i).category;
                        if isempty(cfg.segments(i).categoryvalues)
                            cfg.segments(i).categoryvalues = unique(data.(cfg.segments(i).category));
                            warning('categoryvalues not provided, using unique values in category');
                        end
                        for j=1:length(cfg.segments(i).categoryvalues)
                            run.categoryvalue = cfg.segments(i).categoryvalues(j);
                            run.name = strcat(run.value,'_',run.type,'_',run.category,'_',string(run.categoryvalue));
                            if exist('runs','var')
                                runs(length(runs)+1) = run;
                            else
                                runs(1) = run;
                            end
                        end
                    else
                        warning(strcat('Category (',cfg.segments(i).category,') does not exist, SEGMENT WILL BE SKIPPED'));
                    end
                else
                    run.category = "";
                    run.categoryvalue = "";
                    run.name = strcat(run.value,'_',run.type);
                    if exist('runs','var')
                        runs(length(runs)+1) = run;
                    else
                        runs(1) = run;
                    end
                end
            else
                warning(strcat('Value (',value,') and Type (',type,') is not a valid combination, SEGMENT WILL BE SKIPPED'));
            end
        else
            warning(strcat('Value (',value,') is not a valid variable, segmenting non-array values or character arrays is not possible, SEGMENT WILL BE SKIPPED'));
        end
    else
        warning(strcat('Value (',value,') does not exist, SEGMENT WILL BE SKIPPED'));
    end
end

%% Runs
%Run all of the runs that should be viable
for i=1:length(runs)
    
    %Get the full list of data for this run
    valuedata = data.(runs(i).value);
    
    %If there is a category defined, then filter the valuedata
    if (runs(i).category ~= "")
        categorydata = data.(runs(i).category);
        inlist = find(categorydata == runs(i).categoryvalue);
        valuedata = valuedata(inlist);
    end
    
    %Run the required calculation type over the value data
    switch runs(i).type
        case "mean"
            result = mean(valuedata);
        case "median"
            result = median(valuedata);
        case "amount"
            result = length(valuedata);
        case "unique"
            result = length(unique(valuedata));
        case "sum"
            result = sum(valuedata);
        case "max"
            result = max(valuedata);
        case "min"
            result = min(valuedata);
        otherwise
            result = NaN;
    end
    
    %Store the result in a structure
    results.(runs(i).name) = result;
end

out = results;