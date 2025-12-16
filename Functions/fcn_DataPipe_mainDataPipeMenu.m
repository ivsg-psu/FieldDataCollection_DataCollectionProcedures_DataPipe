function fcn_DataPipe_mainDataPipeMenu(varargin)
%% fcn_DataPipe_mainDataPipeMenu
% Main menu for the data pipe operations
%
% FORMAT:
%
%      fcn_DataPipe_mainDataPipeMenu(thisSourceFolderName, thisDestinationFolder, (figNum));
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
%      (none)
%
% DEPENDENCIES:
%
%     fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataPipe_mainDataPipeMenu
%     for a full test suite.
%
% This version of the function was written on 2025_12_16 by S. Brennan
% Questions or comments? sbrennan@psu.edu


% REVISION HISTORY:
%
% 2025_12_16 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of DataPipe demo

% TO-DO:
%
% 2025_12_16 by Sean Brennan, sbrennan@psu.edu
% (fill in items here)

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

        % Check the directorySourceRawBags to be sure it is an existing
        % directory
        fcn_DebugTools_checkInputsToFunctions(thisSourceFullFolderName, 'DoesDirectoryExist');

        % % Check the directoryDestinationParsedBags_PoseOnly to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(thisDestinationFolder, 'DoesDirectoryExist');

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
figNum = [];
if (0==flag_max_speed) && (MAX_NARGIN == nargin)
    temp = varargin{end};
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp; 
        flag_do_plots = 1;
    end
end
if isempty(figNum)
    h_fig = figure;
    figNum = h_fig.Number;
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


%% Set computer info
% This includes default directories, disk locations, etc

% Get disks to use
clear computerInfo
computerInfo = struct;
infoTable = fcn_DataPipe_helperListPhysicalDrives((-1));

% Fill default drive information, and save available drives
[computerInfo.rootSourceDrive, ~, allDriveLetters, allDriveNames] ...
    = fcn_DataPipe_helperFillDefaultDrives([], (infoTable),(-1));
[computerInfo.rootDestinationDrive, ~, ~, ~] ...
    = fcn_DataPipe_helperFillDefaultDrives([], (infoTable),(-1));
computerIDdoingParsing = string(java.net.InetAddress.getLocalHost().getHostName());
computerInfo.computerIDdoingParsing = computerIDdoingParsing;
% COMMON RESULTS:
% computerIDdoingParsing: "E5-ME-L-SEBR12" for Brennan's laptop

[bytesPerSecondPoseOnly, bytesPerSecondFull, bytesPerSecondFullWithCameras]  = fcn_DataPipe_helperSetDefaultParsingSpeeds((computerIDdoingParsing), (-1));

% Set default folders to use
computerInfo.directoryUnsortedBags   = cat(2,computerInfo.rootSourceDrive,     '\ReadyToParse');
% computerInfo.directoryTempStaging    = cat(2,computerInfo.rootSourceDrive,     '\TempZip');
computerInfo.directoryTempStaging    = 'C:\TempZip';


%% Set menu choices
allMenuOptions = cell(1,1);
allMenuPrompts = cell(1,1);
allMenuOptions{1,1} = 'd';
allMenuPrompts{1,1} = 'd: (D)rive selection for source, destination, and unstaged drives.';
allMenuOptions{end+1,1} = 'c';
allMenuPrompts{end+1,1} = 'c: (C)heck if bag files were already staged.';
allMenuOptions{end+1,1} = 's';
allMenuPrompts{end+1,1} = 's: (S)tage an unsorted bag file directory for copying into RawBags.';
allMenuOptions{end+1,1} = 'm';
allMenuPrompts{end+1,1} = 'm: (M)easure parsing speed on this computer.';
allMenuOptions{end+1,1} = 'p';
allMenuPrompts{end+1,1} = 'p: (P)arse bag files.';
allMenuOptions{end+1,1} = 'z';
allMenuPrompts{end+1,1} = 'z: (Z)ip hash subdirectories in Parsed.';
allMenuOptions{end+1,1} = 'u';
allMenuPrompts{end+1,1} = 'u: (U)nzip hash subdirectories in Parsed.';
allMenuOptions{end+1,1} = 'g';
allMenuPrompts{end+1,1} = 'g: (G)enerate MAT files from pose-only data.';
allMenuOptions{end+1,1} = 'v';
allMenuPrompts{end+1,1} = 'v: (V)isualize MAT files by plotting and saving images.';
allMenuOptions{end+1,1} = 'e';
allMenuPrompts{end+1,1} = 'e: m(E)rge MAT files by combining data in sequence.';
allMenuOptions{end+1,1} = 'q';
allMenuPrompts{end+1,1} = 'q: (Q)uit.';
allMenuOptions{end+1,1} = 'h';
allMenuPrompts{end+1,1} = 'h: (H)elp.';

%% What type of parsing are we going to do?

% Set default choice
parsingChoice = 'h';

