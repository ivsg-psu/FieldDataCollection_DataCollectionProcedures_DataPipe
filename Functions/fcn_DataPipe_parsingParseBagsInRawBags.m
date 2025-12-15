function fcn_DataPipe_parsingParseBagsInRawBags(directorySourceRawBags, directoryDestinationParsedBags_PoseOnly, directoryDestinationParsedBags, bytesPerSecondPoseOnly, bytesPerSecondFull, varargin)
%% fcn_DataPipe_parsingParseBagsInRawBags
% Checks which files need to be parsed, and parses selected bag files
%
% FORMAT:
%
%      fcn_DataPipe_parsingParseBagsInRawBags(directorySourceRawBags, directoryDestinationParsedBags_PoseOnly, directoryDestinationParsedBags, bytesPerSecondPoseOnly, bytesPerSecondFull, (figNum));
%
% INPUTS:
%
%      directorySourceRawBags: a string containing the path of the 
%      directory containing the unsorted bags.
%
%      directoryDestinationParsedBags_PoseOnly: a string containing the path of the 
%      directory where the pose-only files should be parsed into
%
%      directoryDestinationParsedBags: a string containing the path of the 
%      directory where the full parsed files should be parsed into
%
%      bytesPerSecondPoseOnly: the number of bytes that can be processed in
%      pose-only mode
%
%      bytesPerSecondFull: the number of bytes that can be processed in
%      full parsing mode
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
%     See the script: script_test_fcn_DataPipe_parsingParseBagsInRawBags
%     for a full test suite.
%
% This version of the function was written on 2025_12_13 by S. Brennan
% Questions or comments? sbrennan@psu.edu


% REVISION HISTORY:
%
% 2025_12_13 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of DataPipe demo

