%% Create Documentation
%This script is here to help you generate the latest documentation for the
%ExperienceLab 

%% Documentation Guidelines
% Simple rules for the documentation
% SCRIPT NAME, DESCRIPTION, INPUT, OUTPUT, NOTES, BY

%% Index all Functions & Structure
%Go to the location, and browse all folders for files to output
%Exclude folders we dont want
%Create structure with "location" and "filename"

%% Generate XML Files from Functions


%% Generate _help.m Files

%% Generate HTML File

%% Setup
%Setup file location variables
location = "G:\EXP_Lab\ExperienceLabPipelineGit\matlabtools";
folder = "DataTools";
script = 'segment_generic';

%% Grab Description 

%Determine file to open, and open this file in read mode
inputfile = fullfile(location,folder,strcat(script,'.m'));
fid = fopen(inputfile,'rt');

%setup description variables
description = [];
indescription = 0;

%loop over file, and while the first character = %, and were in the
%description (first block with % as first characters), append the lines to 
%the string matrix 
while ~feof(fid)
    tline = fgetl(fid);
    if length(tline)>0 && tline(1) == '%'
        indescription = 1;
        description = [description;string(tline)];
    else
        if indescription == 1
            break;
        end
    end
end
%close the file (NECESSARY!
fclose(fid);

%% Format

%Loop over the string matrix, and apply the determined formatting edits
for isamp = 1:length(description)

    %If there are 2x *, remove all * and add a % in front
    if strfind(description(isamp),"*") >1
        description(isamp) = erase(description(isamp),"*");
        description(isamp) = strcat("%",description(isamp));
    end
end

%% Export
%Determine output file name and location
location = "G:\EXP_Lab\ExperienceLabPipelineGit\documentation\ExperienceLabToolbox";

outputfile = fullfile(location,strcat(script,"_help.m"));

%check if the file already exists, and delete it if so
if isfile(outputfile)
    delete outputfile
end

%Open the new file, print all lines one by one, and close the file
fid = fopen(outputfile,'wt');
for isamp = 1:length(description)
    fprintf(fid,'%s\n',description(isamp));
end
fclose(fid);

%Generate HTML file from the help.m file, using the matlab publish structure
publish(outputfile);



%% SOME TESTS
location =  "G:\EXP_Lab\ExperienceLabPipelineGit\documentation";
builddocsearchdb(location);

sample = fullfile(...
         matlabroot,'help','techdoc','matlab_env',...
         'examples','upslope');
tmp = "G:\EXP_Lab\ExperienceLabPipelineGit\documentation\tempname";
mkdir(tmp);
copyfile(sample,tmp);
addpath(tmp);

folder = fullfile(tmp,'html');
builddocsearchdb(folder)

location = "G:\EXP_Lab\ExperienceLabPipelineGit\matlabtools\DataTools";
%publish('segment_generic.m')
options.showCode = false;
publish(fullfile(location,'segment_generic'),options)

