function data = ridesegmets2mat(cfg)

%NEED TO DOCUMENT #WILCO2018
    cfg.format = 'dd-mm-yyyy HH:MM:SS'
    
if ~isfield(cfg, 'ridesegments')
    cfg.ridesegments = 'ride_segments.csv';
end

curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));

[num, txt, raw] = xlsread(cfg.ridesegments);
 disp(size(txt,1))
for i=2:size(txt,1)
    
    data.start(i-1) = etime(datevec(txt(i,1),cfg.format),datevec(cfg.starttime));
    if (data.start(i-1) < 0)
        data.start(i-1) = 0
    end
    
    data.end(i-1) = etime(datevec(txt(i,2),cfg.format),datevec(cfg.starttime));
    
    if (data.end(i-1) > cfg.offset)
        data.end(i-1) = cfg.offset
    end
end

end