% TO-DO:
%
% 2025_12_13 by Sean Brennan, sbrennan@psu.edu
% (fill in items here)

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 6; % The largest Number of argument inputs to the function
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
        narginchk(5,MAX_NARGIN);

        % % Check the directorySourceRawBags to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(directorySourceRawBags, 'DoesDirectoryExist');
        % 
        % % Check the directoryDestinationParsedBags_PoseOnly to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(directoryDestinationParsedBags_PoseOnly, 'DoesDirectoryExist');

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
%
%   _____ _               _     __          ___     _      _       ______ _ _             _   _               _   _          ____         _____                        _
%  / ____| |             | |    \ \        / / |   (_)    | |     |  ____(_) |           | \ | |             | | | |        |  _ \       |  __ \                      | |
% | |    | |__   ___  ___| | __  \ \  /\  / /| |__  _  ___| |__   | |__   _| | ___  ___  |  \| | ___  ___  __| | | |_ ___   | |_) | ___  | |__) |_ _ _ __ ___  ___  __| |
% | |    | '_ \ / _ \/ __| |/ /   \ \/  \/ / | '_ \| |/ __| '_ \  |  __| | | |/ _ \/ __| | . ` |/ _ \/ _ \/ _` | | __/ _ \  |  _ < / _ \ |  ___/ _` | '__/ __|/ _ \/ _` |
% | |____| | | |  __/ (__|   <     \  /\  /  | | | | | (__| | | | | |    | | |  __/\__ \ | |\  |  __/  __/ (_| | | || (_) | | |_) |  __/ | |  | (_| | |  \__ \  __/ (_| |
%  \_____|_| |_|\___|\___|_|\_\     \/  \/   |_| |_|_|\___|_| |_| |_|    |_|_|\___||___/ |_| \_|\___|\___|\__,_|  \__\___/  |____/ \___| |_|   \__,_|_|  |___/\___|\__,_|
%
%
% http://patorjk.com/software/taag/#p=display&f=Big&t=Check%20Which%20Files%20Need%20to%20Be%20Parsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rawBagSourceDirectory                  = cat(2,rootSourceDrive,'\MappingVanData\RawBags');
% poseOnlyParsedBagDestinationDirectory       = cat(2,rootDestinationDrive,'\MappingVanData\ParsedBags_PoseOnly');
% fullParsedBagDestinationDirectory           = cat(2,rootDestinationDrive,'\MappingVanData\ParsedBags');

% THe following extension folder is for debugging or focusing on particular
% types of data
extensionFolder            = filesep;
% extensionFolder            = '\TestTrack\';
% extensionFolder            = '\OnRoad\';
% extensionFolder            = '\TestTrack\Scenario 1.2\2024-12-03\';

rawBagSearchDirectory                = cat(2,directorySourceRawBags,extensionFolder);
poseOnlyParsedBagDirectory           = cat(2,directoryDestinationParsedBags_PoseOnly,extensionFolder);
fullParsedBagRootDirectory           = cat(2,directoryDestinationParsedBags,extensionFolder);

% Make sure folders exist!
fcn_DataPipe_helperConfirmDirectoryExists(rawBagSearchDirectory, (1), (-1));
fcn_DataPipe_helperConfirmDirectoryExists(poseOnlyParsedBagDirectory, (1), (-1));
fcn_DataPipe_helperConfirmDirectoryExists(fullParsedBagRootDirectory, (1), (-1));


% Query the raw bags available for parsing within rawBagSearchDirectory
fileQueryString = '*.bag'; % The more specific, the better to avoid accidental loading of wrong information
flag_fileOrDirectory = 0; % A file
directory_allRawBagFiles = fcn_DebugTools_listDirectoryContents({rawBagSearchDirectory}, (fileQueryString), (flag_fileOrDirectory), (-1));

fprintf(1,'\n\n Scanning for raw bag files in the folder: %s',rawBagSearchDirectory);
if 1==1
    % Print the results?
    fcn_DebugTools_printDirectoryListing(directory_allRawBagFiles, ([]), ([]), (1));
end

%%%
% Summarize the file sizes
totalBytes = fcn_DebugTools_countBytesInDirectoryListing(directory_allRawBagFiles, (1:length(directory_allRawBagFiles)));
estimatedPoseOnlyParseTime = totalBytes/bytesPerSecondPoseOnly;
estimatedFullParseTime = totalBytes/bytesPerSecondFull;

timeInSeconds = estimatedPoseOnlyParseTime;
fprintf(1,'\nTotal maximum time to process these %.0f bags, pose only:\n %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));
timeInSeconds = estimatedFullParseTime;
fprintf(1,'Total maximum time to process these %.0f bags, full (no cameras): \n %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',length(directory_allRawBagFiles),timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));

%%%
% Extract all the file names for the types of files to process
bagFileNames = {directory_allRawBagFiles.name}';


%%% Start the parsing menu...
% What type of parsing to do?

flag_keepGoing = 1;
if 1==flag_keepGoing


    % Set default choice
    parsingChoice = 'p';

    % Set default filesToKeep
    clear filesToKeep
    filesToKeep = ~contains(bagFileNames,'Ouster') .* ~contains(bagFileNames,'velodyne') .* ~contains(bagFileNames,'cameras');

    % Initialize count of bad inputs and loop flag
    numBadInputs = 0;
    flag_goodReply = 0;
    while 0==flag_goodReply
        fprintf(1,'\nWhat type of files should be analyzed?\n')
        
        fcn_INTERNAL_showSelection(parsingChoice,'p');
        fprintf(1,'p: (P)ose files (fast, but LIDAR/camera data excluded)\n');
        
        fcn_INTERNAL_showSelection(parsingChoice,'v');
        fprintf(1,'v: (V)elodyne LIDAR parsing (very slow).\n')
        
        fcn_INTERNAL_showSelection(parsingChoice,'c');
        fprintf(1,'c: (C)amera image parsing (very slow).\n')
        
        fcn_INTERNAL_showSelection(parsingChoice,'o');
        fprintf(1,'o: (O)uster LIDAR parsing (very slow).\n')

        fcn_INTERNAL_showSelection(parsingChoice,'a');
        fprintf(1,'a: (A)ccept and continue.\n')

        fcn_INTERNAL_showSelection(parsingChoice,'q');
        fprintf(1,'q: (Q)uit.\n')

        % Fill in filesToKeep, processType, and processName based on selection
        switch lower(parsingChoice)
            case 'p'
                filesToKeep = ~contains(bagFileNames,'Ouster') .* ~contains(bagFileNames,'velodyne') .* ~contains(bagFileNames,'cameras');
                processType = 'pose-only';
                processName = 'pose';
            case 'v'
                filesToKeep = ~contains(bagFileNames,'Ouster') .* ~contains(bagFileNames,'velodyne') .* ~contains(bagFileNames,'cameras');
                % NOTE: some files have "velodyne" naming - these are deprecated.
                % filesToKeep = contains(bagFileNames,'velodyne');
                processType = 'LIDAR/camera';
                processName = 'Velodyne';
            case 'c'
                filesToKeep = contains(bagFileNames,'cameras');
                processType = 'LIDAR/camera';
                processName = 'camera';
            case 'o'
                filesToKeep = contains(bagFileNames,'OusterO1_Raw');
                processType = 'LIDAR/camera';
                processName = 'Ouster';
            otherwise
                % Use defaults
        end

        % Estimate times
        goodFileindicies = find(filesToKeep);
        bagFileNamesSelected = bagFileNames(goodFileindicies);
        directory_selectedRawBagFiles = directory_allRawBagFiles(goodFileindicies);

        % Summarize the processing times, starting with maximums
        if strcmp(parsingChoice,'p')
            speedBytesPerSecond = bytesPerSecondPoseOnly;
            parsedBagRoot = directoryDestinationParsedBags_PoseOnly;
        else
            speedBytesPerSecond = bytesPerSecondFull;
            parsedBagRoot = directoryDestinationParsedBags;
        end
        totalBytes = fcn_DebugTools_countBytesInDirectoryListing(directory_selectedRawBagFiles, (1:length(directory_selectedRawBagFiles)));
        estimatedParseTime = totalBytes/speedBytesPerSecond;

        timeInSeconds = estimatedParseTime;
        fprintf(1,'Total estimated time to %s process all %.0f %s bags: \n %.2f seconds (e.g. %.2f minutes, or %.2f hours, or %.2f days) \n',...
            processType, length(directory_selectedRawBagFiles), processName, timeInSeconds, timeInSeconds/60, timeInSeconds/3600, timeInSeconds/(3600*24));

        parseType = input('Selection? [default = p]:','s');
        if isempty(parseType)
            parseType = 'p';
        end

        fprintf(1,'Selection chosen: -->  %s\n',parseType);

        switch lower(parseType)
            case 'p'
                parsingChoice = 'p';

            case 'v'
                parsingChoice = 'v';

            case 'c'
                parsingChoice = 'c';

            case 'o'
                parsingChoice = 'o';

            case 'a'
                flag_goodReply = 1;
                flag_keepGoing = 1;
                fprintf(1,'Accepted - continuing.\n');

            case 'q'
                flag_goodReply = 1;
                flag_keepGoing = 0;
                fprintf(1,'Quitting\n');

            otherwise
                numBadInputs = numBadInputs + 1;
                if numBadInputs>3
                    fprintf(1,'Too many failed inputs: %.0f of 3 allowed. Exiting.\n',numBadInputs);
                    flag_goodReply = 1;
                    flag_keepGoing = 0;
                else
                    fprintf(1,'Unrecognized option: %s. Try again (try %.0f of 3) \n ', parseType, numBadInputs);
                end

        end
    end % Ends while loop
end

%%% Show the choices

if 1==flag_keepGoing

    %%%
    % Summarize the file sizes?
    if 1==0
        fprintf(1,'\n\nSELECTED FILES: \n');
        % TO DO - fix directory listing to include full name
        fcn_DebugTools_printDirectoryListing(directory_selectedRawBagFiles, ([]), ([]), (1));
    end


    %%%%
    % Find which files were previously parsed
    flag_matchingType = 2; % file to folder
    typeExtension = '.bag';
    flags_fileWasPreviouslyParsed = fcn_DebugTools_compareDirectoryListings(directory_selectedRawBagFiles, directorySourceRawBags, parsedBagRoot, (flag_matchingType), (typeExtension), (1));

    %%%%
    % Print the results
    NcolumnsToPrint = 2;
    cellArrayHeaders = cell(NcolumnsToPrint,1);
    cellArrayHeaders{1} = 'BAG NAME                                   ';
    cellArrayHeaders{2} = 'PREVIOUSLY PARSED';
    cellArrayValues = [bagFileNamesSelected, fcn_DebugTools_convertBinaryToYesNoStrings(flags_fileWasPreviouslyParsed)];
    fid = 1;
    fcn_DebugTools_printNumeredDirectoryList(directory_selectedRawBagFiles, cellArrayHeaders, cellArrayValues, (directorySourceRawBags), (fid))
end


%%% What numbers of files to parse?
if 1==flag_keepGoing
    [flag_keepGoing, indiciesSelected] = fcn_DebugTools_queryNumberRange(flags_fileWasPreviouslyParsed, (' of the file(s) to parse'), (1), (directory_selectedRawBagFiles), (1));
end

%%% Estimate the time it takes to parse
if 1==flag_keepGoing

    if strcmp(processType,'pose-only')
        bytesPerSecond = bytesPerSecondPoseOnly;
    elseif strcmp(processType,'LIDAR/camera')
        bytesPerSecond = bytesPerSecondFull;
    end

    [flag_keepGoing, timeEstimateInSeconds] = fcn_DebugTools_confirmTimeToProcessDirectory(directory_selectedRawBagFiles, bytesPerSecond, (indiciesSelected),(1));
end

%%%%
% Parse the files

if 1==flag_keepGoing

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
    end

    if strcmp(processType,'pose-only')
        parse_command_starter = 'py main_bag_to_csv_py3_poseOnly.py';
        parsedFileLocationFolder = directoryDestinationParsedBags_PoseOnly;
    elseif strcmp(processType,'LIDAR/camera')
        parse_command_starter = 'py main_bag_to_csv_py3.py';
        parsedFileLocationFolder = directoryDestinationParsedBags;
    else
        error('Unknown error - should not enter here!');
    end

    alltstart = tic;
    Ndone = 0;
    NtoProcess = length(indiciesSelected);
    for ith_index = 1:NtoProcess
        ith_bagFile = indiciesSelected(ith_index);
        Ndone = Ndone + 1;
        sourceBagFolderName  = directory_selectedRawBagFiles(ith_bagFile).folder;
        thisFolder           = extractAfter(sourceBagFolderName,directorySourceRawBags);
        thisBytes            = directory_selectedRawBagFiles(ith_bagFile).bytes;

        destinationBagFolder = cat(2,parsedFileLocationFolder,thisFolder);

        thisFileFullName = directory_selectedRawBagFiles(ith_bagFile).name;
        thisFile = extractBefore(thisFileFullName,'.bag');

        fprintf(1,'\n\nProcessing file: %d (file %d of %d)\n', ith_bagFile, Ndone,NtoProcess);
        fprintf(1,'Initiating parsing for file: %s\n',thisFile);
        fprintf(1,'Pulling from folder: %s\n',sourceBagFolderName);
        fprintf(1,'Pushing to folder: %s\n',destinationBagFolder);


        % Build the end string, and fix back-slashes to forward slashes
        parse_command_end = sprintf(' -s "%s" -d "%s" -b "%s"',sourceBagFolderName, destinationBagFolder, thisFileFullName);
        parse_command_end_fixed = parse_command_end;
        parse_command_end_fixed(parse_command_end=='\') = '/';

        % if 7==exist(poseOnlySearchFolder,'dir')
        %     flags_fileWasPoseParsed(ith_bagFile,1) = 1;
        % end

        % Build the command
        parse_command = cat(2,parse_command_starter,parse_command_end_fixed);
        fprintf(1,'Running system parse command: \n\t%s\n',parse_command);


        % replace the file separators

        tstart = tic;
        [status,cmdout] = system(parse_command,'-echo'); %#ok<ASGLU>
        telapsed = toc(tstart);

        totalBytes = directory_selectedRawBagFiles(ith_bagFile).bytes;
        predictedFileTime =  totalBytes/bytesPerSecond;
        fprintf(1,'Processing speed, predicted: %.0f seconds versus actual: %.0f seconds\n',predictedFileTime, telapsed);
        fprintf(1,'Actual bytes per second: %.0f \n',thisBytes/telapsed);
    end
    alltelapsed = toc(alltstart);

    % Check prediction
    fprintf(1,'\nTotal time to process bags: \n');
    if timeEstimateInSeconds<100
        fprintf(1,'\tEstimated: %.2f seconds \n', timeEstimateInSeconds)
        fprintf(1,'\tActual:    %.2f seconds \n', alltelapsed);
    elseif timeEstimateInSeconds>=100 && timeEstimateInSeconds<3600
        fprintf(1,'\tEstimated: %.2f seconds (e.g. %.2f minutes)\n',timeEstimateInSeconds, timeEstimateInSeconds/60);
        fprintf(1,'\tActual:    %.2f seconds (e.g. %.2f minutes)\n',alltelapsed, alltelapsed/60);
    else
        fprintf(1,'\tEstimated: %.2f seconds (e.g. %.2f minutes, or %.2f hours)\n',timeEstimateInSeconds, timeEstimateInSeconds/60, timeEstimateInSeconds/3600);
        fprintf(1,'\tActual:    %.2f seconds (e.g. %.2f minutes, or %.2f hours)\n',alltelapsed, alltelapsed/60, alltelapsed/3600);
    end

    cd(currentPath);

    fprintf(1,'Parsing complete. Check the above messages for errors.\n');
    fprintf(1,'Hit any key to continue.\n');
    pause;
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
