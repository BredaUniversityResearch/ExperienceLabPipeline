function out = segment_eda(cfg, data)
% function out = segment_eda(cfg, data);
% segments EDA data (in matlab formt) around a trigger point.
% It returns conductance and z-transformed conductance.
% input data are e.g. the output struct from empatica2matlab
%
% cfg options are:
% cfg.trigger_time: date string specifying the time point of interest (trigger point)
% cfg.pretrigger: time in seconds before trigger point
% cfg.posttrigger: time in seconds after trigger point, can also be string 'EOF', in which case data are included until the end of the recordings
%
% pretrigger and posttrigger together define the data segment that results
% from this function.
%
% Marcel & Wilco, 05-04-2018

%check for pretrigger
if ~isfield(cfg, 'pretrigger')
    cfg.pretrigger = 0;
end

% find timestamp (seconds) of trigger
% find timestamp (seconds) of preTrigger
% find timestamp (seconds) of postTrigger
triggertime = etime(datevec(cfg.trigger_time),datevec(data.initial_time_stamp_mat));
pretrigger = triggertime-cfg.pretrigger;

%determine posttrigger depending on user input
if isnumeric(cfg.posttrigger)
    posttrigger = triggertime+cfg.posttrigger;
elseif strcmpi('EOF', cfg.posttrigger)
   posttrigger = data.time(numel(data.time));
else
    error('segment_eda: cfg.posttrigger is not correctly specified. Type help segment_eda for options');
end

if pretrigger < 0
    error(strcat('trigger time is defined {' , num2str(pretrigger) , '} seconds, before data onset, this is impossible. Check initial time stamp of input data, and trigger time'));
end
if posttrigger > data.time(length(data.time))
    error(strcat('EDA Participant Offset is set {',num2str(posttrigger-data.time(length(data.time))),'} seconds after duration of the EDA file. This may not happen! Please Check participant Offset!'));
end
    
% reposition events if any are in the selected segment, create a dummy
% event if not
if isfield(data, 'event') % events exist in the recordings
    j=1;
    for  i = 1:numel(data.event) % reposition events
        if (data.event(i).time >= pretrigger) && (data.event(i).time <=  posttrigger)       
            newevent(j).time = data.event(i).time-pretrigger;
            newevent(j).nid = j;
            newevent(j).name = strcat('event', int2str(newevent(j).time));  
            j=j+1;
        end
    end
    if j == 1 % no events in selected segment, create a dummy event at t=0 (needed for Ledalab).
        newevent(j).time = 0;
        newevent(j).nid = 1;
        newevent(j).name = 'dummy_event';
        newevent.userdata = [];
    end
else % no events at all in original recordings, create dummy event at t=0 of new segment (needed for Ledalab).
    newevent.time = 0;
    newevent.nid = 1;
    newevent.name = 'dummy_event';
    newevent.userdata = [];
end


% cut out data and time segments; if phasic and tonic components are there, also segment those
newtime = [];
newconductance = [];
newconductance_z = [];
newphasic = [];
newphasic_z = [];
newtonic = [];
newtonic_z = [];
neweventchan = [];
for  i = 1:numel(data.time)
    if (data.time(i) >= pretrigger) && (data.time(i) <=  posttrigger)
        newtime = [newtime,data.time(i)-pretrigger];
        newconductance = [newconductance,data.conductance(i)];
        if isfield(data, 'conductance_z'); newconductance_z = [newconductance_z,data.conductance_z(i)]; end
        if isfield(data, 'phasic'); newphasic = [newphasic,data.phasic(i)]; end
        if isfield(data, 'phasic_z'); newphasic_z = [newphasic_z,data.phasic_z(i)]; end
        if isfield(data, 'tonic'); newtonic = [newtonic,data.tonic(i)]; end
        if isfield(data, 'tonic_z'); newtonic_z = [newtonic_z,data.tonic_z(i)]; end
        if isfield(data, 'eventchan'); neweventchan = [neweventchan,data.eventchan(i)]; end
    end
end

out = data;
out.time = newtime;
out.conductance = newconductance;
if numel(newconductance_z) > 0 % create z-transformed conductance if it didn't already exist
    out.conductance_z = newconductance_z; 
else
    out.conductance_z = zscore(out.conductance);
end
if numel(newphasic) > 0; out.phasic = newphasic; end
if numel(newphasic_z) > 0; out.phasic_z = newphasic_z; end
if numel(newtonic) > 0; out.tonic = newtonic; end
if numel(newtonic_z) > 0; out.tonic_z = newtonic_z; end
if numel(neweventchan) > 0; out.eventchan = neweventchan; end
out.initial_time_stamp_mat = datestr(datetime(cfg.trigger_time)-seconds(cfg.pretrigger));
out.initial_time_stamp = data.initial_time_stamp + pretrigger;
out.event = newevent;
end


