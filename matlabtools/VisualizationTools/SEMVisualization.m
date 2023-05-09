%% create plots with SEM shading

% phasic_z BUas

% smooth data for plotting

 

x = [];

y = [];

x = GA_hi_buas.time;

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

 

% phasic_z BYU

x = [];

y = [];

x = GA_hi_byu.time;

% y1 = GA_hi_byu.avg';

% y2 = GA_lo_byu.avg';

% or apply smoothing, e.g. 9 samples = 2 seconds

y1 = movmean(GA_hi_byu.avg_z', 19);

y2 = movmean(GA_lo_byu.avg_z', 19);

lo1 = GA_hi_byu.phasic_zSEMLOW';

lo2 = GA_lo_byu.phasic_zSEMLOW';

hi1 = GA_hi_byu.phasic_zSEMHIGH';

hi2 = GA_lo_byu.phasic_zSEMHIGH';

 

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

 

legend([patch_movie, patch_non_movie],{'SCR phasic z high disclosure BYU','SCR phasic z low disclosure BYU'});