% Initialize count of bad inputs and loop flag
numBadInputs = 0;
flag_exitMain = 0;
while 0==flag_exitMain
    clc;

    % Set default MappingVanData directories (changes each time rootSourceDrive
    % and rootDestinationDrive changes)
    computerInfo.rootSourceDriveName = fcn_INTERNAL_setDriveName(computerInfo.rootSourceDrive,allDriveLetters, allDriveNames);
    computerInfo.rootDestinationDriveName = fcn_INTERNAL_setDriveName(computerInfo.rootDestinationDrive, allDriveLetters, allDriveNames);

    computerInfo = fcn_INTERNAL_setDefaultMappingVanDataDirectories(computerInfo);

    computerInfo = fcn_INTERNAL_checkAndPrintDiretories(computerInfo);
    
    allowableOptions = fcn_INTERNAL_setAllowableMenuOptions(computerInfo, allMenuOptions);

    fprintf(1,'\nWhat parsing step do you want to do now?\n')
    fcn_INTERNAL_printMenuOptions(allowableOptions, allMenuOptions, allMenuPrompts, parsingChoice)
    
    mainMenuChoice = input('Selection? [default = h]:','s');
    if isempty(mainMenuChoice)
        mainMenuChoice = 'h';
    end

    fprintf(1,'Selection chosen: -->  %s\n',mainMenuChoice);

    if ~any(strcmpi(mainMenuChoice,allowableOptions))
        mainMenuChoice = '';
    end

    % Fill in filesToKeep, processType, and processName based on selection
    switch lower(mainMenuChoice)
        case 'd'
            [computerInfo.rootSourceDrive, computerInfo.rootDestinationDrive, computerInfo.directoryUnsortedBags, computerInfo.directoryTempStaging] = ...
                fcn_INTERNAL_setSourceDestinationDrives(computerInfo.rootSourceDrive, computerInfo.rootDestinationDrive, computerInfo.directoryUnsortedBags, computerInfo.directoryTempStaging);

        case 'c'
            fcn_DataPipe_parsingCheckIfFilesStaged(computerInfo.directoryUnsortedBags, computerInfo.directoryDestinationRawBags, -1);
            fprintf(1,'(hit any key to continue...)\n');
            pause;

        case 's'
            fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy(computerInfo.directoryUnsortedBags, computerInfo.directoryTempStaging)
            fprintf(1,'You must manually copy the directory into the destination. This is to force the user to check results before continuing.\n');
            fprintf(1,'Hit any key to continue.\n');
            pause;

        case 'm'
            fcn_DataPipe_parsingMeasureParsingSpeed(computerInfo.rootSourceDrive, computerInfo.directoryTempStaging);
            fprintf(1,'Hit any key to continue.\n');
            pause;

        case 'p'
            warning('This function needs to be tested, and its test script needs to be done also');
            fcn_DataPipe_parsingParseBagsInRawBags(...
                computerInfo.directorySourceRawBags, ...
                computerInfo.directoryDestinationParsedBags_PoseOnly, ...
                computerInfo.directoryDestinationParsedBags, ....
                bytesPerSecondPoseOnly, bytesPerSecondFull)

        case 'z'
            oneStepCommand = 'zip hash files';
            sourceMainSubdirectory = 'ParsedBags';
            destinationMainSubdirectory = 'ParsedBags';
            defaultSourceDirectory = computerInfo.directorySourceParsedBags;
            sourceDescription = 'hash tables, or hash tables within its subdirectories';
            stringSourceQuery = 'hash';
            flag_sourceIsFileOrDirectory = 1; % 0-->file, 1--> directory
            defaultDestinationDirectory = computerInfo.directoryTempStaging;
            destinationDescription = 'temporary zip files during the process. These files may be up to 20GB.';
            stringDestinationFileExtension = '.mat';
            flag_destinationIsFileOrDirectory = 0; % 0-->file, 1--> directory
            avePerStepProcessingSpeed = 150;
            flagUseDirectoryNameInDestination = 0;

            fcn_INTERNAL_menuWrappedAroundOneTransfer(...
                oneStepCommand,...
                sourceMainSubdirectory, ...
                destinationMainSubdirectory, ...
                defaultSourceDirectory, ...
                sourceDescription,...
                stringSourceQuery, ...
                flag_sourceIsFileOrDirectory,...
                defaultDestinationDirectory,...
                destinationDescription,...
                stringDestinationFileExtension,...
                flag_destinationIsFileOrDirectory,...
                avePerStepProcessingSpeed, ...
                flagUseDirectoryNameInDestination);

        case 'u'
            oneStepCommand = 'unzip hash files';
            sourceMainSubdirectory = 'ParsedBags';
            destinationMainSubdirectory = 'ParsedBags';
            defaultSourceDirectory = computerInfo.directorySourceParsedBags;
            sourceDescription = 'zipped hash tables, or zipped hash tables within its subdirectories';
            stringSourceQuery = 'hash';
            flag_sourceIsFileOrDirectory = 1; % 0-->file, 1--> directory
            defaultDestinationDirectory = computerInfo.directoryTempStaging;
            destinationDescription = 'temporary unzip files during the process. These files may be up to 20GB.';
            stringDestinationFileExtension = '.mat';
            flag_destinationIsFileOrDirectory = 0; % 0-->file, 1--> directory
            avePerStepProcessingSpeed = 150;
            flagUseDirectoryNameInDestination = 0;

            fcn_INTERNAL_menuWrappedAroundOneTransfer(...
                oneStepCommand,...
                sourceMainSubdirectory, ...
                destinationMainSubdirectory, ...
                defaultSourceDirectory, ...
                sourceDescription,...
                stringSourceQuery, ...
                flag_sourceIsFileOrDirectory,...
                defaultDestinationDirectory,...
                destinationDescription,...
                stringDestinationFileExtension,...
                flag_destinationIsFileOrDirectory,...
                avePerStepProcessingSpeed, ...
                flagUseDirectoryNameInDestination);

        case 'g'
            oneStepCommand = 'create MAT files';
            sourceMainSubdirectory = 'ParsedBags_PoseOnly';
            destinationMainSubdirectory = cat(2,'ParsedMATLAB_PoseOnly',filesep,'RawData');
            defaultSourceDirectory = computerInfo.directorySourceParsedBags_PoseOnly;
            sourceDescription = 'bagfile parsed data';
            stringSourceQuery = 'mapping_van_*';
            flag_sourceIsFileOrDirectory = 1; % 0-->file, 1--> directory
            defaultDestinationDirectory = computerInfo.directoryDestinationParsedMATLAB_PoseOnlyRawData;
            destinationDescription = '';
            stringDestinationFileExtension = '.mat';
            flag_destinationIsFileOrDirectory = 0; % 0-->file, 1--> directory
            avePerStepProcessingSpeed = 0.5;
            flagUseDirectoryNameInDestination = 0;

            fcn_INTERNAL_menuWrappedAroundOneTransfer(...
                oneStepCommand,...
                sourceMainSubdirectory, ...
                destinationMainSubdirectory, ...
                defaultSourceDirectory, ...
                sourceDescription,...
                stringSourceQuery, ...
                flag_sourceIsFileOrDirectory,...
                defaultDestinationDirectory,...
                destinationDescription,...
                stringDestinationFileExtension,...
                flag_destinationIsFileOrDirectory,...
                avePerStepProcessingSpeed, ...
                flagUseDirectoryNameInDestination);

        case 'v'
            oneStepCommand = 'create FIG and PNG files';
            sourceMainSubdirectory = cat(2,'ParsedMATLAB_PoseOnly',filesep,'RawData');
            destinationMainSubdirectory = cat(2,'ParsedMATLAB_PoseOnly',filesep,'RawData');
            defaultSourceDirectory = computerInfo.directorySourceParsedMATLAB_PoseOnlyRawData;
            sourceDescription = 'mat files';
            stringSourceQuery = '*.'; %'*.mat';
            flag_sourceIsFileOrDirectory = 1; %0; % 0-->file, 1--> directory
            defaultDestinationDirectory = computerInfo.directoryDestinationParsedMATLAB_PoseOnlyRawData;
            destinationDescription = '';
            stringDestinationFileExtension = '.fig';
            flag_destinationIsFileOrDirectory = 0; % 0-->file, 1--> directory
            avePerStepProcessingSpeed = 3.5;
            flagUseDirectoryNameInDestination = 1;

            fcn_INTERNAL_menuWrappedAroundOneTransfer(...
                oneStepCommand,...
                sourceMainSubdirectory, ...
                destinationMainSubdirectory, ...
                defaultSourceDirectory, ...
                sourceDescription,...
                stringSourceQuery, ...
                flag_sourceIsFileOrDirectory,...
                defaultDestinationDirectory,...
                destinationDescription,...
                stringDestinationFileExtension,...
                flag_destinationIsFileOrDirectory,...
                avePerStepProcessingSpeed, ...
                flagUseDirectoryNameInDestination);
        case 'e'

            oneStepCommand = 'merge MAT files';
            sourceMainSubdirectory = cat(2,'ParsedMATLAB_PoseOnly',filesep,'RawData');
            destinationMainSubdirectory = cat(2,'ParsedMATLAB_PoseOnly',filesep,'Merged_00');
            defaultSourceDirectory = computerInfo.directorySourceParsedMATLAB_PoseOnlyRawData;
            sourceDescription = 'raw mat files';
            stringSourceQuery = '*.'; %'*.mat';
            flag_sourceIsFileOrDirectory = 1; %0; % 0-->file, 1--> directory
            defaultDestinationDirectory = computerInfo.directoryDestinationParsedMATLAB_PoseOnlyRawDataMerged;
            destinationDescription = '';
            stringDestinationFileExtension = '.mat';
            flag_destinationIsFileOrDirectory = 0; % 0-->file, 1--> directory
            avePerStepProcessingSpeed = 10;
            flagUseDirectoryNameInDestination = [];

            fcn_INTERNAL_menuWrappedAroundOneTransfer(...
                oneStepCommand,...
                sourceMainSubdirectory, ...
                destinationMainSubdirectory, ...
                defaultSourceDirectory, ...
                sourceDescription,...
                stringSourceQuery, ...
                flag_sourceIsFileOrDirectory,...
                defaultDestinationDirectory,...
                destinationDescription,...
                stringDestinationFileExtension,...
                flag_destinationIsFileOrDirectory,...
                avePerStepProcessingSpeed, ...
                flagUseDirectoryNameInDestination);
           
        case 'q'
            flag_exitMain = 1;
            fprintf(1,'Quitting\n');

        case 'h'
            fcn_INTERNAL_showHelp;

        otherwise
            numBadInputs = numBadInputs + 1;
            if numBadInputs>3
                fprintf(1,'Too many failed inputs: %.0f of 3 allowed. Exiting.\n',numBadInputs);
                flag_exitMain = 1;
            else
                fprintf(1,'Unrecognized or unallowed option: %s. Try again (try %.0f of 3) \n ', parseType, numBadInputs);
            end

    end
