function out = getgrandaverages (data, cfg)

% cfg.datatypes = ["conductance" "phasic"];
% data = scr_data;

fields = fieldnames(data);

c_data = [];
m_data = [];

for type = 1:length(cfg.datatypes)
    if max(contains(fields,cfg.datatypes(type))) == 1
        longest = 0;
        c_data = [];
        for p = 1:length(data)
            thislength = length(data(p).(cfg.datatypes(type)));
            if thislength > longest
                longest = thislength;
            end
        end
        for p = 1:length(data)
            n_data = nan(1,longest);
            thislength = length(data(p).(cfg.datatypes(type)));
            n_data(1,1:thislength) = data(p).(cfg.datatypes(type));
            c_data = [c_data;n_data];
        end
        m_data.(cfg.datatypes(type)) = mean(c_data,'omitnan');
    else
        warning(strcat(cfg.datatypes(type)," DOES NOT EXIST IN DATA FILE, SKIPPING DATATYPE FOR GRAND AVERAGING"));
    end
end

averagesstruct = struct();
for field = 1:length(fields)
    fieldname = string(fields(field));
    averagesstruct.(fieldname) = NaN;
    if ~isempty(intersect(cfg.datatypes,fieldname))
        averagesstruct.(fieldname) = m_data.(fieldname)';
    end
end 

averagesstruct.participant = -1;

data(length(data)+1) = averagesstruct;

out = data;
end