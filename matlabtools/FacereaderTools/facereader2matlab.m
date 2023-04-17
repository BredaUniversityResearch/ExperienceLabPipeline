function out = facereader2matlab(cfg)
%% FACEREADER 2 MATLAB
%function out = facereader2matlab(cfg)
%
% *DESCRIPTION*
%function to read the facereader txt file into matlab
%
% *INPUT*
%Configuration Options
%cfg.datafolder = directory the data is placed in
%cfg.facereaderfile = (OPTIONAL) name of the file
%           default = 'FaceReader.txt';
%
% *OUTPUT*
%Structure containing the data from the facereader file
%
% *NOTES*
%NA
%
% *BY*
%Wilco Boode

%% DEV INFO
%This function was partially developed, but never fully implemented in a
%project, need some cleanup and a sensibility check.
%The data is not perfectly linear afaik, might be good to change it to a
%linear datastream for easier analysis afterwards.

%% VARIABLE CHECK
if ~isfield(cfg, 'datafolder')
    error('facereader2matlab:No datafolder file provided, type "help facereader2matlab" for options');
end
if ~isfield(cfg, 'facereaderfile')
    cfg.facereaderfile = 'FaceReader.txt';
    warning('facereader2matlab:No facereaderfile file provided, type "help facereader2matlab" for options');
end

%% LOAD DATA AND STRUCTURE IT
curdir = pwd;
eval(sprintf('cd %s', cfg.datafolder));


if exist(cfg.facereaderfile, 'file')
    z=textread(cfg.facereaderfile,'%s','delimiter','\n');
    fsample = regexp(z{7,1},'\t','split');
    fsample = str2num(fsample{1,2});
    z=z(9:end);
    q = regexp(z,'\t','split');
    x = reshape([q{:}],[length(q{1,1}),length(z)]);
    
    videotime = rot90(fliplr(x(1,2:end)));
    t = datevec(videotime);
    time = [];
    
    for  i = 1:length(t)
        H = t(i,4) * 3600;
        MN =  t(i,5) * 60;
        S =  t(i,6);
        thistime = H+MN+S;
        time = [time,thistime];
    end
    
    out.fsample = fsample;
    out.time = transpose(time));
    out.neutral = transpose(x(2,2:end));
    out.happy = transpose(x(3,2:end));
    out.sad = transpose(x(4,2:end));
    out.angry = transpose(x(5,2:end));
    out.surprised = transpose(x(6,2:end));
    out.scared = transpose(x(7,2:end));
    out.disgusted = transpose(x(8,2:end));
    out.valence = transpose(x(9,2:end));
    out.arousal = transpose(x(10,2:end));
    out.orig = "C:\\data\\Wilco\\Gent\\data";
    out.datatype = "facereader";
else
    out = [];
end
end