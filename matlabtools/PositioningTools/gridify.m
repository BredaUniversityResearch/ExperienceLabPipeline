function out = gridify(cfg,data)

%% CHECK CFG AND DATA FOR ALL PARTICIPANTS
%Check data format
if isa(data,'table')
    %check for lat & lon/long names
end    
if isstruct(data)
    %check for lat & lon/long names for all participants
end

%Check settings in CFG
if ~isfield(cfg,'gridsize')
    warning('gridsze is not defined in the configuration, using default (20)');
    cfg.gridsize = 20;
end

if ~isfield(cfg,'smoothmethod')
    cfg.smoothmethod = 'none';
elseif max(strcmp(cfg.smoothmethod,{'movmean';'movmedian';'gaussian';'lowess';'loess';'sgolay';'none'})) == 0
    cfg.smoothmethod = 'movmean';
end

if ~isfield(cfg,'spheroid')
    cfg.spheroid = wgs84Ellipsoid("m");
end

%Check if variables calculation exist, if not setup new based on the first participant
if isstruct(data)
    if ~isfield(cfg,'variables')
        warning('Variables and calculations have not been defined, calculating MEAN for ALL variables apart from lat/lon');

        %Add all variables apart from Lat & Lon to the list of variables to calculate
        varCount = 1;
        for isamp = 1:length(data(1).data.Properties.VariableNames)
            if max(strcmp(data(1).data.Properties.VariableNames{isamp},{'lat';'lon';'long'})) == 0
                cfg.variables(varCount) = struct('in',data(1).data.Properties.VariableNames{isamp},'out',data(1).data.Properties.VariableNames{isamp},'calculation','mean');
                varCount = varCount+1;
            end
        end
        cfg.variables(varCount) = struct('in','lat','out','count','calculation','count');

        cfg.variables = struct2table(cfg.variables);
    end

    %Check individual participants in struct on available variables
    for isamp = 1:max(size(data))
        labels = fieldnames(data(isamp).data);
        valid = contains(cfg.variables.in,labels);
        for jsamp =height(cfg.variables):-1:1
            if ~valid(jsamp)
                cfg.variables(2,:)=[];
            end
        end
    end
end

%% TO DO
%1. If a table is provided, check if there are multiple participants, if so
%separate the participants

%% RUN IF TABLE
%Check if data is provided for one or several participants
%If input is a table then assume its one participant and return the outcome
if isa(data,'table')
    data_grid = gridify_participant(cfg,data);
    out=data_grid;
    return;
end

%% RUN IF SINGLE PARTICIPANT
%If a struct of size 1 is provided then run that participant and return the
%outcome
if max(size(data))==1
    data_grid = gridify_participant(cfg,data(1).data);
    out=data_grid;
    warning("ONLY ONE PARTICIPANT IN STRUCT, RETURNING GRIDDED DATA FOR THIS PARTICIPANT");
    return;
end

%% RUN IF MULTIPLE PARTICIPANTS
%If a struct contains multiple participants, then run and return outcome
%for all

for isamp = 1:max(size(data))
    data_grid(isamp).data = gridify_participant(cfg,data(isamp).data);
end
data_c = struct2cell(data_grid);
data_t = vertcat(data_c{:});

%Add participant count variable
vNew = table({'participant'},{'participantcount'},{'unique'},'VariableNames',{'in','out','calculation'});
cfg.variables = vertcat(cfg.variables,vNew);

%Index combined data table
[data_g,~,idx] = unique(data_t(:,1:3),'rows');

%Calculate variables over combined table
for vsamp = 1:height(cfg.variables)
    if strcmp(cfg.variables.calculation{vsamp},'mean')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data_t.(cfg.variables.in{vsamp}),[],@mean);
    elseif strcmp(cfg.variables.calculation{vsamp},'unique')
        data_g.(cfg.variables.out{vsamp}) = groupsummary(data_t.(cfg.variables.in{vsamp}),idx,"numunique");
    elseif strcmp(cfg.variables.calculation{vsamp},'count')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data_t.(cfg.variables.in{vsamp}),[],@sum);
    elseif strcmp(cfg.variables.calculation{vsamp},'sum')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data_t.(cfg.variables.in{vsamp}),[],@sum);
    elseif strcmp(cfg.variables.calculation{vsamp},'min')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data_t.(cfg.variables.in{vsamp}),[],@min);
    elseif strcmp(cfg.variables.calculation{vsamp},'max')
        data_g.(cfg.variables.out{vsamp}) = accumarray(idx,data_t.(cfg.variables.in{vsamp}),[],@max);
    end
end

%Add final lat/lon/alt
[data_g.lat,data_g.lon,data_g.alt] = ecef2geodetic(cfg.spheroid,data_g.x,data_g.y,data_g.z);

%% CREATE OUTPUT
out = data_g;
end