end % Ends while loop for menu



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

%% fcn_INTERNAL_confirmSourceDestinationDrives
function [flag_keepGoing, driveRoot] = fcn_INTERNAL_confirmSourceDestinationDrives(stringInputOutput, defaultDriveRoot, infoTable)

% Check defaults
[~, diskNumber, ~, allDriveNames] = fcn_DataPipe_helperFillDefaultDrives(defaultDriveRoot, (infoTable),(-1));
if isempty(diskNumber)
    diskNumber = nan;
end

goodDisks = fcn_INTERNAL_findNonEmptyDrives(infoTable);
NgoodDisks = length(goodDisks);

flag_keepGoing = 1; % Flag to exit permanently
flag_goodInput = 0; % Flag to stay in while loop
while 0==flag_goodInput
    numBadInputs = 0;
    fprintf(1,'\n\nSelect from the following drive options for the %s:\n', stringInputOutput);
    % diskStrings = fcn_INTERNAL_showDiskList(infoTable, goodDisks, allDriveNames);

    fprintf(1,'\nWhat disk to use for %s?\n', stringInputOutput)
    if isempty(goodDisks)
        fprintf(1,'(no disks found!)\n');
    else
        for ith_disk = 1:NgoodDisks
            fprintf(1,'\t%.0d: Select drive %s ',ith_disk, allDriveNames{ith_disk});
            if ith_disk==diskNumber
                fprintf(1,'<---- (selected) \n');
            else
                fprintf(1,'\n');
            end
        end
        if ismember(diskNumber,(1:NgoodDisks))
            fprintf(1,'\ta: (A)ccept selection.\n')
        end
    end
    fprintf(1,'\tr: (R)escan for drives (default).\n')
    fprintf(1,'\tq: (Q)uit.\n')
    diskChoice = input('Selection? [default = r]:','s');
    if isempty(diskChoice)
        diskChoice = 'r';
    end

    fprintf(1,'Selection chosen: --> %s \n ',diskChoice);

    if isscalar(diskChoice) && ismember(str2double(diskChoice),(1:NgoodDisks))
        % Good choice
        diskNumber = str2double(diskChoice);
    elseif strcmpi(diskChoice,'a') && ~isempty(goodDisks)
        % Accept
        flag_goodInput = 1;

    elseif strcmpi(diskChoice,'r')
        % Rescan
        infoTable = fcn_DataPipe_helperListPhysicalDrives;
        isNotEmpty  = ~isnan(infoTable.Size);
        serialNumbers = char(infoTable.SerialNumber(:));
        % Empty volume names have all spaces in their name. So we check to
        % see if the serialNumber rows are all spaces along their columns
        notEmptyName = ~all(serialNumbers == ' ',2);
        goodDisks = find((isNotEmpty.*notEmptyName)==1);
        diskChoice = nan;
        NgoodDisks = length(goodDisks);

    elseif strcmpi(diskChoice, 'q')
        diskChoice = nan;
        flag_goodInput = 1;
        flag_keepGoing = 0;
        fprintf(1,'Quitting\n');
    else
        numBadInputs = numBadInputs + 1;
        if numBadInputs>3
            fprintf(1,'Too many failed inputs: %.0f of 3 allowed. Exiting.\n',numBadInputs, diskChoice);
            flag_goodInput = 1;
            flag_keepGoing = 0;
        else
            fprintf(1,'Unrecognized option: %s. Try again (try %.0f of 3) \n ', diskChoice, numBadInputs);
        end

    end

end

% Fill in data
driveRoot = nan;
if ~isnan(diskChoice)
    rowNumber = goodDisks(diskNumber);
    driveRoot = char(infoTable(rowNumber,:).DeviceID);
end

end % Ends fcn_INTERNAL_confirmSourceDestinationDrives


