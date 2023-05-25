function out = SEMVisualization (cfg,data)
%% NAME OF FUNCTION
% function out = SEMVisualization (cfg,data)
%
% *DESCRIPTION*
%create plots with SEM shading
%
% *INPUT*
%Information on the variables / data to feed into this function must
%contain info about the expected / possible configuration settings, and
%possibly a default / example variable
%
%Configuration Options
%cfg.variable1 = Info about this configuration variable
%cfg.variable2 = (OPTIONAL) Info about an optional configuration variable
%           default = 1;
%
%Data Requirements
%data.value1 = Description of a required variable in the data structure (if relevant)
%           example = [0 0 0 -1 -1 -1 1 1 1 1 0 0];
%
% *OUTPUT*
%Description of the output this function provides, both type of data, and
%potentialy the format it outputs
%
% *NOTES*
%Additional information about the function, for example if parts have been
%retrieved from an online source
%
% *BY*
%Name & Date when function was made or last updated

%% DEV INFO
%Information relevant for developers, things to add to the function,
%potential updates to consider

%% create plots with SEM shading



cfg = [];
cfg.patchdatalo = "tonic";
cfg.patchdatahi = "conductance";
cfg.graphdata= "phasic";
cfg.timedata = "time";
cfg.axisnames = ["Axis1"; "Axis2"];
cfg.colormap = colormap(jet);

figure;
clear hax
hax=axes;

amount = length(data);
isamp = 4;

if isamp == 1
    cloc = 1;
elseif isamp == amount
    cloc = height(cfg.colormap);
else
    cloc = int32(height(cfg.colormap)/(amount-1)*(isamp-1));
end

col = cfg.colormap(cloc,:);

x = data(isamp).time;

y = data(isamp).(cfg.graphdata);
lo = data(isamp).(cfg.patchdatalo);
hi = data(isamp).(cfg.patchdatahi);


patchvis = patch([x; x(end:-1:1); x(1)], [lo; hi(end:-1:1); lo(1)], col); % shaded area (SEM) of movie
graphvis = line(x,y); % graph of movie

hold on
%Generate all Patches
set(patchvis, 'facecolor', col, 'edgecolor', 'none');
hold on

%Generate all Graphs
set(graphvis, 'color', col,'linewidth',3);
hold on

set(gca,'FontSize',20);
set(gca,'YColor','k');
set(gca,'box','on');
xlabel('time (s)');
ylabel('SCR (microS)');

legend([patchvis, graphvis],cfg.axisnames);


%%

%x = GA_hi_buas.time;

% y1 = GA_hi_buas.avg';

% y2 = GA_lo_buas.avg';

% or apply smoothing, e.g. 9 samples = 2 seconds

y1 = movmean(GA_hi_buas.avg_z', 19);

y2 = movmean(GA_lo_buas.avg_z', 19);

lo1 = GA_hi_buas.phasic_zSEMLOW';

lo2 = GA_lo_buas.phasic_zSEMLOW';

hi1 = GA_hi_buas.phasic_zSEMHIGH';

hi2 = GA_lo_buas.phasic_zSEMHIGH';

figure;

clear hax

hax=axes;

hold on

patch_movie = patch([x; x(end:-1:1); x(1)], [lo1; hi1(end:-1:1); lo1(1)], 'r'); % shaded area (SEM) of movie

hold on;

patch_non_movie = patch([x; x(end:-1:1); x(1)], [lo2; hi2(end:-1:1); lo2(1)], 'b'); % shaded area (SEM) of non-movie

hold on;

graph_movie = line(x,y1); % graph of movie

hold on;

graph_non_movie = line(x,y2); % graph of non-movie

hold on;


% colours and line width

set(patch_movie, 'facecolor', [1 0.8 0.8], 'edgecolor', 'none');

set(patch_non_movie, 'facecolor', [0.8 0.8 1], 'edgecolor', 'none');

set(graph_movie, 'color', 'r','linewidth',3);

set(graph_non_movie, 'color', 'b','linewidth',3);


% title, axis labels, legend, flip y-axis

set(gca,'FontSize',20);

set(gca,'YColor','k');

set(gca,'box','on');

xlabel('time (s)');

ylabel('SCR (microS)');

%ylim([0.3 0.6]);


legend([patch_movie, patch_non_movie],{'SCR phasic z high disclosure BUas','SCR phasic z low disclosure BUas'});

%%

amount = 10;%length(data);
isamp = 10;

if isamp == 1
    cloc = 1;
elseif isamp == amount
    cloc = height(cfg.colormap);
else
    cloc = int32(height(cfg.colormap)/(amount-1)*(isamp-1));
end
cloc

%%