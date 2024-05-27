function dimensions = minimizeWhitespace(gca)
% MINIMIZEWHITESPACE 
%   Takes the current chart
%   removes the white space around it
%   and returns the dimensions
%   [left bottom ax_width ax_height]
%
% Created by Hans Revers, 27 sept 2023

    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4); 
    dimensions = [left bottom ax_width ax_height];
end