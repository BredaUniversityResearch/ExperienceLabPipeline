function out = segment_event(cfg, data)
% function out = segment_event(cfg, data)
% function to resegment the event data from the Empatica Devices
%
% configuration options are:
%
% cfg options are:
% cfg.trigger_time: date string specifying the time point of interest (trigger point)
% cfg.pretrigger: time in seconds before trigger point
% cfg.posttrigger: time in seconds after trigger point
%
% Wilco Boode, 11-04-2019
%
% Update: added else statement under IsEmpty to create empty array (can
% happen with short E4 Files)

%check for pretrigger
if ~isfield(cfg, 'pretrigger')
    cfg.pretrigger = 0;
end

%calculate when the file must start (based on data timestamp & trigger_time)
triggertime = datetime(cfg.trigger_time);
pretrigger = triggertime-seconds(cfg.pretrigger);

%check whether the posttrigger is defined, if not then the posttrigger will be equal
%to the final date/time
if ~isempty(data.event)
    if ~isfield(cfg, 'posttrigger')
        cfg.posttrigger = seconds(datetime(data.event(length(data.event)).time_stamp_mat)-datetime(data.event(1).time_stamp_mat));
        error('posttrigger undefined: will use entire file');
    end
    
    %event=struct([]);
    fields = {'time_stamp','time_stamp_mat','nid','name','time'}
    c = cell(length(fields),0);
    event = cell2struct(c,fields);
    
    for i=1:length(data.event)
        data.event(i).time = seconds(datetime(data.event(i).time_stamp_mat)-datetime(cfg.trigger_time,'TimeZone',data.event(i).time_stamp_mat.TimeZone))
        
        if data.event(i).time > -cfg.pretrigger && data.event(i).time < cfg.posttrigger
            event(length(event)+1) = data.event(i);
            break;
        end
    end
else
    event = [];
end

%output the requried data
out = data;
out.event = event;
out.timeoff = cfg.pretrigger;
out.initial_time_stamp_mat = pretrigger;
out.initial_time_stamp = datenum2unixmillis(datenum(pretrigger));


end

