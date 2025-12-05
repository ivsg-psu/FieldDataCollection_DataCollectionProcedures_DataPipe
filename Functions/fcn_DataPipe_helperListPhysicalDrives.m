function infoTable = fcn_DataPipe_helperListPhysicalDrives(varargin)
% fcn_DataPipe_helperListPhysicalDrives List physical drives present on system
%
% NOTE: this is a wrapper for "listPhysicalDrives.m"
% Obtained from:
% https://www.mathworks.com/matlabcentral/fileexchange/121143-list-physical-drives
%
%
% FORMAT:
%
%      [infoTable] = fcn_DataPipe_helperListPhysicalDrives((figNum));
%
% INPUTS:
%
%      (none)
%
%      (OPTIONAL INPUTS)
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed. Default is no figure.
%
% OUTPUTS:
%
%   infoTable = system.listPhysicalDrives() returns a table which contains
%       the following variables:
%
%       DeviceID        : The device id (drive letter / disk number)
%       VolumeName      : Name of drive / volume
%       SerialNumber    : Serial number of drive / volume
%       FileSystem      : File system, i.e ntfs, ex-fat, apfs (Note: only for windows)
%       Size            : Physical storage size
%       SizeUnit        : Actual unit for size, i.e MB, GB, TB
%
% DEPENDENCIES:
%
%     (none)
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataPipe_helperListPhysicalDrives
%     for a full test suite.
%
% References
%   Mac : https://ss64.com/osx/diskutil.html
%   PC  : https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-logicaldisk
%
% This version of the function was written on 2025_12_03 by S. Brennan
% Original version written by Eivind Hennestad on 2022_11_24
% Questions or comments? sbrennan@psu.edu


% REVISION HISTORY:
%
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of ParseData demo

