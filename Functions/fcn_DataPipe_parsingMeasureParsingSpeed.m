function fcn_DataPipe_parsingMeasureParsingSpeed(rootSourceDrive, speedTestOutputPath, varargin)
%% fcn_DataPipe_parsingMeasureParsingSpeed
% Checks and measures parsing speeds
%
% FORMAT:
%
%      fcn_DataPipe_parsingMeasureParsingSpeed(rootSourceDrive, speedTestOutputPath, (figNum));
%
% INPUTS:
%
%      rootSourceDrive: a string containing the path of the 
%      directory containing the unsorted bags.
%
%      speedTestOutputPath: a string containing the path of the 
%      directory containing the sorted bags.
%
%      (OPTIONAL INPUTS)
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed. Default is no figure.
%
% OUTPUTS:
%
%      (none)
%
% DEPENDENCIES:
%
%    fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataPipe_parsingMeasureParsingSpeed
%     for a full test suite.
%
% This version of the function was written on 2025_12_14 by S. Brennan
% Questions or comments? sbrennan@psu.edu


% REVISION HISTORY:
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of DataPipe demo

% TO-DO:
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
% (fill in items here)

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 3; % The largest Number of argument inputs to the function
flag_max_speed = 0; % The default. This runs code with all error checking
if (nargin==MAX_NARGIN && isequal(varargin{end},-1))
    flag_do_debug = 0; % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_LAPS_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_LAPS_FLAG_CHECK_INPUTS");
    MATLABFLAG_LAPS_FLAG_DO_DEBUG = getenv("MATLABFLAG_LAPS_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_LAPS_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_LAPS_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_LAPS_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_LAPS_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(2,MAX_NARGIN);

        % % Check the rootSourceDrive to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(rootSourceDrive, 'DoesDirectoryExist');
        % 
        % % Check the speedTestOutputPath to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(speedTestOutputPath, 'DoesDirectoryExist');

    end
end

% % The following area checks for variable argument inputs (varargin)
% 
% % Does the user want to specify the flagHaltIfFail?
% % Set defaults first:
% flagHaltIfFail = false; % Default case
% if 2 <= nargin
%     temp = varargin{1};
%     if ~isempty(temp)
%         % Set the end values
%         flagHaltIfFail = temp;
%     end
% end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed) && (MAX_NARGIN == nargin)
    temp = varargin{end};
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp; %#ok<NASGU>
        flag_do_plots = 1;
    end
end

% % For debugging
% flag_do_start_end = 1; % Flag to calculate the start and end segments
%
% % Check the outputs
% nargoutchk(0,3)
%
% % Show results thus far
% if flag_do_debug
%     fprintf(1,'After variable checks, here are the flags: \n');
%     fprintf(1,'Flag: flag_start_is_a_point_type = \t\t%d\n',flag_start_is_a_point_type);
%     fprintf(1,'Flag: flag_end_is_a_point_type = \t\t%d\n',flag_end_is_a_point_type);
%     fprintf(1,'Flag: flag_use_excursion_definition = \t%d\n',flag_use_excursion_definition);
%     fprintf(1,'Flag: flag_excursion_is_a_point_type = \t%d\n',flag_excursion_is_a_point_type);
% end


