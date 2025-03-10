%% script to list the timestamps of the Dance Macrabre data:
% 

%% read data
% read participant data (ppt number, match, condition, include)
clear;

% Directory on Hans' laptop. Change this to the folder that has the 0.RawData subfolder on your laptop.
% project_folder = 'C:\Hans\Projects\Forts'; 
project_folder = 'C:\Users\revers.j\BUas\602012 - Experience Lab - C11051 - Danse Macabre - Home import';


% go through all the folders
% read the file
% extract the initial unix timestamp
% convert to readable date/time
% add to a table


% Make a list of all folders
folder_list = dir(project_folder);
if size(folder_list, 1) < 3 % stop processing when the list is empty
    warning('No folders found in %s', project_folder);
end

file_counter = 1;
file_data = [];

% go through all the folders
for folder_i = 3:size(folder_list, 1) % skip the first two ( '.' and '..')
    if folder_list(folder_i).isdir
        % get all files in that folder
        file_list = dir(fullfile(folder_list(folder_i).folder, folder_list(folder_i).name));

        % go through all files
        for file_i = 3:size(file_list, 1)
            if any(regexp(file_list(file_i).name,'.csv$')) % check that the name ends with '.csv'

                shimmer_file = fullfile(file_list(file_i).folder, file_list(file_i).name);
                % Get import options for file
                opts = detectImportOptions(shimmer_file);
                % determine find provided data and column names
                datanames = opts.VariableNames;
                % Check if first line is header file
                fid = fopen(shimmer_file);
                firstLine = strsplit(fgetl(fid));
                fclose(fid);
                if max(contains(firstLine,"sep="))
                    opts.DataLines = 4;
                    opts.VariableNamesLine = 2;
                else
                    opts.DataLines = 3;
                    opts.VariableNamesLine = 1;
                end
                % get the name of the timestamp column
                c = find(contains(datanames,'Unix')==1);
                if isempty(c)
                    warning('No unix data for %s', shimmer_file);
                    continue;
                end
                timestamp_column = datanames{c};
                % load only that timestamp column
                opts.SelectedVariableNames = {};
                opts.SelectedVariableNames{1} = timestamp_column;


                % get the raw shimmer data
                shimmerraw = readtable(shimmer_file, opts);
                timestamps = shimmerraw.(timestamp_column);

                % make initial time stamp in UNIX time Seconds
                time_stamp_start = timestamps(1)/1000;
                time_stamp_end   = timestamps(end)/1000;
                time_stamp_duration = time_stamp_end - time_stamp_start;
                % make initial time stamp human-readable
                time_stamp_start_datetime = datetime(time_stamp_start,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone','Europe/Amsterdam');
                time_stamp_end_datetime   = datetime(time_stamp_end,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','dd-MMM-yyyy HH:mm:ss.SSS','TimeZone','Europe/Amsterdam');
                time_stamp_duration_datetime = datetime(time_stamp_duration,'ConvertFrom','posixtime','TicksPerSecond',1,'Format','HH:mm:ss.SSS');
                % store times in a table
                file_data(file_counter).name = file_list(file_i).name;
                file_data(file_counter).folder = file_list(file_i).folder;
                file_data(file_counter).shimmer_start = string(time_stamp_start_datetime);
                file_data(file_counter).shimmer_end = string(time_stamp_end_datetime);
                file_data(file_counter).shimmer_duration = string(time_stamp_duration_datetime);
                file_counter = file_counter + 1;
            end

        end
    end
end


% save data with unixtimestamps in an excel file
writetable(struct2table(file_data), 'timestamps_of_raw_data.csv');




%% plot start/end times of Shimmer and Strava data

% TODO: this is a quick solution, write proper detection


pps_forts1 = [1:18, 20:27, 29:50]; % 30/31 Aug
figure;
hold on;
for pp_i = pps_forts1
    disp(num2str(pp_i));
    XDates = [datetime(pp_data_unix(pp_i).strava_start) datetime(pp_data_unix(pp_i).strava_end)];
    YNumsForXDates = pp_i * ones(size(XDates));
    plot(XDates,YNumsForXDates, 'LineWidth', 2);
    plot(datetime(pp_data_unix(pp_i).shimmer_start), pp_i,'r*', 'MarkerSize', 10);  % adds a red asterisk at the point (x_pos,y_pos)
    plot(datetime(pp_data_unix(pp_i).shimmer_end), pp_i,'ro', 'MarkerSize', 10);  % adds a red circle at the point (x_pos,y_pos)
    text(datetime(pp_data_unix(pp_i).shimmer_start)-minutes(20), pp_i, pp_data_unix(pp_i).pp_label, 'HorizontalAlignment', 'right');
end
xlim([datetime('30-Aug-2024 00:00:00'), datetime('31-Aug-2024 23:59:59')]);


pps_forts2 = [51:101]; % 7/8 Sep
figure;
hold on;
for pp_i = pps_forts2
    disp(num2str(pp_i));
    XDates = [datetime(pp_data_unix(pp_i).strava_start) datetime(pp_data_unix(pp_i).strava_end)];
    YNumsForXDates = pp_i * ones(size(XDates));
    plot(XDates,YNumsForXDates, 'LineWidth', 2);
    plot(datetime(pp_data_unix(pp_i).shimmer_start), pp_i,'r*', 'MarkerSize', 10);  % adds a red asterisk at the point (x_pos,y_pos)
    plot(datetime(pp_data_unix(pp_i).shimmer_end), pp_i,'ro', 'MarkerSize', 10);  % adds a red circle at the point (x_pos,y_pos)
    text(datetime(pp_data_unix(pp_i).shimmer_start)-minutes(20), pp_i, pp_data_unix(pp_i).pp_label, 'HorizontalAlignment', 'right');
end
xlim([datetime('7-Sep-2024 00:00:00'), datetime('8-Sep-2024 23:59:59')]);


pps_forts3 = [102:151]; % 14/15 Sep
figure;
hold on;
for pp_i = pps_forts3
    disp(num2str(pp_i));
    XDates = [datetime(pp_data_unix(pp_i).strava_start) datetime(pp_data_unix(pp_i).strava_end)];
    YNumsForXDates = pp_i * ones(size(XDates));
    plot(XDates,YNumsForXDates, 'LineWidth', 2);
    plot(datetime(pp_data_unix(pp_i).shimmer_start), pp_i,'r*', 'MarkerSize', 10);  % adds a red asterisk at the point (x_pos,y_pos)
    plot(datetime(pp_data_unix(pp_i).shimmer_end), pp_i,'ro', 'MarkerSize', 10);  % adds a red circle at the point (x_pos,y_pos)
    text(datetime(pp_data_unix(pp_i).shimmer_start)-minutes(20), pp_i, pp_data_unix(pp_i).pp_label, 'HorizontalAlignment', 'right');
end
xlim([datetime('14-Sep-2024 00:00:00'), datetime('15-Sep-2024 23:59:59')]);


pps_forts4 = [152, 155, 156, 158:170]; % 15 Oct
figure;
hold on;
for pp_i = pps_forts4
    disp(num2str(pp_i));
    XDates = [datetime(pp_data_unix(pp_i).strava_start) datetime(pp_data_unix(pp_i).strava_end)];
    YNumsForXDates = pp_i * ones(size(XDates));
    plot(XDates,YNumsForXDates, 'LineWidth', 2);
    plot(datetime(pp_data_unix(pp_i).shimmer_start), pp_i,'r*', 'MarkerSize', 10);  % adds a red asterisk at the point (x_pos,y_pos)
    plot(datetime(pp_data_unix(pp_i).shimmer_end), pp_i,'ro', 'MarkerSize', 10);  % adds a red circle at the point (x_pos,y_pos)
    text(datetime(pp_data_unix(pp_i).shimmer_start)-minutes(20), pp_i, pp_data_unix(pp_i).pp_label, 'HorizontalAlignment', 'right');
end
xlim([datetime('15-Oct-2024 00:00:00'), datetime('15-Oct-2024 23:59:59')]);pps_forts4 = [131, 134, 135, 137:150]; % 15 Oct

pps_forts5 = [172:175, 177, 178, 179, 181, 182]; % 15 Nov
figure;
hold on;
for pp_i = pps_forts5
    disp(num2str(pp_i));
    XDates = [datetime(pp_data_unix(pp_i).strava_start) datetime(pp_data_unix(pp_i).strava_end)];
    YNumsForXDates = pp_i * ones(size(XDates));
    plot(XDates,YNumsForXDates, 'LineWidth', 2);
    plot(datetime(pp_data_unix(pp_i).shimmer_start), pp_i,'r*', 'MarkerSize', 10);  % adds a red asterisk at the point (x_pos,y_pos)
    plot(datetime(pp_data_unix(pp_i).shimmer_end), pp_i,'ro', 'MarkerSize', 10);  % adds a red circle at the point (x_pos,y_pos)
    text(datetime(pp_data_unix(pp_i).shimmer_start)-minutes(20), pp_i, pp_data_unix(pp_i).pp_label, 'HorizontalAlignment', 'right');
end
xlim([datetime('15-Nov-2024 00:00:00'), datetime('15-Nov-2024 23:59:59')]);