% %% fcn_INTERNAL_showDiskList
% function diskStrings = fcn_INTERNAL_showDiskList(infoTable, goodDisks, allDriveNames) %#ok<INUSD>
% diskStrings = cell(length(goodDisks),1);
% if ~isempty(goodDisks)
% 
%     for ith_disk = 1:length(goodDisks)
%         diskToScan = goodDisks(ith_disk);
%         deviceID = infoTable(diskToScan,:).DeviceID;
%         volumeName = infoTable(diskToScan,:).VolumeName;
%         FileSystem = infoTable(diskToScan,:).FileSystem;
%         if ~strcmp(volumeName,"")
%             thisDiskString = sprintf('%s (%s, %s)',deviceID, volumeName, FileSystem);
%         else
%             thisDiskString = sprintf('%s (-unnamed- %s) %s',deviceID, FileSystem, temp);
%         end
%         diskStrings{ith_disk} = thisDiskString;
%     end
% end
% 
% end % Ends fcn_INTERNAL_showDiskList

%% fcn_INTERNAL_showSelection
function fcn_INTERNAL_showSelection(parsingChoice,thisChoice)
if strcmp(parsingChoice,thisChoice)
    fprintf(1,'SELECTED--->');
else
    fprintf(1,'            ');
end
end % Ends fcn_INTERNAL_showSelection


%% fcn_INTERNAL_setSourceDestinationDrives
function [sourceDrive, destinationDrive, directoryUnsortedBags, directoryTempStaging] = fcn_INTERNAL_setSourceDestinationDrives(defaultSourceDrive, defaultDestinationDrive, defaultDirectoryUnsortedBags, defaultDirectoryTempZip)
% Determine the source and destination drives
infoTable = fcn_DataPipe_helperListPhysicalDrives;

[flag_keepGoing, sourceDrive] = fcn_INTERNAL_confirmSourceDestinationDrives('Source drive',defaultSourceDrive, infoTable);
if 1==flag_keepGoing
    [~, destinationDrive] = fcn_INTERNAL_confirmSourceDestinationDrives('Destination drive',defaultDestinationDrive, infoTable);
else
    sourceDrive = defaultSourceDrive;
    destinationDrive = defaultDestinationDrive;
end

% Set the directory for unsorted files
directoryUnsortedBags = fcn_INTERNAL_getUserDirectoryChoice(defaultDirectoryUnsortedBags,' for the unstaged bag files');

% Set the directory for zip file processing
directoryTempStaging = fcn_INTERNAL_getUserDirectoryChoice(defaultDirectoryTempZip,' for storing intermediate zip files');


end % Ends fcn_INTERNAL_setSourceDestinationDrives

%% fcn_INTERNAL_menuWrappedAroundOneTransfer
function fcn_INTERNAL_menuWrappedAroundOneTransfer( ...
    oneStepCommand,...
    sourceMainSubdirectory, destinationMainSubdirectory, ...
    defaultSourceDirectory, sourceDescription, stringSourceQuery, flag_sourceIsFileOrDirectory,  ...
    defaultDestinationDirectory, destinationDescription, stringDestinationFileExtension, flag_destinationIsFileOrDirectory,  ...
    avePerStepProcessingSpeed, flagUseDirectoryNameInDestination) %#ok<INUSD>

% This is a helper function that wraps a menu system around one processing
% operation, calling different operations depending on the oneStepCommand
% string. It has 3 parts:
% 1. Verification of the directories for source and destination
% 2. Query of the source directory to find all possible sources, and then
% using these to find all possible destination files/folders, tagging each
% either as existing or not existing.
% 3. Showing user a menu that allows selection of the indices to process
% 4. Implementing a for-loop among the indices to call one transfer
% operation for each index.

% TO FIX: Use structures to define source and destination information
% sourceInfo.stringSourceDescription = sourceDescription; % Queries the user with "Selecte a source folder containing XXXX" - only queries if description is NOT empty
% sourceInfo.sourceMainSubdirectory
% sourceInfo.stringSourceQuery = stringSourceQuery; % Defines the type of query to perform to search for directories and files.



%% Step 1: Confirm the source and destination folders to use
% Confirm the source? Only do this if the user gives a description
sourceRootOrSubroot = defaultSourceDirectory; % Set default value
if ~isempty(sourceDescription)
     sourceRootOrSubroot = uigetdir(defaultSourceDirectory, sprintf('Select a source folder containing %s', sourceDescription));
    % If the user hits cancel, it returns 0
    if 0==sourceRootOrSubroot
        return;
    end
end

% Confirm the destination? Only do this if the user gives a description
destinationRootOrSubroot = defaultDestinationDirectory; % Set default value
if ~isempty(destinationDescription)
    destinationRootOrSubroot = uigetdir(defaultDestinationDirectory, sprintf('Select a source folder containing %s', destinationDescription));
    % If the user hits cancel, it returns 0
    if 0==destinationRootOrSubroot
        return;
    end
end

% Make sure folders exist!
fcn_DataPipe_helperConfirmDirectoryExists(sourceRootOrSubroot, (1), (-1));
fcn_DataPipe_helperConfirmDirectoryExists(destinationRootOrSubroot, (1), (-1));

%% Step 2: Query which of the sources were already processed into the destinations
if ~strcmp(stringSourceQuery,'hash')
    directoryListing_allSources = fcn_DebugTools_listDirectoryContents(...
        {sourceRootOrSubroot}, stringSourceQuery, (flag_sourceIsFileOrDirectory), (-1));

    % Summarize results
    fprintf(1,['\n\nFound %.0f source data folders/files in the following \n ' ...
        'data folder (and its subfolders): \n\t%s\n'],length(directoryListing_allSources), sourceRootOrSubroot);
else

    directory_allVelodyneHashes = fcn_DebugTools_listDirectoryContents(...
        {sourceRootOrSubroot}, 'hashVelodyne_*', (flag_sourceIsFileOrDirectory), (-1));
    directory_allCamerasHashes = fcn_DebugTools_listDirectoryContents(...
        {sourceRootOrSubroot}, 'hashCameras_*', (flag_sourceIsFileOrDirectory), (-1));
    directory_allOusterO1Hashes = fcn_DebugTools_listDirectoryContents(...
        {sourceRootOrSubroot}, 'hashOusterO1_*', (flag_sourceIsFileOrDirectory), (-1));
   
    directoryListing_allSources = [directory_allVelodyneHashes; directory_allCamerasHashes; directory_allOusterO1Hashes];

    fprintf(1,'\n\nFound %.0f hash folders in the parsed data folder: %s\n',length(directoryListing_allSources), sourceRootOrSubroot);
    fprintf(1,'\t hashVelodyne_ data had: %.0f hashes\n',length(directory_allVelodyneHashes));
    fprintf(1,'\t hashCameras_ data had:  %.0f hashes\n',length(directory_allCamerasHashes));
    fprintf(1,'\t hashOusterO1_ data had: %.0f hashes\n',length(directory_allOusterO1Hashes));

