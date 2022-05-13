function out = depersonalize_beacon(cfg)
%This function is developed to help simplify the depersonalization process
%of beacon data. It seraches for prefixed folders (P002), and
%replaced files with a certain name (beacon.csv), with one where the first
%line uses the folder name, rather than the originally provided participant
%name.
%
%Configuration Options:
%cfg.folderprefix = the prefix of participant folders. Is 'P' (for P002) by
%   default
%cfg.filecontains = will change files with a specific text in the name. Is
%   'beacon' by default (for beacon.csv / beacon P002.csv)
%cfg.datafolder = the folder containing the participantfolders (0.RawData).
%   Will open a folder picker by default.
%
%Wilco Boode 13/05/2022

%Set the default values
if ~isfield(cfg,'folderprefix')
    cfg.folderprefix = 'P';
end
if ~isfield(cfg,'filecontains')
    cfg.filecontains = 'beacon';
end
if ~isfield(cfg,'datafolder')
    %Open a folder picker
    cfg.datafolder = uigetdir(pwd);
end

%Get the main folder foles and subfolders
files = dir(cfg.datafolder);
subFolders = files([files.isdir]);
subFolderNames = {subFolders(3:end).name};

%Go over all subfolders, if they detect the indicated folder prefix, then
%it will look for files with the filecontains, and trigger the
%TextReplacement
personalized = 0;
for k = 1 : length(subFolderNames)
    if strcmp(subFolderNames{k}(1),cfg.folderprefix)
        fdir = strcat(cfg.datafolder,'\',subFolderNames{k});
        ffiles = dir(fdir);
        for l = 1 : length(ffiles)
            if contains(lower(ffiles(l).name),cfg.filecontains)
                replacetext (strcat(fdir,'\',ffiles(l).name),subFolderNames{k});
                personalized = personalized+1;
            end
        end
    end
end

%Get the file, replace the 8th item with the provided name, and save the
%file using the original file name.
    function out = replacetext(file,name)
        S = readlines(file);
        Sl = split(S{1},',');
        Sl{8} = strcat('"',name,'"');
        S(1) = strjoin(Sl,',');

        [fid, msg] = fopen(file, 'w');
        if fid < 1
            error('could not write output file because "%s"', msg);
        end
        fwrite(fid, strjoin(S, '\n'));
        fclose(fid);
        out = 1;
    end
out = personalized;
end