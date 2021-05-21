function out = facereader2matlab(cfg)
%clearvars
%cfg.datafolder = 'C:\data\Ondrej\Gina\Rawdata\Rit01';
%cfg.facereaderfile = 'FaceReader.txt';

if ~isfield(cfg, 'datafolder')
    error('facereader2matlab:No datafolder file provided, type "help facereader2matlab" for options');
end
if ~isfield(cfg, 'facereaderfile')
    error('facereader2matlab:No facereaderfile file provided, type "help facereader2matlab" for options');
end

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
    out.time = rot90(fliplr(time));
    out.neutral = rot90(fliplr(x(2,2:end)));
    out.happy = rot90(fliplr(x(3,2:end)));
    out.sad = rot90(fliplr(x(4,2:end)));
    out.angry = rot90(fliplr(x(5,2:end)));
    out.surprised = rot90(fliplr(x(6,2:end)));
    out.scared = rot90(fliplr(x(7,2:end)));
    out.disgusted = rot90(fliplr(x(8,2:end)));
    out.valence = rot90(fliplr(x(9,2:end)));
    out.arousal = rot90(fliplr(x(10,2:end)));
    out.orig = "C:\\data\\Wilco\\Gent\\data";
    out.datatype = "facereader";
else
    out = [];
end
end