end

if 1==0
    % Print the results?
    fcn_DebugTools_printDirectoryListing(directoryListing_allSources, ([]), ([]), (1));
end

% Extract all the file names for the types of files to process
[sourceDirectoryFullNames, sourceDirectoryShortNames, sourceFileNames, sourceBytes, goodDirectories] = ...
    fcn_INTERNAL_extractFullAndShortNames(directoryListing_allSources, sourceRootOrSubroot, stringSourceQuery);


%%%%%%%%%%%%%%%%%%%%%%
% NEED TO FUNCTIONALIZE THIS SECTION

% Compare the source and destination strings to do replacement. We start by
% copying the poseOnly bag directory names into an "expectedNames" cell
% array:

% Next, find the header that goes in front. To do this, we look for the
% pattern: \MappingVanData\
% in sourceParsedBagRootOrSubroot and extract just that. This is usually
% just a drive letter, but can be a path. We also find the destination
% starter. Again, this can be a drive letter, but can also be a path.

beforePatternToMatch = cat(2,filesep,'MappingVanData',filesep);
sourceStarter      = extractBefore(sourceRootOrSubroot,beforePatternToMatch);
destinationStarter = extractBefore(destinationRootOrSubroot,beforePatternToMatch);

% Now, use the above to define the pattern to replace. It will be 
% (sourceStart) + \ + MappingVanData + \ + (sourceMainSubdirectory) + \ 
patternToReplace = cat(2,sourceStarter,filesep,'MappingVanData',filesep,sourceMainSubdirectory,filesep);

% Define the replacement string. It will be:
% (destinationStart) + \ + MappingVanData + \ + (destinationMainSubdirectory) + \ 
replacementString = cat(2,destinationStarter,filesep,'MappingVanData',filesep,destinationMainSubdirectory, filesep);

destinationDirectories = replace(sourceDirectoryFullNames,patternToReplace,replacementString);
if 1==flag_destinationIsFileOrDirectory
    expectedDestinationFilesHeaderOnly = destinationDirectories;
else
    expectedDestinationFilesHeaderOnly = replace(sourceFileNames,patternToReplace,replacementString);
end


if 0 == flag_destinationIsFileOrDirectory
    % % Should the directory name be duplicated?
    % if 1==flagUseDirectoryNameInDestination
    %     for ith_file = 1:length(expectedDestinationFilesHeaderOnly)
    %         thisName = expectedDestinationFilesHeaderOnly{ith_file};
    %         indexLastFileSep = find(thisName==filesep,1,'last');
    %         folderName    = thisName(indexLastFileSep+1:end);
    %         thisNameModified = cat(2,thisName,filesep,folderName);
    %         expectedDestinationFilesHeaderOnly{ith_file} = thisNameModified;
    %     end
    % end


    % If a file, add the extension
    destinationFiles = strcat(expectedDestinationFilesHeaderOnly,stringDestinationFileExtension);
else
    % If a directory query, then use this
    destinationFiles = expectedDestinationFilesHeaderOnly;
end

%%%%
% Find which files were previously processed
NfilesToCheck =length(destinationFiles);
flags_folderWasPreviouslyProcessed = false(NfilesToCheck,1);
for ith_check = 1:NfilesToCheck

    % Is the flag for a file? (0)  or a directory? (1)
    if 0==flag_destinationIsFileOrDirectory
        if exist(destinationFiles{ith_check},'file')==2
            flags_folderWasPreviouslyProcessed(ith_check) = true;
        end
    elseif 1==flag_destinationIsFileOrDirectory
        if exist(destinationFiles{ith_check},'dir')==7
            flags_folderWasPreviouslyProcessed(ith_check) = true;
        end
    else
        error('Unrecognized option for flag_destinationIsFileOrDirectory');
    end
end
%%%END FUNCTIONALIZE%%%%%%%%%%%%%%%%%%%

if strcmp(oneStepCommand,'zip hash files')
    flags_folderWasPreviouslyProcessed = fcn_DataPipe_zippingCheckIfFolderPreviouslyZipped(sourceDirectoryFullNames);
    goodDirectories = directoryListing_allSources;
elseif strcmp(oneStepCommand,'unzip hash files')
    flags_folderWasPreviouslyProcessed = fcn_DataPipe_zippingCheckIfFolderPreviouslyUnzipped(sourceDirectoryFullNames);
    goodDirectories = directoryListing_allSources;
elseif strcmp(oneStepCommand,'merge MAT files')
    %%%NEED TO FUNCTIONALIZE THIS WITHIN A MERGE FUNCTION%%
    % CHECK WHICH SOURCE FOLDERS ARE MERGABLE

    % Set up variables
    Nmergable = 0;
    clear mergingSourceDirectoryListing
    mergingSourceDirectoryListing(1) = struct;
    mergingFlags_folderWasPreviouslyProcessed = [];

    % Loop through the directory list, looking for mapping files that end
    % with _0 . These will always be the source of the merge files
    for ith_folder = 1:length(goodDirectories)

        % Convert the directory information into a structured folder name
        thisSourceName = goodDirectories(ith_folder).name;
        thisSourcePartialFolder = goodDirectories(ith_folder).folder;
        if strcmp(thisSourceName,'.')
            thisSourceFolderName = thisSourcePartialFolder;
        else
            thisSourceFolderName = cat(2,thisSourcePartialFolder,filesep,thisSourceName);
        end

        % Using the folder name, check to see the "children" of that folder
        % to see what folders are there, to see this is a "mergable" folder
        % * Must contain, directly under, folders called mapping_van_*
        fileQueryString = 'mapping_van_*.';
        directoryQuery = fullfile(thisSourceFolderName,fileQueryString);
        filelist = dir(directoryQuery);
        fileListToCheck = filelist([filelist.isdir]==1);

        % If the list of files is not empty, then these can be merged
        if ~isempty(fileListToCheck)
            % This directory is mergable
            Nmergable = Nmergable+1;

            % Append the directory information into a growing structure
            % array. This is used later to reconstruct names
            if Nmergable == 1
                mergingSourceDirectoryListing = goodDirectories(ith_folder);
            else
                mergingSourceDirectoryListing(Nmergable) = goodDirectories(ith_folder); %#ok<AGROW>
            end

            % Check if this folder was  fully processed
            flag_fullyProcessed = true;
            
            for ith_mappingFile = 1:length(fileListToCheck)
                thisMappingFileName = fileListToCheck(ith_mappingFile).name;

                % Check if the folder ends as expected
                if strcmp(thisMappingFileName(end-1:end),'_0')
                    expectedDestinationFolder = destinationDirectories{ith_folder};
                    expectedDestinationName = cat(2,thisMappingFileName(1:end-2),'_merged.mat');                    
                    fullPath = fullfile(expectedDestinationFolder,expectedDestinationName);
                    if exist(fullPath,'file')~=2
                        flag_fullyProcessed = false;
                    end

                end             
            end

            mergingFlags_folderWasPreviouslyProcessed(Nmergable,1) = flag_fullyProcessed; %#ok<AGROW>
        end
    end

    % Fill in the variables used hereafter, as well as the flags indicating
    % processing
    [sourceDirectoryFullNames, sourceDirectoryShortNames, ~, sourceBytes, goodDirectories] = ...
    fcn_INTERNAL_extractFullAndShortNames(mergingSourceDirectoryListing, sourceRootOrSubroot, stringSourceQuery); 
    flags_folderWasPreviouslyProcessed = mergingFlags_folderWasPreviouslyProcessed;
    destinationDirectories = replace(sourceDirectoryFullNames,patternToReplace,replacementString);