% TO-DO:
%
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% Todo (copied from Eivind's to-do)
% [ ] Implement for linux systems
% [ ] Add internal, external (how to get this on pc?)
% [ ] On mac, file system is not correct...
% [ ] On mac, don't show hidden partitions?
% [ ] On windows, is the serial number complete?
% [ ] On mac, add serial number
% [ ] On mac, parse result when using -plist instead?
% [ ] On windows, use 'where drivetype=3' i.e 'wmic logicaldisk where drivetype=3 get ...'



%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 1; % The largest Number of argument inputs to the function
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
        narginchk(0,MAX_NARGIN);

        % % Check the input_path to be sure it has 2 or 3 columns, minimum 2 rows
        % % or more
        % fcn_DebugTools_checkInputsToFunctions(input_path, '2or3column_of_numbers',[2 3]);
    end
end

%
%
% % Set the start values
% [flag_start_is_a_point_type, start_zone_definition] = fcn_Laps_checkZoneType(start_zone_definition, 'start_definition', -1);
%
%
% % The following area checks for variable argument inputs (varargin)
%
% % Does the user want to specify the end_definition?
% % Set defaults first:
% end_zone_definition = start_zone_definition; % Default case
% flag_end_is_a_point_type = flag_start_is_a_point_type; % Inheret the start case
% % Check for user input
% if 3 <= nargin
%     temp = varargin{1};
%     if ~isempty(temp)
%         % Set the end values
%         [flag_end_is_a_point_type, end_zone_definition] = fcn_Laps_checkZoneType(temp, 'end_definition', -1);
%     end
% end
%
% % Does the user want to specify excursion_definition?
% flag_use_excursion_definition = 0; % Default case
% flag_excursion_is_a_point_type = 1; % Default case
% if 4 <= nargin
%     temp = varargin{2};
%     if ~isempty(temp)
%         % Set the excursion values
%         [flag_excursion_is_a_point_type, excursion_definition] = fcn_Laps_checkZoneType(temp, 'excursion_definition',-1);
%         flag_use_excursion_definition = 1;
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

if ismac
    warning('This code is not yet tested on MacOS. Errors are likely.');
    [~, infoStr] = system('diskutil list physical');
    infoTable = fcn_INTERNAL_convertListToTableMac(infoStr);
elseif ispc
    [~, infoStr] = system(['wmic logicaldisk get DeviceId, ', ...
        'VolumeName, VolumeSerialNumber, FileSystem, Size, ', ...
        'DriveType' ] );
    infoTable = fcn_INTERNAL_convertListToTablePc(infoStr);
elseif isunix
    error('Not implemented for unix systems')
end
infoTable = fcn_INTERNAL_postprocessTable(infoTable);


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

    disp(infoTable)

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

%% fcn_INTERNAL_convertListToTableMac
function infoTable = fcn_INTERNAL_convertListToTableMac(infoStr)
%fcn_INTERNAL_convertListToTableMac Split string containing list of drive info into a table
%
%   Ad hoc conversion of string into table.
% Remove some random(?) unicode symbols
infoStr = strrep(infoStr, char(8296), ' ');
infoStr = strrep(infoStr, char(8297), ' ');
infoStr = strrep(infoStr, '*', ' ');
infostrCell = fcn_INTERNAL_splitStringIntoRows(infoStr);
rowIdxRemove = strncmp(infostrCell, '/dev', 4);

% Keep track of rows belonging to same drive / device
deviceNumber = cumsum(rowIdxRemove);
deviceHeaders = infostrCell(rowIdxRemove);
infostrCell(rowIdxRemove) = [];  % Remove title rows
deviceNumber(rowIdxRemove) = [];
% Use first header row to find index locations for splitting each row
% into cells. Find indices where columns start and stop:
colStart = regexp(infostrCell{1}, '(?<= )\S{1}', 'start'); % Space before char
colStop = regexp(infostrCell{1}, '\S{1}(?= )', 'start'); % Space after char
% Columns 1-2 are right aligned, columns 3-5 are left-aligned
colStart = [1, colStop(1:2)+1, colStart(3:4)];
rowIdxRemove = strncmp(infostrCell, '#', 1);
infostrCell(rowIdxRemove) = [];  % Remove header rows before splitting
deviceNumber(rowIdxRemove) = [];
C = fcn_INTERNAL_splitRowsIntoColumns(infostrCell, colStart);
% Remove first column.
C(:, 1) = [];
% Split columns with disk size into size and unit
colIdx = size(C, 2) + 1;
for i = 2:size(C, 1)
    C(i, [3,colIdx]) = strsplit(C{i, 3}, ' ');
end

% Get the drive type
expression = '\((.*)\)';
driveType = regexp(deviceHeaders, expression, 'tokens');
driveTypeColumnData = arrayfun(@(x) driveType{x}{1}{1}, deviceNumber, 'uni', 0);

colIdx = size(C, 2) + 1;
C(:, colIdx) = driveTypeColumnData;
% Set varible names and create table
variableNames = {'FileSystem', 'VolumeName', 'Size', 'DeviceID', 'SizeUnit', 'DriveType'};
infoTable = cell2table(C(2:end,:), 'VariableNames', variableNames);
% Convert some variables into numbers
infoTable.Size = str2double( infoTable.Size );
% Todo: Find serial number
serialNumber = repmat(missing, size(C, 1)-1, 1);
infoTable = addvars(infoTable, serialNumber, 'NewVariableNames', 'SerialNumber');
end % Ends fcn_INTERNAL_convertListToTableMac



%% fcn_INTERNAL_convertListToTablePc
function infoTable = fcn_INTERNAL_convertListToTablePc(infoStr)
infostrCell = fcn_INTERNAL_splitStringIntoRows(infoStr);
% Detect indices where rows should be split
colStart = regexp(infostrCell{1}, '(?<=\ )\S{1}', 'start');
colStart = [1, colStart];
C = fcn_INTERNAL_splitRowsIntoColumns(infostrCell, colStart);
%C{1,6} = 'SerialNumber'; % Shorten name
C = strrep(C, 'VolumeSerialNumber', 'SerialNumber');
infoTable = cell2table(C(2:end,:), 'VariableNames',C(1,:));
% Compute size and add unit
infoTable.Size = str2double( infoTable.Size );
power = floor(log10(infoTable.Size)/3)*3;
infoTable.Size = infoTable.Size ./ 10.^(power);
sizeUnit = categorical(power, [3, 6, 9, 12], {'kB', 'MB', 'GB', 'TB'});
infoTable = addvars(infoTable, sizeUnit, 'NewVariableNames', 'SizeUnit');

infoTable.DriveType = fcn_INTERNAL_labelDriveTypePC(infoTable.DriveType);
end % Ends fcn_INTERNAL_convertListToTablePc

%% fcn_INTERNAL_splitStringIntoRows
function infoStrCell = fcn_INTERNAL_splitStringIntoRows(infoStr)

% Split string into rows
infoStrCell = textscan( infoStr, '%s', 'delimiter', '\n' );
infoStrCell = infoStrCell{1};
% Remove empty cells
infoStrCell = fcn_INTERNAL_removeEmptyCells(infoStrCell);
end % Ends fcn_INTERNAL_splitStringIntoRows

%% fcn_INTERNAL_splitRowsIntoColumns
function C = fcn_INTERNAL_splitRowsIntoColumns(infostrCell, splitIdx)

numRows = numel(infostrCell);
numColumns = numel(splitIdx);
strLength = max( cellfun(@(c) numel(c), infostrCell) );
% Make sure all rows are the same length
infostrCell = cellfun(@(str) pad(str, strLength), infostrCell, 'uni', 0);
% Add length of row to split index (Add 1, see below)
splitIdx = [splitIdx, strLength+1];
C = cell(numRows, numColumns);
for i = 1:numColumns
    colIdx = splitIdx(i) : splitIdx(i+1)-1;
    C(:, i) = cellfun(@(str) str(colIdx), infostrCell, 'uni', 0);
end

C = strtrim(C); % Remove trailing whitespace from all cells
end % Ends fcn_INTERNAL_splitRowsIntoColumns

%% fcn_INTERNAL_labelDriveTypePC
function driveType = fcn_INTERNAL_labelDriveTypePC(driveType)

%     0	Unknown
%     1	No Root Directory
%     2	Removable Disk
%     3	Local Disk
%     4	Network Drive
%     5	Compact Disc
%     6	RAM Disk
driveType = categorical(driveType, {'0','1','2','3','4','5','6'}, ...
    {'Unknown', 'No Root Directory', 'Removable Disk', 'Local Disk', ...
    'Network Drive', 'Compact Disc', 'RAM Disk'});
end % Ends fcn_INTERNAL_labelDriveTypePC

%% fcn_INTERNAL_postprocessTable
function infoTable = fcn_INTERNAL_postprocessTable(infoTable)
% Convert the rest of the variables into strings
infoTable.FileSystem = string(infoTable.FileSystem);
infoTable.VolumeName = string(infoTable.VolumeName);
infoTable.SizeUnit = categorical(infoTable.SizeUnit);
infoTable.DeviceID = string(infoTable.DeviceID);
infoTable.SerialNumber = string(infoTable.SerialNumber);
infoTable.DriveType = string(infoTable.DriveType);
% Reorder variables into standard order
variableOrder = {'DeviceID', 'VolumeName', 'SerialNumber', ...
    'FileSystem', 'Size', 'SizeUnit', 'DriveType'};
infoTable = infoTable(:, variableOrder);
% Add row names
infoTable.Properties.RowNames = arrayfun(@num2str, 1:size(infoTable,1), 'uni', 0)';
end % Ends fcn_INTERNAL_postprocessTable


%% fcn_INTERNAL_getWindowsTestStr
% Windows test:
function infoStr = fcn_INTERNAL_getWindowsTestStr() %#ok<DEFNU>
infoStr = sprintf(['DeviceID  FileSystem  Size           VolumeName                 VolumeSerialNumber\n', ...
    'C:        NTFS        487263825920   Windows                    362B9C03            \n', ...
    'D:        NTFS        23300403200    Recovery Image             8C270C51            \n', ...
    'E:        NTFS        4000768323584  Data                       A029F36B            \n', ...
    'F:        exFAT       5000669429760  One Touch                  5FD3B355            \n', ...
    'H:        exFAT       5000669429760  One Touch                  5FD3B355            \n', ...
    'I:        NTFS        5000845586432  Seagate Backup Plus Drive  C45AD2BE            \n', ...
    '\n', ...
    '\n']);
end % Ends fcn_INTERNAL_getWindowsTestStr

%% fcn_INTERNAL_removeEmptyCells
function cellArray = fcn_INTERNAL_removeEmptyCells(cellArray)
isEmptyCell = cellfun(@isempty, cellArray);
cellArray( isEmptyCell ) = [];
end % Ends fcn_INTERNAL_removeEmptyCells

% % % function filename = filewrite(filename, textString)
% % %
% % %     if isempty(filename)
% % %         filename = [tempname, '.txt'];
% % %     end
% % %
% % %     fid = fopen(filename, 'w');
% % %     fwrite(fid, textString);
% % %     fclose(fid);
% % % end
% % %
% % %         [~, infoStr] = system('diskutil list -plist physical');
% % %
% % %         filename = [tempname, '.xml'];
% % %         filename = filewrite(filename, infoStr);
% % %
% % %         convertedValue = readstruct(filename);