%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____ _               _                         _    _____      _     _____               _                _____                     _
%  / ____| |             | |        /\             | |  / ____|    | |   |  __ \             (_)              / ____|                   | |
% | |    | |__   ___  ___| | __    /  \   _ __   __| | | (___   ___| |_  | |__) |_ _ _ __ ___ _ _ __   __ _  | (___  _ __   ___  ___  __| |___
% | |    | '_ \ / _ \/ __| |/ /   / /\ \ | '_ \ / _` |  \___ \ / _ \ __| |  ___/ _` | '__/ __| | '_ \ / _` |  \___ \| '_ \ / _ \/ _ \/ _` / __|
% | |____| | | |  __/ (__|   <   / ____ \| | | | (_| |  ____) |  __/ |_  | |  | (_| | |  \__ \ | | | | (_| |  ____) | |_) |  __/  __/ (_| \__ \
%  \_____|_| |_|\___|\___|_|\_\ /_/    \_\_| |_|\__,_| |_____/ \___|\__| |_|   \__,_|_|  |___/_|_| |_|\__, | |_____/| .__/ \___|\___|\__,_|___/
%                                                                                                      __/ |        | |
%                                                                                                     |___/         |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Check%20And%20Set%20Parsing%20Speeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Measure the parsing speed of this computer? (WARNING: takes a LONG time)

% Identify the source folders to use
sourceUTestDirectory  = cat(2,rootSourceDrive,'\FoldersForTestingProcessingSteps');
sourceUTestDirectory = uigetdir(sourceUTestDirectory,'Select the folder to test the processing steps. It is usually called \\FoldersForTestingProcessingSteps\ParseTestInput');
% If the user hits cancel, it returns 0
if 0==sourceUTestDirectory
    return;
end
speedTestInputPath = sourceUTestDirectory;
fcn_DataPipe_helperConfirmDirectoryExists(speedTestInputPath, (1), (-1));
fcn_DataPipe_helperConfirmDirectoryExists(speedTestOutputPath, (1), (-1));



% Format the path names to be consistent with Python external call, so need
% to switch backslash to forward slash
speedTestInputPathFormatted  = strrep(speedTestInputPath,'\','/');
speedTestOutputPathFormatted = strrep(speedTestOutputPath,'\','/');

% Change directory?
currentPath = cd;
python_file = fullfile(currentPath,"main_bag_to_csv_py3_poseOnly.py");
if 2~=exist(python_file,'file')
    python_file = fullfile(currentPath,'bag_to_csv_code',"main_bag_to_csv_py3_poseOnly.py");
    if 2~=exist(python_file,'file')
        error('Unable to find folder with python file in it!');
    else
        cd('bag_to_csv_code\')
    end
else
    % Already inside bag_to_csv_code directory. Need to update the
    % currentPath variable
    cd('..');
    currentPath = cd;
    cd('bag_to_csv_code\')
end

% Clear outputs
directory_speedTesting = fcn_DebugTools_listDirectoryContents({speedTestOutputPathFormatted}, ('*.*'), (2), (-1));
if length(directory_speedTesting)~=2
    warning('on','backtrace');
    warning('The ParseTestOutput directory in the testing area must be empty. Please delete the contents before running a speed test!');
    disp('Press any key to continue.\n');
    pause;
end

% Get files that do not have camera data
directory_speedTesting = fcn_DebugTools_listDirectoryContents({speedTestInputPath}, ('mapping_van_2024-*.bag'), (0), (-1));
file_speedTesting = directory_speedTesting(1).name;
tempBytes = directory_speedTesting(1).bytes;

% Build the pose-only command
parse_command = sprintf('py main_bag_to_csv_py3_poseOnly.py -s %s -d %s -b %s',speedTestInputPathFormatted, speedTestOutputPathFormatted, file_speedTesting);
fprintf(1,'Running POSE ONLY system parse command: \n\t%s\n',parse_command);
fprintf(1,'WARNING: this may take several minutes.\n');

% Time the result of pose-only
tstart = tic;
[status,cmdout] = system(parse_command,'-echo'); %#ok<ASGLU>
telapsed = toc(tstart);
bytesPerSecond = tempBytes/telapsed;
fprintf(1,'Processing speed, bytesPerSecondPoseOnly, in bytes per second (bytesPerSecondPoseOnly): %.0f\n',bytesPerSecond);

% Build the FULL parsing command
file_speedTesting = directory_speedTesting(2).name;
tempBytes = directory_speedTesting(2).bytes;
parse_command = sprintf('py main_bag_to_csv_py3.py -s %s -d %s -b %s',speedTestInputPathFormatted, speedTestOutputPathFormatted, file_speedTesting);
fprintf(1,'Running FULL system parse command: \n\t%s\n',parse_command);
fprintf(1,'WARNING: this usually takes 10 to 50 times longer than the previous command.\n');

% Time the result of full parsing
tstart = tic;
[status,cmdout] = system(parse_command,'-echo'); %#ok<ASGLU>
telapsed = toc(tstart);
bytesPerSecond = tempBytes/telapsed;
fprintf(1,'Processing speed, bytesPerSecondFull, in bytes per second (bytesPerSecondFull): %.0f\n',bytesPerSecond);
computerIDdoingParsing = string(java.net.InetAddress.getLocalHost().getHostName());
fprintf(1,'If desired, the computerIDdoingParsing for computer: %s \n',computerIDdoingParsing);
fprintf(1,'Could be updated with the above values in function fcn_DataPipe_helperFillDefaultDrives. This is not updated automatically.\n');
fprintf(1,'Hit any key to continue.\n');
pause;

% % Get files that do not have camera data
% directory_speedTesting = fcn_DebugTools_listDirectoryContents({speedTestPath}, ('mapping_van_cameras_2024-*.bag'), (0), (-1));
% file_speedTesting = directory_speedTesting(1).name;
% tempBytes = directory_speedTesting(1).bytes;
%
% % Build the pose-only command
% parse_command = sprintf('py main_bag_to_csv_py3.py -s %s -d %s -b %s', speedTestPathFormatted, speedTestOutputFormatted, file_speedTesting);
%
% % Time the result of camera parsing (does not work?)
% tstart = tic;
% [status,cmdout] = system(parse_command,'-echo');
% telapsed = toc(tstart);
% bytesPerSecond = tempBytes/telapsed;
% fprintf(1,'Processing speed, PoseOnly, in bytes per second (bytesPerSecondPoseOnly): %.0f\n',bytesPerSecond);

cd(currentPath);

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots


    % % plot the final XY result
    % figure(figNum);
    % clf;
    %
    % % Everything put together
    % subplot(1,2,1);
    % hold on;
    % grid on
    % title('Results of breaking data into laps');
    %
    %
    %
    % % Plot the indices per lap
    % all_ones = ones(length(input_path(:,1)),1);
    %
    % % fill in data
    % start_of_lap_x = [];
    % start_of_lap_y = [];
    % lap_x = [];
    % lap_y = [];
    % end_of_lap_x = [];
    % end_of_lap_y = [];
    % for ith_lap = 1:Nlaps
    %     start_of_lap_x = [start_of_lap_x; cell_array_of_entry_indices{ith_lap}; NaN]; %#ok<AGROW>
    %     start_of_lap_y = [start_of_lap_y; all_ones(cell_array_of_entry_indices{ith_lap})*ith_lap; NaN]; %#ok<AGROW>;
    %     lap_x = [lap_x; cell_array_of_lap_indices{ith_lap}; NaN]; %#ok<AGROW>
    %     lap_y = [lap_y; all_ones(cell_array_of_lap_indices{ith_lap})*ith_lap; NaN]; %#ok<AGROW>;
    %     end_of_lap_x = [end_of_lap_x; cell_array_of_exit_indices{ith_lap}; NaN]; %#ok<AGROW>
    %     end_of_lap_y = [end_of_lap_y; all_ones(cell_array_of_exit_indices{ith_lap})*ith_lap; NaN]; %#ok<AGROW>;
    % end
    %
    % % Plot results
    % plot(start_of_lap_x,start_of_lap_y,'g-','Linewidth',3,'DisplayName','Prelap');
    % plot(lap_x,lap_y,'b-','Linewidth',3,'DisplayName','Lap');
    % plot(end_of_lap_x,end_of_lap_y,'r-','Linewidth',3,'DisplayName','Postlap');
    %
    % h_legend = legend;
    % set(h_legend,'AutoUpdate','off');
    %
    % xlabel('Indices');
    % ylabel('Lap number');
    % axis([0 length(input_path(:,1)) 0 Nlaps+0.5]);
    %
    %
    % subplot(1,2,2);
    % % Plot the XY coordinates of the traversals
    % hold on;
    % grid on
    % title('Results of breaking data into laps');
    % axis equal
    %
    % cellArrayOfPathsToPlot = cell(Nlaps+1,1);
    % cellArrayOfPathsToPlot{1,1}     = input_path;
    % for ith_lap = 1:Nlaps
    %     temp_indices = cell_array_of_lap_indices{ith_lap};
    %     if length(temp_indices)>1
    %         dummy_path = input_path(temp_indices,:);
    %     else
    %         dummy_path = [];
    %     end
    %     cellArrayOfPathsToPlot{ith_lap+1,1} = dummy_path;
    % end
    % h = fcn_Laps_plotLapsXY(cellArrayOfPathsToPlot,figNum);
    %
    % % Make input be thin line
    % set(h(1),'Color',[0 0 0],'Marker','none','Linewidth', 0.75);
    %
    % % Make all the laps have thick lines
    % for ith_plot = 2:(length(h))
    %     set(h(ith_plot),'Marker','none','Linewidth', 5);
    % end
    %
    % % Add legend
    % legend_text = {};
    % legend_text = [legend_text, 'Input path'];
    % for ith_lap = 1:Nlaps
    %     legend_text = [legend_text, sprintf('Lap %d',ith_lap)]; %#ok<AGROW>
    % end
    %
    % h_legend = legend(legend_text);
    % set(h_legend,'AutoUpdate','off');
    %
    %
    %
    % %     % Plot the start, excursion, and end conditions
    % %     % Start point in green
    % %     if flag_start_is_a_point_type==1
    % %         Xcenter = start_zone_definition(1,1);
    % %         Ycenter = start_zone_definition(1,2);
    % %         radius  = start_zone_definition(1,3);
    % %         INTERNAL_plot_circle(Xcenter, Ycenter, radius, [0 .7 0], 4);
    % %     end
    % %
    % %     % End point in red
    % %     if flag_end_is_a_point_type==1
    % %         Xcenter = end_definition(1,1);
    % %         Ycenter = end_definition(1,2);
    % %         radius  = end_definition(1,3);
    % %         INTERNAL_plot_circle(Xcenter, Ycenter, radius, [0.7 0 0], 2);
    % %     end
    % %     legend_text = [legend_text, 'Start condition'];
    % %     legend_text = [legend_text, 'End condition'];
    % %     h_legend = legend(legend_text);
    % %     set(h_legend,'AutoUpdate','off');
    %
    % % Plot start zone
    % h_start_zone = fcn_Laps_plotZoneDefinition(start_zone_definition,'g-',figNum);
    %
    % % Plot end zone
    % h_end_zone = fcn_Laps_plotZoneDefinition(end_zone_definition,'r-',figNum);


end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§