end % Ends if statement for special cases

%% Step 3: Show the choices and get user selection

% Print the results
NcolumnsToPrint = 2;
cellArrayHeaders = cell(NcolumnsToPrint,1);
cellArrayHeaders{1} = 'FOLDER NAME                             ';
cellArrayHeaders{2} = 'ALREADY PROCESSED?';
cellArrayValues = [sourceDirectoryShortNames, fcn_DebugTools_convertBinaryToYesNoStrings(flags_folderWasPreviouslyProcessed)];
fid = 1;
fcn_DebugTools_printNumeredDirectoryList(goodDirectories, cellArrayHeaders, cellArrayValues, (sourceRootOrSubroot), (fid))

% Ask user what numbers of files to process?
[flag_keepGoing, indiciesSelected] = fcn_DebugTools_queryNumberRange(...
    flags_folderWasPreviouslyProcessed, ...
    (' of the folders to convert'), ...
    (1), ...
    (goodDirectories), (1));

%% Step 4: do the loop
% flag_keepGoing
% indiciesSelected
% sourceDirectoryFullNames = 1;
% sourceDirectoryShortNames = 1;
% sourceBytes = 1;
% destinationDirectories = 1;

% Loop through the files
if 1==flag_keepGoing

    Ndone = 0;
    NtoProcess = length(indiciesSelected);
    timeEstimateInSeconds = avePerStepProcessingSpeed*NtoProcess;
    thisAveProcessingSpeed = 0;

    % Show time estimate 
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated', oneStepCommand)

    alltstart = tic;

    % Iterate through each source-->destination process
    for ith_index = 1:NtoProcess

        ith_file = indiciesSelected(ith_index);
        Ndone = Ndone + 1;

        % Define source/destination settings for this instance
        thisSourceFullFolderName  = sourceDirectoryFullNames{ith_file};
        thisSourceBytes           = sourceBytes(ith_file,1); %#ok<NASGU>

        thisSourceShortFolderName = sourceDirectoryShortNames{ith_file};
        thisDestinationFolder     = destinationDirectories{ith_file};
        
        fprintf(1,'\n\nProcessing file or folder: %d (process %d of %d)\n', ith_file, Ndone, NtoProcess);
        fprintf(1,'Starting to %s using sub folder: %s\n',oneStepCommand,thisSourceShortFolderName);
        fprintf(1,'\t Pulling from folder: %s\n',thisSourceFullFolderName);
        fprintf(1,'\t Pushing to folder:   %s\n',thisDestinationFolder)

        tstart = tic;
        
        switch oneStepCommand
            case 'zip hash files'
                fcn_DataPipe_processOneZipOfHashFolders(thisSourceFullFolderName, destinationRootOrSubroot)   
            case 'unzip hash files'
                fcn_DataPipe_processOneUnzipFolder(thisSourceFullFolderName, destinationRootOrSubroot)                  
            case 'create MAT files'
                fcn_DataPipe_processOneMatFile(thisSourceFullFolderName, thisDestinationFolder)
            case 'create FIG and PNG files'
                fcn_DataPipe_processOneFigFile(thisSourceFullFolderName, thisDestinationFolder)
            case 'merge MAT files'
                fcn_DataPipe_processOneMerge(thisSourceFullFolderName, thisDestinationFolder)                
            otherwise
                error('Unrecognized operation found');
        end

        telapsed = toc(tstart); 

        % Update the average estimate for processing speeds
        thisAveProcessingSpeed = thisAveProcessingSpeed + telapsed/NtoProcess;

    end

    alltelapsed = toc(alltstart);

    % Check prediction
    fprintf(1,'\nAverage processing speed per operation: %.2f seconds',thisAveProcessingSpeed);
    fprintf(1,'\nTotal time summary: \n');
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated total', oneStepCommand);
    fcn_INTERNAL_printTimeEstimate(alltelapsed, 'Actual total', oneStepCommand);
    fprintf(1,'Process to %s complete. Check the above messages for errors.\n', oneStepCommand);
    fprintf(1,'Hit any key to continue.\n');
    pause;

end % Ends if flag_keep_going

end % Ends fcn_INTERNAL_menuWrappedAroundOneTransfer

%% fcn_INTERNAL_checkAndPrintDiretories
function computerInfo = fcn_INTERNAL_checkAndPrintDiretories(computerInfo)
% Prints the directory information to the user, flags if the directory
% exists or not, and prints red or green warnings if/if not exists.

if ~isempty(computerInfo.computerIDdoingParsing)
    fprintf(1,'Computer ID doing parsing: %s\n',computerInfo.computerIDdoingParsing);
end

% Print each directory, and list if it was found
computerInfo.flagSourceDriveFound       = fcn_INTERNAL_printDiretories('Source root:', computerInfo.rootSourceDrive, computerInfo.rootSourceDriveName);
computerInfo.flagDestinationDriveFound  = fcn_INTERNAL_printDiretories('Destination root:', computerInfo.rootDestinationDrive, computerInfo.rootDestinationDriveName);
computerInfo.flagSourceUnsortedBagFound = fcn_INTERNAL_printDiretories('Unstaged bag file root:', computerInfo.directoryUnsortedBags, '');
computerInfo.flagDirectoryTempStagingFound   = fcn_INTERNAL_printDiretories('Temporary staging directory:', computerInfo.directoryTempStaging, '');

