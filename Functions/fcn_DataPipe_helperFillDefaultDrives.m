function [defaultDriveRoot, diskNumber, allDriveLetters, allDriveNames]  ...
    = fcn_DataPipe_helperFillDefaultDrives(defaultDriveRoot, varargin)

%fcn_DataPipe_helperFillDefaultDrives
%     examines the current drives available and sets default drives
%
% METHOD: find real disk drives by checking which physical drives exist.
% Empty drives have no size.
% 
% On PCs, some volumes list that are empty - these have all spaces in their
% serial numbers. These are excluded from the output 'allDriveLetters'
% 
% If the default drives are not found, returns first drive as choice
%
%
% FORMAT:
%
%      [defaultDriveRoot, diskNumber, allDriveLetters, allDriveNames]  ...
%       = fcn_DataPipe_helperFillDefaultDrives(defaultDriveRoot, (infoTable), (figNum));
% 
% INPUTS:
%
%      defaultDriveRoot: the likely drive root (c:, d:, etc.) to use, if no
%      other drive root is found
%
%      (OPTIONAL INPUTS)
%
%      infoTable = system.listPhysicalDrives() returns a table which contains
%      the following variables:
%          DeviceID        : The device id (drive letter / disk number)
%          VolumeName      : Name of drive / volume
%          SerialNumber    : Serial number of drive / volume
%          FileSystem      : File system, i.e ntfs, ex-fat, apfs (Note: only for windows)
%          Size            : Physical storage size
%          SizeUnit        : Actual unit for size, i.e MB, GB, TB
%      If not entered, the code calls the function:
%      fcn_DataPipe_helperListPhysicalDrives to fill these values.
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed. Default is no figure.
%
% OUTPUTS:
%
%      defaultDriveRoot: the suggested drive root to use as default.
%      Returns empty value if defaults not found. Defaults are either
%      drive names containing "ADS" or drives that match the user-given
%      default.
%
%      diskNumber: the index of the suggested drive to use
%
%      allDriveLetters: a list of all non-empty drive letters
%
%      allDriveNames: the names of all non-empty drives
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%      fcn_DataPipe_helperListPhysicalDrives
%      fcn_DataPipe_helperFindNonEmptyDrives
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataPipe_helperFillDefaultDrives
%     for a full test suite.
%
% This function was written on 2025_12_03 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of ParseData demo


% TO-DO:
%
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% - (fill in items here)



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
        narginchk(1,MAX_NARGIN);

        % % Check the input_path to be sure it has 2 or 3 columns, minimum 2 rows
        % % or more
        % fcn_DebugTools_checkInputsToFunctions(input_path, '2or3column_of_numbers',[2 3]);
    end
end



% The following area checks for variable argument inputs (varargin)

% Does the user want to specify the infoTable?
infoTable = []; % Set the default value (empty values are filled in later, in Main)
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        infoTable = temp;
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed) && (MAX_NARGIN == nargin) 
    temp = varargin{end};
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp; %#ok<NASGU>
        flag_do_plots = 1;
    end
end

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

if isempty(infoTable)
    infoTable = fcn_DataPipe_helperListPhysicalDrives((-1));
end

% Use this section to save test data
if 1==0
    fullExampleFilePath = fullfile(cd,'Data','ExampleData_helperFillDefaultDrives_case20001.mat');
    save(fullExampleFilePath,'infoTable');
end

% METHOD: find real disk drives by checking which physical drives exist.
% Empty drives have no size.
% On PCs, some volumes list that are empty - these have all spaces in their
% serial numbers
% If the default drives are not found, returns first drive as choice

% Keep only non-empty drives
nonEmptyInfoTable = fcn_DataPipe_helperFindNonEmptyDrives((infoTable), (-1));


% Make a list of drive root options
NgoodDisks = size(nonEmptyInfoTable,1);

% Check defaults
currentChoice = [];
allDriveLetters = cell(NgoodDisks,1);
allDriveNames   = cell(NgoodDisks,1);
for ith_root = 1:NgoodDisks
    thisDriveLetter = char(nonEmptyInfoTable(ith_root,:).DeviceID);
    thisDriveName = char(nonEmptyInfoTable(ith_root,:).VolumeName);
    thisVolumeName = nonEmptyInfoTable(ith_root,:).VolumeName;
    thisFileSystem = char(nonEmptyInfoTable(ith_root,:).FileSystem);
    thisVolumeName = char(thisVolumeName);
    thisSize =  nonEmptyInfoTable(ith_root,:).Size;
    thisUnit =  nonEmptyInfoTable(ith_root,:).SizeUnit;
    thisDriveType =  nonEmptyInfoTable(ith_root,:).DriveType;


    if isempty(defaultDriveRoot)
        if contains(thisDriveName,'ADSPrimary1')
            currentChoice = ith_root;
        elseif isempty(currentChoice) && contains(thisDriveName,'ADS')
            currentChoice = ith_root;
        end
    elseif contains(thisDriveLetter,defaultDriveRoot)
        currentChoice = ith_root;
    end

    % Fill in drive letters and names
    if strcmp(thisVolumeName,"")
        thisVolumeName = "-unnamed-";
    end

    thisFullDriveName = sprintf('%s %s %s %.3f%s %s',...
        thisDriveLetter,...
        thisVolumeName,...
        thisFileSystem,...
        thisSize, ...
        thisUnit, ...
        thisDriveType);

    allDriveLetters{ith_root,1} = thisDriveLetter;
    allDriveNames{ith_root,1} = thisFullDriveName;
end

if isempty(currentChoice)
    % Default is to use first one
    currentChoice = 1;
end

% Based on current choice, return values
if ~isempty(currentChoice)
    defaultDriveRoot = allDriveLetters{currentChoice,1};
    diskNumber = currentChoice;
else
    defaultDriveRoot = [];
    diskNumber = [];
end


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