if strcmpi(computerInfo.rootSourceDrive,computerInfo.rootDestinationDrive)
    fcn_DebugTools_cprintf('*red',  '\n');
    fcn_DebugTools_cprintf('*red','WARNING: USING THE SAME PHYSICAL DRIVE \nFOR SOURCE AND DESTINATION TRANSFERS \nSIGNFICANTLY SLOWS PROCESSING!\n')
end

fprintf(1,'\n');
fprintf(1,'Possible source directories:\n');
allFields = fieldnames(computerInfo);
for ith_field = 1:length(allFields)
    thisField = allFields{ith_field};
    if contains(thisField,'directorySource')
        directoryExists = fcn_INTERNAL_printDiretories('', computerInfo.(thisField), '');
        flagName = cat(2,'flag',upper(thisField(1)),thisField(2:end));
        computerInfo.(flagName) = directoryExists;
    end
end
fprintf(1,'\n');
fprintf(1,'Possible destination directories:\n');
allFields = fieldnames(computerInfo);
for ith_field = 1:length(allFields)
    thisField = allFields{ith_field};
    if contains(thisField,'directoryDestination')
        directoryExists = fcn_INTERNAL_printDiretories('', computerInfo.(thisField), '');
        flagName = cat(2,'flag',upper(thisField(1)),thisField(2:end));
        computerInfo.(flagName) = directoryExists;
    end
end

end % Ends fcn_INTERNAL_checkAndPrintDiretories

%% fcn_INTERNAL_printDiretories
function flagWasFound = fcn_INTERNAL_printDiretories(promptString, directoryString, directoryName)
% Prints the directory details and lists in either red or green if the
% directory is found

fprintf(1,'\t %s %s ',promptString, directoryString)
if ~isempty(directoryName)
    fprintf(1,'named: %s ', directoryName);
end

% Make sure folders exist!
flagDirectoryExists = fcn_DataPipe_helperConfirmDirectoryExists(directoryString, (0), (-1));
if flagDirectoryExists
    fcn_DebugTools_cprintf('*green',  '(exists)\n')
    flagWasFound = true;
else
    fcn_DebugTools_cprintf('*red',  '(not found)\n')
    flagWasFound = false;
end

end % Ends fcn_INTERNAL_printDiretories

%% fcn_INTERNAL_getUserDirectoryChoice
function directoryChoiceOutput = fcn_INTERNAL_getUserDirectoryChoice(directoryDefault, prompt)
% Queries the user to enter a directory. Allows entry of a default choice.
% Returns default if user does not select viable result.

% Identify the source folders to use
resultDirectory = uigetdir(directoryDefault,sprintf('Select the folder to use%s',prompt));
% If the user hits cancel, it returns 0
if 0==resultDirectory
    directoryChoiceOutput = directoryDefault;
else
    directoryChoiceOutput = resultDirectory;
end
end % Ends fcn_INTERNAL_getUserDirectoryChoice

%% fcn_INTERNAL_setAllowableMenuOptions
function allowableOptions = fcn_INTERNAL_setAllowableMenuOptions(computerInfo, allMenuOptions)
  
allowableOptions = cell(1,1);
allowableOptions{1,1} = 'd';
for ith_option = 2:length(allMenuOptions)
    thisOption = allMenuOptions{ith_option};
    switch thisOption
        case 'd'
            % Do nothing - this option is always allowed
        case 'c'
            if computerInfo.flagSourceUnsortedBagFound && computerInfo.flagDirectoryDestinationRawBags
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 's'
            if computerInfo.flagSourceUnsortedBagFound && computerInfo.flagDirectoryTempStagingFound 
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'm'
            if computerInfo.flagSourceDriveFound && computerInfo.flagDirectoryTempStagingFound 
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'p'
            if computerInfo.flagDirectorySourceRawBags && computerInfo.flagDirectoryDestinationParsedBags_PoseOnly && computerInfo.flagDirectoryDestinationParsedBags
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'z'
            if computerInfo.flagDirectorySourceRawBags && computerInfo.flagDirectoryTempStagingFound 
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'u'
            if computerInfo.flagDirectorySourceRawBags && computerInfo.flagDirectoryTempStagingFound 
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'g'
            if computerInfo.flagDirectorySourceParsedBags_PoseOnly && computerInfo.flagDirectoryDestinationParsedMATLAB_PoseOnlyRawData
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'v'
            if computerInfo.flagDirectorySourceParsedMATLAB_PoseOnlyRawData && computerInfo.flagDirectoryDestinationParsedMATLAB_PoseOnlyRawData
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'e'
            if computerInfo.flagDirectorySourceParsedMATLAB_PoseOnlyRawData && computerInfo.flagDirectoryDestinationParsedMATLAB_PoseOnlyRawDataMerged
                allowableOptions{end+1,1} = thisOption; %#ok<AGROW>
            end
        case 'q'
            allowableOptions{end+1,1} = thisOption; %#ok<AGROW>

        case 'h'
            allowableOptions{end+1,1} = thisOption; %#ok<AGROW>

        otherwise
            error('Unrecognized or unallowed option: %s. \n ', thisOption);

    end
end % Ends loop through options

end % Ends fcn_INTERNAL_setAllowableMenuOptions

%% fcn_INTERNAL_setDefaultMappingVanDataDirectories
function computerInfo = fcn_INTERNAL_setDefaultMappingVanDataDirectories(computerInfo)
computerInfo.directorySourceRawBags                                  = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\RawBags');
computerInfo.directorySourceParsedBags_PoseOnly                      = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedBags_PoseOnly');
computerInfo.directorySourceParsedBags                               = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedBags');
computerInfo.directorySourceParsedMATLAB_PoseOnlyRawData             = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedMATLAB_PoseOnly\RawData');
computerInfo.directorySourceParsedMATLAB_PoseOnlyRawDataMerged       = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedMATLAB_PoseOnly\Merged_00');
computerInfo.directorySourceParsedMATLAB_PoseOnlyTimeCleaned         = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedMATLAB_PoseOnly\Merged_01_TimeCleaned');
computerInfo.directorySourceParsedMATLAB_PoseOnlyDataCleaned         = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedMATLAB_PoseOnly\Merged_02_DataCleaned');   
computerInfo.directorySourceParsedMATLAB_PoseOnlyKalmanFiltered      = cat(2,computerInfo.rootSourceDrive,     '\MappingVanData\ParsedMATLAB_PoseOnly\Merged_03_KalmanFiltered');   

computerInfo.directoryDestinationRawBags                             = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\RawBags');
computerInfo.directoryDestinationParsedBags_PoseOnly                 = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedBags_PoseOnly');
computerInfo.directoryDestinationParsedBags                          = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedBags');
computerInfo.directoryDestinationParsedMATLAB_PoseOnlyRawData        = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedMATLAB_PoseOnly\RawData');
computerInfo.directoryDestinationParsedMATLAB_PoseOnlyRawDataMerged  = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_00');
computerInfo.directoryDestinationParsedMATLAB_PoseOnlyTimeCleaned    = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_01_TimeCleaned');
computerInfo.directoryDestinationParsedMATLAB_PoseOnlyDataCleaned    = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_02_DataCleaned');   
computerInfo.directoryDestinationParsedMATLAB_PoseOnlyKalmanFiltered = cat(2,computerInfo.rootDestinationDrive,'\MappingVanData\ParsedMATLAB_PoseOnly\Merged_03_KalmanFiltered');   

end % Ends fcn_INTERNAL_setDefaultMappingVanDataDirectories

%% fcn_INTERNAL_printMenuOptions
function fcn_INTERNAL_printMenuOptions(allowableOptions, allOptions, promptsForOptions, parsingChoice)
% Prints the main menu options
for ith_option = 1:length(allOptions)
    thisOption = allOptions{ith_option};
    if strcmpi(thisOption,'h')
        fprintf('\n');
    end

    fcn_INTERNAL_showSelection(parsingChoice,allOptions{ith_option});
    if any(strcmp(thisOption,allowableOptions))
        fcn_DebugTools_cprintf(0.0*[1 1 1],'%s\n',promptsForOptions{ith_option});
    else
        fcn_DebugTools_cprintf(0.8*[1 1 1],'%s\n',promptsForOptions{ith_option});
    end

end

end % Ends fcn_INTERNAL_printMenuOptions

%% fcn_INTERNAL_setDriveName
function driveName = fcn_INTERNAL_setDriveName(driveLetter,allDriveLetters, allDriveNames)
matchingIndex = find(strcmpi(driveLetter,allDriveLetters),1);
driveName = allDriveNames{matchingIndex,1};

end % Ends fcn_INTERNAL_setDriveName

%% fcn_INTERNAL_extractFullAndShortNames
function [cellArrayOfFullNames, cellArrayOfShortNames, cellArrayOfFileNames, arrayOfBytes, goodDirectories] = ...
    fcn_INTERNAL_extractFullAndShortNames(directoryListing, directoryStub, stringSourceQuery)

% produces the full names, short names, file names, bytes, and good
% directories.
%
% INPUTS: 
%
% directoryListing: the result of the "dir" command, typically at the
% directoryStub
%
% directoryStub: the folder where names are extracted from (at and below).
% For example 'C:\MappingVanData\ParsedBags\TestTrack\BaseMap\2024-08-05'
%
% stringSourceQuery: the type of query being done, for example 'hash'
%
% OUTPUTS:
%
% cellArrayOfFullNames: a listing of the full path to each folder or file
%
% cellArrayOfShortNames: a listing that shows just the final directory or
% final file name, without folders leading up to that point
% 
% cellArrayOfFileNames: a listing of the file names for each file, or
% folder, with full path. For directories, the filename is the name of the
% final folder in the path.
%
% arrayOfBytes: how many bytes are in each file
% 
%  goodDirectories: if the query is for directories (e.g. all the contents
%  of the query are directories), the good directories are the ones that
%  are not the trivial ones (e.g. "." and ".."). Only the good directories
%  are returned. As well, if the directory listing source is itself a
%  directory (e.g. stringSourceQuery is '*.'), it lists the first directory
%  as well as a "good" directory, even if it is a '.' folder. If the
%  listing is NOT directories, simply returns the directoryListing.


% Is the input ONLY directories? If so, need to get rid of duplications
isDirectory = cell2mat({directoryListing.isdir}');
flagAddFirstDirectoryBack = 0;
if strcmp(stringSourceQuery,'*.')
    flagAddFirstDirectoryBack = 1;
end


if all(isDirectory)
    queryNames     = {directoryListing.name}';
    goodIndices     = ~strcmp(queryNames,'.');
   
    if 1==flagAddFirstDirectoryBack
        goodIndices(1) = true;
    end

    goodDirectories = directoryListing(goodIndices);
else
    goodDirectories = directoryListing;
end
    

queryNames     = {goodDirectories.name}';
queryFolders   = {goodDirectories.folder}';
if 1==flagAddFirstDirectoryBack
    firstString = queryFolders{1};
    lastFileSep = find(firstString==filesep,1,'last');
    queryNames{1} = firstString(lastFileSep+1:end);
    queryFolders{1} = firstString(1:lastFileSep-1);
end
arrayOfBytes   = cell2mat({goodDirectories.bytes}');

Nfolders = length(queryFolders);
cellArrayOfFullNames  = cell(Nfolders,1);
cellArrayOfShortNames = cell(Nfolders,1);
cellArrayOfFileNames  = cell(Nfolders,1);
for ith_name = 1:Nfolders
    fullDirectoryName = cat(2,queryFolders{ith_name},filesep,queryNames{ith_name});
    cellArrayOfFullNames{ith_name}  = fullDirectoryName;
    cellArrayOfShortNames{ith_name} = extractAfter(fullDirectoryName,directoryStub);
    if strcmp(fullDirectoryName,directoryStub)
        cellArrayOfShortNames{ith_name} = queryNames{ith_name};
    end
    cellArrayOfFileNames{ith_name}  = cat(2,fullDirectoryName,filesep,queryNames{ith_name});
end
end % Ends fcn_INTERNAL_extractFullAndShortNames

%% fcn_INTERNAL_printTimeEstimate
function fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, stringEstimatedOrCalculated, stringWhatWasDone)
fprintf(1,'%s time to %s: ', stringEstimatedOrCalculated, stringWhatWasDone);
if timeEstimateInSeconds<100
    fprintf(1,'\t %.2f seconds \n', timeEstimateInSeconds)
elseif timeEstimateInSeconds>=100 && timeEstimateInSeconds<3600
    fprintf(1,'\t %.2f seconds (e.g. %.2f minutes)\n',timeEstimateInSeconds, timeEstimateInSeconds/60);
else
    fprintf(1,'\t %.2f seconds (e.g. %.2f minutes, or %.2f hours)\n',timeEstimateInSeconds, timeEstimateInSeconds/60, timeEstimateInSeconds/3600);
end
end % Ends fcn_INTERNAL_printTimeEstimate

%% fcn_INTERNAL_showHelp
function fcn_INTERNAL_showHelp
% Shows help prompt

type('helpParseRaw.txt');
fprintf(1,'(hit any key to continue...)\n');
pause;

end