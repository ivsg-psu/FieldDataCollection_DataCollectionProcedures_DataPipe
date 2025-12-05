%% script_main_ParseRaw.m
%
% This main script is used to demonstrate key codes in parsing bag files
% from the mapping van
%
% Author: Sean Brennan, Xinyu Cao, Sadie Duncan, Liming Gao
% Original Date of Creation: 2024-10-13 from DataClean repo


% REVISION HISTORY:
%
% As: script_main_ParseRaw (within the ParseRawDataToDatabase repo)
% 
% 2024_10_13 by Sean Brennan, sbrennan@psu.edu
% - First creation of the code
% 
% 2024_10_13 by Sean Brennan, sbrennan@psu.edu
% -- Added new debug tools
% 
% 2024_10_21 by Sean Brennan, sbrennan@psu.edu
% - Added and tested automated parsing section
% 
% 2024_10_25 by Sean Brennan, sbrennan@psu.edu
% -- Added directory comparison and query tools using DebugTools
% 
% 2024_12_28 by Sean Brennan, sbrennan@psu.edu
% - Added complete menu system
% 
% 2025_01_10 by Sean Brennan, sbrennan@psu.edu
% - Added MAT file generation to menu system
% 
% 2025_09_18 by Sean Brennan, sbrennan@psu.edu
% - Added clarity to menu system 
% - Added help file
% - Fixed many bug issues
% - Added script_test_fcn_DataClean_loadRawDataFromDirectories and
%   fcn_DataClean_loadRawDataFromDirectories from
%   DataCleanClassLibrary repo
% - Added LoadRawDataToMATLAB_v2025_09_21 functions
%   % * Raw data loading
%   % * Saving mat files
%   % * Merging data that is in sequence
%   % This depends on the following libraries, which were also installed:
%   % - PathClass_v2025_08_03
%   % - GetUserInputPath_v2025_04_27
%   % - PlotRoad_v2025_07_16
%   % - GeometryClass_v2025_05_31
%   % - GPSClass_v2023_04_21
% - Added LoadRawDataToMATLAB_v2025_09_22 functions
% - Added LoadRawDataToMATLAB_v2025_09_23 functions
% - Added wrapper function for better future integration
% - Added MAT file generation capability using wrapper
% - Added plotting capability using wrapper
% - Added merge capability using wrapper
% - Added LoadRawDataToMATLAB_v2025_09_23b functions
% 
% 2025_09_25 - Aneesh Batchu
% - Added Aneesh's lab laptop in fcn_INTERNAL_setDefaultParsingSpeeds 
% 
% 2025_09_26 by Sean Brennan, sbrennan@psu.edu
% - Bug fix where missing new line in error statement
% - Bug fix where 7z zip file extraction was nesting extracted folder into
%   % copy of the same folder.
% 
% As: script_demo_DataPipe
%
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% - Moved code into new repo
% - Added autoinstaller
% - Moved many INTERNAL functions to be external stand-alone functions,
%   % with 'helper' designations


%%%%%
% Known issues:
% 
% 2025_06_19 - Aneesh Batchu
% -- For macs, Volumes can be found by doing: dir("/Volumes")

%%%%
% TO_DO:
% (none)


%% Prep the workspace
close all

%% Make sure we are running out of root directory
st = dbstack; 
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% Clear paths and folders, if needed
if 1==1
    clear flag_DataPipe_Folders_Initialized
end
if 1==0
    fcn_INTERNAL_clearUtilitiesFromPathAndFolders;
end
if 1==0
    % Resets all paths to factory default
    restoredefaultpath;
end

%% Install dependencies
% Define a universal resource locator (URL) pointing to the repos of
% dependencies to install. Note that DebugTools is always installed
% automatically, first, even if not listed:
clear dependencyURLs dependencySubfolders
ith_repo = 0;

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_DataCollectionProcedures_LoadRawDataToMATLAB';
dependencySubfolders{ith_repo} = {'Functions', 'Data'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_PathTools_PathClassLibrary';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_PathTools_GetUserInputPath';
dependencySubfolders{ith_repo} = {''};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_VisualizingFieldData_PlotRoad';
dependencySubfolders{ith_repo} = {'Functions','Data'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/FieldDataCollection_GPSRelatedCodes_GPSClass';
dependencySubfolders{ith_repo} = {'Functions'};

ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/PathPlanning_GeomTools_GeomClassLibrary';
dependencySubfolders{ith_repo} = {'Functions','Data'};

%% Do we need to set up the work space?
if ~exist('flag_DataPipe_Folders_Initialized','var')

    % Clear prior global variable flags
    clear global FLAG_*

    % Navigate to the Installer directory
    currentFolder = pwd;
    cd('Installer');
    % Create a function handle
    func_handle = @fcn_DebugTools_autoInstallRepos;

    % Return to the original directory
    cd(currentFolder);

    % Call the function to do the install
    func_handle(dependencyURLs, dependencySubfolders, (0), (-1));

    % Add this function's folders to the path
    this_project_folders = {...
        'Functions','Data'};
    fcn_DebugTools_addSubdirectoriesToPath(pwd,this_project_folders)

    flag_DataPipe_Folders_Initialized = 1;
end



%% Set environment flags that define the ENU origin
% This sets the "center" of the ENU coordinate system for all plotting
% functions

% % Location for Test Track base station
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.86368573');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-77.83592832');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','344.189');

% Location for Pittsburgh, site 1
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.44181017');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.76090840');
setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','327.428');

% % Location for Site 2, Falling water
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','39.995339');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-79.445472');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','344.189');

% % Location for Aliquippa, site 3
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE','40.694871');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE','-80.263755');
% setenv('MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE','223.294');


%% Set environment flags for plotting
% These are values to set if we are forcing image alignment via Lat and Lon
% shifting, when doing geoplot. This is added because the geoplot images
% are very, very slightly off at the test track, which is confusing when
% plotting data
setenv('MATLABFLAG_PLOTROAD_ALIGNMATLABLLAPLOTTINGIMAGES_LAT','-0.0000008');
setenv('MATLABFLAG_PLOTROAD_ALIGNMATLABLLAPLOTTINGIMAGES_LON','0.0000054');


%% Set environment flags for input checking
% These are values to set if we want to check inputs or do debugging
% setenv('MATLABFLAG_FINDEDGE_FLAG_CHECK_INPUTS','1');
% setenv('MATLABFLAG_FINDEDGE_FLAG_DO_DEBUG','1');
setenv('MATLABFLAG_DATAPIPE_FLAG_CHECK_INPUTS','1');
setenv('MATLABFLAG_DATAPIPE_FLAG_DO_DEBUG','0');

%% Main menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  __  __       _         __  __
% |  \/  |     (_)       |  \/  |
% | \  / | __ _ _ _ __   | \  / | ___ _ __  _   _
% | |\/| |/ _` | | '_ \  | |\/| |/ _ \ '_ \| | | |
% | |  | | (_| | | | | | | |  | |  __/ | | | |_| |
% |_|  |_|\__,_|_|_| |_| |_|  |_|\___|_| |_|\__,_|
%
%
% http://patorjk.com/software/taag/#p=display&f=Big&t=Main%20Menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


URHERE - need to functionalize the menu, suggest DataPipe_mainDataPipeMenu

%% Set computer info
% This includes default directories, disk locations, etc

% Get disks to use
clear computerInfo
computerInfo = struct;
infoTable = fcn_DataPipe_helperListPhysicalDrives((-1));

% Fill default drive information, and save available drives
[computerInfo.rootSourceDrive, ~, allDriveLetters, allDriveNames] ...
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
    computerInfo.rootDestinationDriveName = fcn_INTERNAL_setDriveName(computerInfo.rootDestinationDrive,allDriveLetters, allDriveNames);

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
            fcn_INTERNAL_checkIfFilesStaged(computerInfo.directoryUnsortedBags, computerInfo.directoryDestinationRawBags);

        case 's'
            fcn_INTERNAL_stageUnsortedBagFoldersForCopyIntoRawBags(computerInfo.directoryUnsortedBags, computerInfo.directoryTempStaging)

        case 'm'
            fcn_INTERNAL_measureParsingSpeed(computerInfo.rootSourceDrive, computerInfo.directoryTempStaging)

        case 'p'

            fcn_INTERNAL_parseBagsInRawBags(...
                computerInfo.directorySourceRawBags, ...
                computerInfo.directoryDestinationParsedBags_PoseOnly, ...
                computerInfo.directoryDestinationParsedBags, ....
                bytesPerSecondPoseOnly, bytesPerSecondFull)

        case 'z'
            % fcn_INTERNAL_zipHashTablesInParsed(computerInfo.directorySourceParsedBags, computerInfo.directoryTempStaging)

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
            fcn_INTERNAL_unzipHashTablesInParsed(computerInfo.directorySourceParsedBags, computerInfo.directoryTempStaging)

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


%% Supporting Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _    _      _                    ______                _   _
% | |  | |    | |                  |  ____|              | | (_)
% | |__| | ___| |_ __   ___ _ __   | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
% |  __  |/ _ \ | '_ \ / _ \ '__|  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
% | |  | |  __/ | |_) |  __/ |     | |  | |_| | | | | (__| |_| | (_) | | | \__ \
% |_|  |_|\___|_| .__/ \___|_|     |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%               | |
%               |_|
% https://patorjk.com/software/taag/#p=display&f=Big&t=Helper++Functions&x=none&v=4&h=4&w=80&we=false
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



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

%% function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
% Clear out the variables
clear global flag* FLAG*
clear flag*
clear path

% Clear out any path directories under Utilities
if ispc
    path_dirs = regexp(path,'[;]','split');
elseif ismac
    path_dirs = regexp(path,'[:]','split');
elseif isunix
    path_dirs = regexp(path,'[;]','split');
else
    error('Unknown operating system. Unable to continue.');
end

utilities_dir = fullfile(pwd,filesep,'Utilities');
for ith_dir = 1:length(path_dirs)
    utility_flag = strfind(path_dirs{ith_dir},utilities_dir);
    if ~isempty(utility_flag)
        rmpath(path_dirs{ith_dir})
    end
end

% Delete the Utilities folder, to be extra clean!
if  exist(utilities_dir,'dir')
    [status,message,message_ID] = rmdir(utilities_dir,'s');
    if 0==status
        error('Unable remove directory: %s \nReason message: %s \nand message_ID: %s\n',utilities_dir, message,message_ID);
    end
end

end % Ends fcn_INTERNAL_clearUtilitiesFromPathAndFolders


%% fcn_INTERNAL_confirmDirectoryExists
function flagDirectoryExists = fcn_INTERNAL_confirmDirectoryExists(directoryName, flagHaltIfFail)
% Checks to see if a directory exists, returning true or false, given a
% string/character name. A user can give a flag that forces the code to
% throw an error. During the throw, a warning is also thrown to allow
% traceback into the code.

if 7~=exist(directoryName,'dir')
    if flagHaltIfFail==1
        % uigetdir(matlabroot,'MATLAB Root Folder')
        warning('on','backtrace');
        warning('Unable to find folder: \n\t%s',directoryName);
        error('Desired directory: %s does not exist!',directoryName);
    end
    flagDirectoryExists = false;
else
    flagDirectoryExists = true;
end
end % Ends fcn_INTERNAL_confirmDirectoryExists



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


%% fcn_INTERNAL_showDiskList
function diskStrings = fcn_INTERNAL_showDiskList(infoTable, goodDisks, allDriveNames) %#ok<INUSD>
diskStrings = cell(length(goodDisks),1);
if ~isempty(goodDisks)

    for ith_disk = 1:length(goodDisks)
        diskToScan = goodDisks(ith_disk);
        deviceID = infoTable(diskToScan,:).DeviceID;
        volumeName = infoTable(diskToScan,:).VolumeName;
        FileSystem = infoTable(diskToScan,:).FileSystem;
        if ~strcmp(volumeName,"")
            thisDiskString = sprintf('%s (%s, %s)',deviceID, volumeName, FileSystem);
        else
            thisDiskString = sprintf('%s (-unnamed- %s) %s',deviceID, FileSystem, temp);
        end
        diskStrings{ith_disk} = thisDiskString;
    end
end

end % Ends fcn_INTERNAL_showDiskList

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






%% fcn_INTERNAL_checkIfFilesStaged
function fcn_INTERNAL_checkIfFilesStaged(directoryUnsortedBags, directoryRawBags)
% Checks if unparsed files are already staged
% Staged = the files already exist in the processed rawBags directory,
% namely they are associated with an existing test, been processed already,
% etc. This section is thus basically checking if a "ReadyToParse" set of
% files was already parsed. It's thus very useful when reviewing old
% directories to check if staged files were already done. In particular,
% one can set up a folder or folders of bag files, and this code checks to
% see if the same bags already exist in the raw bag "staged" area.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____ _               _      _  __   ______ _ _              _____ _                       _
%  / ____| |             | |    (_)/ _| |  ____(_) |            / ____| |                     | |
% | |    | |__   ___  ___| | __  _| |_  | |__   _| | ___  ___  | (___ | |_ __ _  __ _  ___  __| |
% | |    | '_ \ / _ \/ __| |/ / | |  _| |  __| | | |/ _ \/ __|  \___ \| __/ _` |/ _` |/ _ \/ _` |
% | |____| | | |  __/ (__|   <  | | |   | |    | | |  __/\__ \  ____) | || (_| | (_| |  __/ (_| |
%  \_____|_| |_|\___|\___|_|\_\ |_|_|   |_|    |_|_|\___||___/ |_____/ \__\__,_|\__, |\___|\__,_|
%                                                                                __/ |
%                                                                               |___/
% http://patorjk.com/software/taag/#p=display&f=Big&t=Check%20if%20Files%20Staged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(directoryUnsortedBags,1);
fcn_INTERNAL_confirmDirectoryExists(directoryRawBags,1);

% Obtain the directory listing of all bag files
fileQueryString = '*.bag'; % The more specific, the better to avoid accidental loading of wrong information
flag_fileOrDirectory = 0; % A file
directory_allRawBagFilesUnparsed = fcn_DebugTools_listDirectoryContents({directoryUnsortedBags}, (fileQueryString), (flag_fileOrDirectory), (-1));

% Sort them by time
directory_allRawBagFilesUnparsed_sorted = fcn_DebugTools_sortDirectoryListingByTime(directory_allRawBagFilesUnparsed);

% Create a listing of all files that are in the "Organized" folder
flag_fileOrDirectory = 0; % A file
directory_allOrganizedBagFiles = fcn_DebugTools_listDirectoryContents({directoryRawBags}, (fileQueryString), (flag_fileOrDirectory), (-1));

% Print the results? (for debugging)
if 1==1
    fprintf(1,'ALL RAW BAG FILES FOUND IN FOLDER AND SUBFOLDERS OF: %s',directoryUnsortedBags );
    fcn_DebugTools_printDirectoryListing(directory_allRawBagFilesUnparsed_sorted, ([]), ([]), (1));
end

%%%
% Extract all the file names of the organized files
NbagFilesInRawBagFolder = length(directory_allOrganizedBagFiles);
rawBagFolderFileNames   = cell(NbagFilesInRawBagFolder,1);

for ith_bagFile = 1:NbagFilesInRawBagFolder
    rawBagFolderFileNames{ith_bagFile} = directory_allOrganizedBagFiles(ith_bagFile).name;
end

%%%
% Find which of the source bags are NOT within the existing directory
NbagFilesInSourceBagFolder = length(directory_allRawBagFilesUnparsed_sorted);
flag_bagFileIsAlreadySorted = zeros(NbagFilesInSourceBagFolder,1);
for ith_sourceBagFile = 1:NbagFilesInSourceBagFolder
    thisBagName = directory_allRawBagFilesUnparsed_sorted(ith_sourceBagFile).name;
    if any(contains(rawBagFolderFileNames,thisBagName))
        flag_bagFileIsAlreadySorted(ith_sourceBagFile,1) = 1;
    end
end




%%%%
% Print the results
Ncharacters_Name = 70;
Ncharacters_flag = 30;

fprintf(1,'\n\n');
nameString  = fcn_DebugTools_debugPrintStringToNCharacters('BAG NAME',Ncharacters_Name);
flag1String = fcn_DebugTools_debugPrintStringToNCharacters('ALREADY STAGED?',Ncharacters_flag);
fprintf(1,'\t\t%s\t%s\n',nameString,flag1String);

previous_folder = '';
for ith_bagFile = 1:NbagFilesInSourceBagFolder
    thisFolder   = directory_allRawBagFilesUnparsed_sorted(ith_bagFile).folder;

    if ~strcmp(thisFolder,previous_folder)
        fprintf(1,'Folder: %s:\n',thisFolder);
        previous_folder = thisFolder;
    end

    nameString  = fcn_DebugTools_debugPrintStringToNCharacters(directory_allRawBagFilesUnparsed_sorted(ith_bagFile).name,Ncharacters_Name);
    fprintf(1,'\t%.0d\t%s\t',ith_bagFile,nameString);

    % Print the flag_bagFileIsAlreadySorted results
    if 1==flag_bagFileIsAlreadySorted(ith_bagFile,1)
        flag1String = fcn_DebugTools_debugPrintStringToNCharacters('yes',Ncharacters_flag);
        fcn_DebugTools_cprintf('*Green','%s\n',flag1String);
    else
        flag1String = fcn_DebugTools_debugPrintStringToNCharacters('no',Ncharacters_flag);
        fcn_DebugTools_cprintf('*Red','%s\n',flag1String);
    end

end
fprintf(1,'(hit any key to continue...)\n');
pause;
end % Ends fcn_INTERNAL_checkIfFilesStaged

%% fcn_INTERNAL_stageUnsortedBagFoldersForCopyIntoRawBags
function fcn_INTERNAL_stageUnsortedBagFoldersForCopyIntoRawBags(directoryUnsortedBags, directoryStaging)
% Prepares bag file listings including readme, organizing by date/time,
% etc. These prepared files are NOT automatically moved into the
% MappingVanData folders because this is dangerious (overwrite!). 
% Rather, this function prepares the files for move
% and requires the user to manually do the move after this step is done.
%
% The input to this is a directory containing files that are usually
% captured directly from the mapping van and stored in a "ReadyToParse"
% area with subfolders indicating details about the test, for example "Lane
% 1 CCW with cameras". It then produces a README file whose subsections
% each list the directory names (as details) and the files within, all in
% time-ordered sequence. It then moves all the files into a date-organized
% folder for the test so that the files can be moved into the organized and
% permanent raw bag file storage area.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _____                                 ____                ______ _ _        _      _     _   _
% |  __ \                               |  _ \              |  ____(_) |      | |    (_)   | | (_)
% | |__) | __ ___ _ __   __ _ _ __ ___  | |_) | __ _  __ _  | |__   _| | ___  | |     _ ___| |_ _ _ __   __ _ ___
% |  ___/ '__/ _ \ '_ \ / _` | '__/ _ \ |  _ < / _` |/ _` | |  __| | | |/ _ \ | |    | / __| __| | '_ \ / _` / __|
% | |   | | |  __/ |_) | (_| | | |  __/ | |_) | (_| | (_| | | |    | | |  __/ | |____| \__ \ |_| | | | | (_| \__ \
% |_|   |_|  \___| .__/ \__,_|_|  \___| |____/ \__,_|\__, | |_|    |_|_|\___| |______|_|___/\__|_|_| |_|\__, |___/
%                | |                                  __/ |                                              __/ |
%                |_|                                 |___/                                              |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Prepare%20Bag%20File%20Listings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find all bag files in a given directory, sort them by time, print
% listings into README, and move files into "date" folder

fig_num = [];

% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(directoryUnsortedBags,1);
fcn_INTERNAL_confirmDirectoryExists(directoryStaging,1);

%% Find the date
% Obtain the directory listing of all bag files
fileQueryString = '*.bag'; % The more specific, the better to avoid accidental loading of wrong information
flag_fileOrDirectory = 0; % A file
directory_allRawBagFilesUnparsed = fcn_DebugTools_listDirectoryContents({directoryUnsortedBags}, (fileQueryString), (flag_fileOrDirectory), (-1));

likelyYearMonthDayString = '';
for ith_file = 1:length(directory_allRawBagFilesUnparsed)
    thisFileName = directory_allRawBagFilesUnparsed(ith_file).name;
    % Look for file names of format: mapping_van_2YYY_MM_DD so that we can
    % grab the year, month, day
    if contains(thisFileName,'mapping_van_2')
        newStr = extractAfter(thisFileName,'mapping_van_');
        thisYearMonthDayString = newStr(1:10);
        if isempty(likelyYearMonthDayString)
            likelyYearMonthDayString = thisYearMonthDayString;
        else
            if ~strcmp(likelyYearMonthDayString, thisYearMonthDayString)
                warning('on','backtrace');
                warning('A date was found: %s that is inconsistent with other dates in the files: %s',thisYearMonthDayString, likelyYearMonthDayString);
                fprintf(1,'Exiting sub-menu!\n');
                fprintf(1,'Hit any key to continue.\n');
                pause;
                return
            end
        end
    end
end

dateStringChoice = input(sprintf('What date should be used to define this test (format: YYYY-MM-DD)? [default = %s]:',likelyYearMonthDayString),'s');
if isempty(dateStringChoice)
    dateStringChoice = likelyYearMonthDayString;
end
if length(dateStringChoice)~=10
    warning('on','backtrace');
    warning('Expected a date string of length 10 characters. The date string entered: %s has %.0f characters.',dateStringChoice,length(dateStringChoice));
    fprintf(1,'Exiting sub-menu!\n');
    fprintf(1,'Hit any key to continue.\n');
    pause;
    return
end

%% Ask for the identifierString

% identifierString = '\\RawBags\TestTrack\Scenario 2.3'; % This should match the identifiers in the DataClean repo for each testing situation
identifierString = input('What identifier should be used to define this test (format: \\\\RawBags\\TestTrack\\Scenario 2.3 ):','s');

%% Prep the folder
dateToProcess = dateStringChoice;
destinationSortedBagDirectory = cat(2,directoryStaging,filesep,dateToProcess);

% directory_allRawBagFilesUnparsed_sorted = fcn_ParseRaw_fullBagFolderPrep({directoryUnsortedBags}, destinationSortedBagDirectory, dateToProcess, identifierString, (fig_num));
fcn_ParseRaw_fullBagFolderPrep({directoryUnsortedBags}, destinationSortedBagDirectory, dateToProcess, identifierString, (fig_num));

fprintf(1,'You must manually copy the directory into the destination. This is to force the user to check results before continuing.\n');
fprintf(1,'Hit any key to continue.\n');
pause;

end % Ends fcn_INTERNAL_stageUnsortedBagFoldersForCopyIntoRawBags


%% fcn_INTERNAL_measureParsingSpeed
function fcn_INTERNAL_measureParsingSpeed(rootSourceDrive, speedTestOutputPath)
%% Check and set parsing speeds
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
fcn_INTERNAL_confirmDirectoryExists(speedTestInputPath,1);
fcn_INTERNAL_confirmDirectoryExists(speedTestOutputPath,1);


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


end % Ends fcn_INTERNAL_measureParsingSpeed

%% fcn_INTERNAL_parseBagsInRawBags
function fcn_INTERNAL_parseBagsInRawBags(directorySourceRawBags, directoryDestinationParsedBags_PoseOnly, directoryDestinationParsedBags, bytesPerSecondPoseOnly, bytesPerSecondFull)

% Check which files need to be parsed
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
extensionFolder            = '\';
% extensionFolder            = '\TestTrack\';
% extensionFolder            = '\OnRoad\';
% extensionFolder            = '\TestTrack\Scenario 1.2\2024-12-03\';

rawBagSearchDirectory                = cat(2,directorySourceRawBags,extensionFolder);
poseOnlyParsedBagDirectory           = cat(2,directoryDestinationParsedBags_PoseOnly,extensionFolder);
fullParsedBagRootDirectory           = cat(2,directoryDestinationParsedBags,extensionFolder);

% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(rawBagSearchDirectory,1);
fcn_INTERNAL_confirmDirectoryExists(poseOnlyParsedBagDirectory,1);
fcn_INTERNAL_confirmDirectoryExists(fullParsedBagRootDirectory,1);

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
    fprintf(1,'Parsing complete. Check the above messages for errors.\n');
    fprintf(1,'Hit any key to continue.\n');
    pause;

    cd(currentPath);
end

end % Ends fcn_INTERNAL_parseBagsInRawBags

%% fcn_INTERNAL_zipHashTablesInParsed
function fcn_INTERNAL_zipHashTablesInParsed(sourceParsedBagRootDirectoryDefault, tempZipDirectoryDefault)
% Zips the subdirectories in the hash tables. The tables have 256 entries
% at the primary layer (directory 00 to ff), and within each, another 256
% at the secondary layer, for a total of 256*256 = 65536 folders, each
% containing several files typically.
%
% For example, a typical data measurement "run" may have 100k to 200k
% files. If we zip these down to the primary layer with folders
% 00, 01,... 0e, 0f, 10, 11... , fe, ff
% this produces 256 files for each has table.
%
% This function uses the 7-zip (7z) compression software as the normal
% "zip" software does not handle zip files larger than 2GB, and we regularly
% encounter these in mapping. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______         _    _           _        _____       _         _ _               _             _
% |___  (_)       | |  | |         | |      / ____|     | |       | (_)             | |           (_)
%    / / _ _ __   | |__| | __ _ ___| |__   | (___  _   _| |__   __| |_ _ __ ___  ___| |_ ___  _ __ _  ___  ___
%   / / | | '_ \  |  __  |/ _` / __| '_ \   \___ \| | | | '_ \ / _` | | '__/ _ \/ __| __/ _ \| '__| |/ _ \/ __|
%  / /__| | |_) | | |  | | (_| \__ \ | | |  ____) | |_| | |_) | (_| | | | |  __/ (__| || (_) | |  | |  __/\__ \
% /_____|_| .__/  |_|  |_|\__,_|___/_| |_| |_____/ \__,_|_.__/ \__,_|_|_|  \___|\___|\__\___/|_|  |_|\___||___/
%         | |
%         |_|
%
% http://patorjk.com/software/taag/#p=display&f=Big&t=Zip%20Hash%20Subdirectories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flag_processElseWhere = 1; % set to 1 if process the zip files elsewhere. This is safer than using drives, but is a bit more difficult to manage.

%% Confirm the root folder to look for hashes
sourceRootOrSubroot = uigetdir(sourceParsedBagRootDirectoryDefault,'Select a folder that should be searched, including its subdirectories, for hash tables.');
% If the user hits cancel, it returns 0
if 0==sourceRootOrSubroot
    return;
end
% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(sourceRootOrSubroot,1);

%% Confirm the temporary location to work out of, for zip files
if 1==flag_processElseWhere
    % Confirm the source folders to use
    destinationRootOrSubroot = uigetdir(tempZipDirectoryDefault,'Select a folder to hold temporary zip files during the process. These files may be up to 20GB.');
    % If the user hits cancel, it returns 0
    if 0==destinationRootOrSubroot
        return;
    end
    % Make sure folders exist!
    fcn_INTERNAL_confirmDirectoryExists(destinationRootOrSubroot,1);
end


%% Query the hash tables available for zip within parsed directory
flag_sourceIsFileOrDirectory = 1; % Look for only directories
directory_allVelodyneHashes = fcn_ParseRaw_listDirectoryContents({sourceRootOrSubroot}, 'hashVelodyne_*', (flag_sourceIsFileOrDirectory), (-1));
directory_allCamerasHashes = fcn_ParseRaw_listDirectoryContents({sourceRootOrSubroot}, 'hashCameras_*', (flag_sourceIsFileOrDirectory), (-1));
directory_allOusterO1Hashes = fcn_ParseRaw_listDirectoryContents({sourceRootOrSubroot}, 'hashOusterO1_*', (flag_sourceIsFileOrDirectory), (-1));
directoryListing_allSources = [directory_allVelodyneHashes; directory_allCamerasHashes; directory_allOusterO1Hashes];

fprintf(1,'\n\nFound %.0f hash folders in the parsed data folder: %s\n',length(directoryListing_allSources), sourceRootOrSubroot);
fprintf(1,'\t hashVelodyne_ data had: %.0f hashes\n',length(directory_allVelodyneHashes));
fprintf(1,'\t hashCameras_ data had:  %.0f hashes\n',length(directory_allCamerasHashes));
fprintf(1,'\t hashOusterO1_ data had: %.0f hashes\n',length(directory_allOusterO1Hashes));
if 1==0
    % Print the results?
    fcn_DebugTools_printDirectoryListing(directoryListing_allSources, ([]), ([]), (1));
end

%% Extract all the file names for the types of files to process
[sourceDirectoryFullNames, sourceDirectoryShortNames] = ...
    fcn_INTERNAL_extractFullAndShortNames(directoryListing_allSources, sourceRootOrSubroot,'');


%% Show the choices

%%%%
% Find which files were previously zipped
flags_folderWasPreviouslyProcessed = fcn_INTERNAL_checkIfFolderPreviouslyZipped(sourceDirectoryFullNames);

%%%%
% Print the results
NcolumnsToPrint = 2;
cellArrayHeaders = cell(NcolumnsToPrint,1);
cellArrayHeaders{1} = 'FOLDER NAME                             ';
cellArrayHeaders{2} = 'ALREADY ZIPPED';
cellArrayValues = [sourceDirectoryShortNames, fcn_DebugTools_convertBinaryToYesNoStrings(flags_folderWasPreviouslyProcessed)];
fid = 1;
fcn_DebugTools_printNumeredDirectoryList(directoryListing_allSources, cellArrayHeaders, cellArrayValues, (sourceRootOrSubroot), (fid))



%%% What numbers of files to parse?

[flag_keepGoing, indiciesSelected] = fcn_DebugTools_queryNumberRange(...
    flags_folderWasPreviouslyProcessed, (' of the hash(es) to zip'), (1), (directoryListing_allSources), (1));

%%%%
% Zip the hashes
if 1==flag_keepGoing

    Ndone = 0;
    NtoProcess = length(indiciesSelected);
    aveProcessingSpeed = 153;
    timeEstimateInSeconds = aveProcessingSpeed*NtoProcess;
    thisAveProcessingSpeed = 0;

    % Show time estimate 
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated', 'zip hashes');

    alltstart = tic;


    % Iterate through each hash table
    for ith_index = 1:NtoProcess

        ith_file = indiciesSelected(ith_index);
        Ndone = Ndone + 1;
        thisSourceFullFolderName  = sourceDirectoryFullNames{ith_file};
        % thisBytes            = directory_allHashes(ith_hashTable).bytes;


        thisSourceShortFolderName = sourceDirectoryShortNames{ith_file};
        destinationTempFolder = destinationRootOrSubroot;


        fprintf(1,'\n\nProcessing file: %d (file %d of %d)\n', ith_file, Ndone, NtoProcess);
        fprintf(1,'Initiating zip for hash table: %s\n',thisSourceShortFolderName);
        fprintf(1,'Pulling from folder: %s\n',thisSourceFullFolderName);
        fprintf(1,'Pushing to temp folder: %s\n',destinationTempFolder);

        tstart = tic;

        %%%%%%%%%%%%%%%%%%%%%%
        % Change directory?
        currentPath = cd;
        zip_executable_file = fullfile(currentPath,"7zr.exe");
        if 2~=exist(zip_executable_file,'file')
            zip_executable_file = fullfile(currentPath,'zip_code',"7zr.exe");
            if 2~=exist(zip_executable_file,'file')
                error('Unable to find folder with zip executable in it!');
            else
                cd('zip_code\')
            end
        else
            % Already inside zip_code directory. Need to update the
            % currentPath variable
            cd('..');
            currentPath = cd;
            cd('zip_code\')
        end

        % Clean out the tempZipDirectory?
        % flag_processElseWhere = 1;
        % if 1==flag_processElseWhere
        fcn_INTERNAL_clearTempZipDirectory(destinationTempFolder);
        % else
        %    destinationTempFolder = thisSourceFullFolderName;
        % end

        fprintf(1,'Processing (from 0 to F): ')
        for ith_hex = 0:15
            folderfirstCharacter = dec2hex(ith_hex);
            fprintf(1,'%s ',folderfirstCharacter);
            for jth_hex = 0:15
                foldersecondCharacter = dec2hex(jth_hex);
                folderCharacters = lower(cat(2,folderfirstCharacter,foldersecondCharacter));

                % Build the zip command string
                destinationFile = cat(2,destinationTempFolder,filesep,folderCharacters,'.7z');

                % If the zip file already exists, do NOT run commands. It
                % will overwrite and hence delete the file
                if 2~=exist(destinationFile,'file')
                    sourceFiles     = cat(2,thisSourceFullFolderName,filesep,folderCharacters,filesep);
                    zip_command = sprintf('7zr a -mx1 -t7z -mmt30 -m0=LZMA2:d64k:fb32 -ms=8m -sdel "%s" "%s"',destinationFile, sourceFiles);


                    % [status,cmdout] = system(zip_command,'-echo');
                    [status,cmdout] = system(zip_command);
                    if ~contains(cmdout,'Everything is Ok') || status~=0
                        if ~contains(cmdout,'The system cannot find the file specified.')
                            warning('on','backtrace');
                            warning('Something went wrong during zip- must debug.');
                            disp('The zip command was:');
                            disp(zip_command);
                            disp('The following results were received for cmdout:');
                            disp(cmdout);
                            disp('The following results were received for status:');
                            disp(status);
                            disp('Press any button to continue');
                            pause;
                        end
                    end
                    
                end
            end
        end

        cd(currentPath);


        if 1==flag_processElseWhere
            % Move all files into the source directory
            [status,message,messageId] = movefile(cat(2,destinationRootOrSubroot,filesep,'*.7z'),cat(2,thisSourceFullFolderName,filesep),'f');
            % Check results of move
            temp = dir(destinationRootOrSubroot);
            if length(temp)>2 || status~=1 || ~isempty(message) || ~isempty(messageId)
                warning('on','backtrace');
                warning('Unexpected error encountered when moving files!');
                fprintf(1,'Hit any key to continue\n');
                pause;
            end
        end
  
        %%%%%%%%%%%%%%%%%%%%%%%%%

        telapsed = toc(tstart); 

        % Update the average estimate for processing speeds
        thisAveProcessingSpeed = thisAveProcessingSpeed + telapsed/NtoProcess;

    end

    alltelapsed = toc(alltstart);

    % Check prediction
    fprintf(1,'\nAverage processing speed per operation: %.2f seconds',thisAveProcessingSpeed);
    fprintf(1,'\nTotal time summary: \n');
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated total', 'zip hashes');
    fcn_INTERNAL_printTimeEstimate(alltelapsed, 'Actual total', 'unzip hashes');
    fprintf(1,'\nProcess to %s complete. Check the above messages for errors.\n', 'zip hashes');
    fprintf(1,'Hit any key to continue.\n');
    pause;

end % Ends if flag_keep_going

end % Ends fcn_INTERNAL_zipHashTablesInParsed

%% fcn_INTERNAL_checkIfFolderPreviouslyZipped
function flags_folderWasPreviouslyZipped = fcn_INTERNAL_checkIfFolderPreviouslyZipped(hashFullNames)
% Find which files were previously zipped. Does this by checking the folder
% contents and counting up the entries. A hash folder that is fully zipped
% will have all entries that end in ".7z". Since the directory will also
% list '.' and '..' as entries, we check to see if all entries (e.g. the
% length minus 2) are also .7z files. Also check to make sure that at least
% one file is a zip file (e.g. the directory isn't empty).

Nfolders = length(hashFullNames);
flags_folderWasPreviouslyZipped = zeros(Nfolders,1);
for ith_folder = 1:Nfolders
    this_hash_folder = hashFullNames{ith_folder};
    hashFolderAllContents = dir(this_hash_folder);
    hashFolderZipContents = dir(cat(2,this_hash_folder,filesep,'*.7z'));

    if ~isempty(hashFolderZipContents) && length(hashFolderZipContents)==(length(hashFolderAllContents)-2)
        flags_folderWasPreviouslyZipped(ith_folder,1) = 1;
    end

end

end % Ends fcn_INTERNAL_checkIfFolderPreviouslyZipped

%% fcn_INTERNAL_checkIfFolderPreviouslyUnzipped
function flags_folderWasPreviouslyUnzipped = fcn_INTERNAL_checkIfFolderPreviouslyUnzipped(hashFullNames)
% Find which files were previously unzipped. Does this by checking the folder
% contents and counting up the entries. A hash folder that is fully
% unzipped will either have no entries that end in ".7z", or all the
% entries that end in .7z have a matching sub-directory.

Nfolders = length(hashFullNames);
flags_folderWasPreviouslyUnzipped = zeros(Nfolders,1);
for ith_folder = 1:Nfolders
    this_hash_folder = hashFullNames{ith_folder};
    hashFolderAllDirectories = dir(cat(2,this_hash_folder,filesep,'*.'));
    directoryNames = {hashFolderAllDirectories.name}';
    hashFolderZipContents = dir(cat(2,this_hash_folder,filesep,'*.7z'));

    if isempty(hashFolderZipContents) 
        flags_folderWasPreviouslyUnzipped(ith_folder,1) = 1;
    else
        % Check all the zip files against directories
        all_zip_files_exist_as_folders = zeros(length(hashFolderZipContents),1);
        for ith_zipFile = 1:length(hashFolderZipContents)
            this_zipFileName = hashFolderZipContents(ith_zipFile).name;
            directoryNameToCheck = extractBefore(this_zipFileName,'.7z');
            if any(strcmp(directoryNameToCheck,directoryNames))
                all_zip_files_exist_as_folders(ith_zipFile,1) = 1;
            end
        end

        % If all the zip files in the folder match to a subfolder, then
        % the directory has already been unzipped
        if all(all_zip_files_exist_as_folders)
            flags_folderWasPreviouslyUnzipped(ith_folder,1) = 1;
        end
    end

end

end % Ends fcn_INTERNAL_checkIfFolderPreviouslyUnzipped

%% fcn_INTERNAL_clearTempZipDirectory
function fcn_INTERNAL_clearTempZipDirectory(tempZipDirectory)
temp = dir(tempZipDirectory);
if length(temp)>2
    warning('on','backtrace');
    warning('Unexpected data in temporary working directory: %s\n Need to manually delete!',tempZipDirectory);
    fprintf(1,'Hit any key to continue\n');
    pause;

    % if length(temp)==258
    %     % Need to delete
    %     deleteCommand = cat(2,tempZipDirectory,filesep,'*.*');
    %     delete(deleteCommand);
    % else
    %     warning('Unexpected data in temporary working directory. Need to manually delete!');
    %     fprintf(1,'Hit any key to continue\n');
    %     pause;
    % end
end

end % Ends fcn_INTERNAL_clearTempZipDirectory


%% fcn_INTERNAL_unzipHashTablesInParsed
function fcn_INTERNAL_unzipHashTablesInParsed(fullParsedBagRootDefault, tempZipDirectoryDefault)
% Unzips the subdirectories in the hash tables. The tables have 256 entries
% at the primary layer (directory 00 to ff), and within each, another 256
% at the secondary layer, for a total of 256*256 = 65536 folders, each
% containing several files typically.
%
% For example, a typical data measurement "run" may have 100k to 200k
% files. If we zip these down to the primary layer with folders
% 00, 01,... 0e, 0f, 10, 11... , fe, ff
% this produces 256 files for each has table.
%
% This function uses the 7-zip (7z) compression software as the normal
% "zip" software does not handle zip files larger than 2GB, and we regularly
% encounter these in mapping. This function unzips the 256 "7z" files in
% each has folder.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _    _           _         _    _           _        _____       _         _ _               _             _
% | |  | |         (_)       | |  | |         | |      / ____|     | |       | (_)             | |           (_)
% | |  | |_ __  _____ _ __   | |__| | __ _ ___| |__   | (___  _   _| |__   __| |_ _ __ ___  ___| |_ ___  _ __ _  ___  ___
% | |  | | '_ \|_  / | '_ \  |  __  |/ _` / __| '_ \   \___ \| | | | '_ \ / _` | | '__/ _ \/ __| __/ _ \| '__| |/ _ \/ __|
% | |__| | | | |/ /| | |_) | | |  | | (_| \__ \ | | |  ____) | |_| | |_) | (_| | | | |  __/ (__| || (_) | |  | |  __/\__ \
%  \____/|_| |_/___|_| .__/  |_|  |_|\__,_|___/_| |_| |_____/ \__,_|_.__/ \__,_|_|_|  \___|\___|\__\___/|_|  |_|\___||___/
%                    | |
%                    |_|
% http://patorjk.com/software/taag/#p=display&f=Big&t=Unzip%20Hash%20Subdirectories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flag_processElseWhere = 1; % set to 1 if process the zip files elsewhere. This setting to "1" is preferred, but requires caution

%% Define the root folder to look for hashes
fullParsedBagRootDirectory = uigetdir(fullParsedBagRootDefault,'Select a folder that should be searched, including its subdirectories, for zipped hash tables.');
% If the user hits cancel, it returns 0
if 0==fullParsedBagRootDirectory
    return;
end
% Make sure folders exist!
fcn_INTERNAL_confirmDirectoryExists(fullParsedBagRootDirectory,1);

%% Define a temporary location to work out of, for zip files
if 1==flag_processElseWhere
    tempZipDirectory = uigetdir(tempZipDirectoryDefault,'Select a folder to hold temporary unzipped files during the process. These files may be up to 20GB.');
    % If the user hits cancel, it returns 0
    if 0==tempZipDirectory
        return;
    end
    % Make sure folders exist!
    fcn_INTERNAL_confirmDirectoryExists(tempZipDirectory,1);
end


%% Query the hash tables available for zip within parsed directory
flag_fileOrDirectory = 1; % Look for only directories
directory_allVelodyneHashes = fcn_ParseRaw_listDirectoryContents({fullParsedBagRootDirectory}, 'hashVelodyne_*', (flag_fileOrDirectory), (-1));
directory_allCamerasHashes = fcn_ParseRaw_listDirectoryContents({fullParsedBagRootDirectory}, 'hashCameras_*', (flag_fileOrDirectory), (-1));
directory_allOusterO1Hashes = fcn_ParseRaw_listDirectoryContents({fullParsedBagRootDirectory}, 'hashOusterO1_*', (flag_fileOrDirectory), (-1));
directory_allHashes = [directory_allVelodyneHashes; directory_allCamerasHashes; directory_allOusterO1Hashes];

fprintf(1,'\n\nFound %.0f hash folders in the parsed data folder: %s\n',length(directory_allHashes), fullParsedBagRootDirectory);
fprintf(1,'\t hashVelodyne_ data had: %.0f hashes\n',length(directory_allVelodyneHashes));
fprintf(1,'\t hashCameras_ data had:  %.0f hashes\n',length(directory_allCamerasHashes));
fprintf(1,'\t hashOusterO1_ data had: %.0f hashes\n',length(directory_allOusterO1Hashes));
if 1==0
    % Print the results?
    fcn_DebugTools_printDirectoryListing(directory_allHashes, ([]), ([]), (1));
end

%% Extract all the file names for the types of files to process
[hashFullNames, hashShortNames] = ...
    fcn_INTERNAL_extractFullAndShortNames(directory_allHashes, fullParsedBagRootDirectory, '');

%% Show the choices

%%%%
% Find which files were previously unzipped
flags_folderWasPreviouslyUnzipped = fcn_INTERNAL_checkIfFolderPreviouslyUnzipped(hashFullNames);

%%%%
% Print the results
NcolumnsToPrint = 2;
cellArrayHeaders = cell(NcolumnsToPrint,1);
cellArrayHeaders{1} = 'HASH FOLDER NAME                             ';
cellArrayHeaders{2} = 'ALREADY UNZIPPED?';
cellArrayValues = [hashShortNames, fcn_DebugTools_convertBinaryToYesNoStrings(flags_folderWasPreviouslyUnzipped)];
fid = 1;
fcn_DebugTools_printNumeredDirectoryList(directory_allHashes, cellArrayHeaders, cellArrayValues, (fullParsedBagRootDirectory), (fid))



%%% What numbers of files to unzip?

[flag_keepGoing, indiciesSelected] = fcn_DebugTools_queryNumberRange(flags_folderWasPreviouslyUnzipped, (' of the hash(es) to zip'), (1), (directory_allHashes), (1));

%%%%
% Unzip the hashes
if 1==flag_keepGoing

    % Change directory?
    currentPath = cd;
    zip_executable_file = fullfile(currentPath,"7zr.exe");
    if 2~=exist(zip_executable_file,'file')
        zip_executable_file = fullfile(currentPath,'zip_code',"7zr.exe");
        if 2~=exist(zip_executable_file,'file')
            error('Unable to find folder with zip executable in it!');
        else
            cd('zip_code\')
        end
    else
        % Already inside zip_code directory. Need to update the
        % currentPath variable
        cd('..');
        currentPath = cd;
        cd('zip_code\')
    end

    Ndone = 0;
    NtoProcess = length(indiciesSelected);
    aveProcessingSpeed = 94;
    timeEstimateInSeconds = aveProcessingSpeed*NtoProcess;
    thisAveProcessingSpeed = 0;

    % Show time estimate 
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated', 'unzip hashes');
    
    alltstart = tic;

    for ith_index = 1:NtoProcess

        ith_hashTable = indiciesSelected(ith_index);
        Ndone = Ndone + 1;
        sourceHashFolderName  = hashFullNames{ith_hashTable};
        % thisBytes            = directory_allHashes(ith_hashTable).bytes;


        thisFile = hashShortNames{ith_hashTable};

        % Clean out the tempZipDirectory?
        if 1==flag_processElseWhere
            destinationTempFolder = tempZipDirectory;
            fcn_INTERNAL_clearTempZipDirectory(tempZipDirectory);
        else
            destinationTempFolder = sourceHashFolderName;
        end

        fprintf(1,'\n\nProcessing file: %d (file %d of %d)\n', ith_hashTable, Ndone, NtoProcess);
        fprintf(1,'Initiating unzip for hash table: %s\n',thisFile);
        fprintf(1,'Pulling from folder: %s\n',sourceHashFolderName);
        fprintf(1,'Pushing to temp folder: %s\n',destinationTempFolder);
        fprintf(1,'Processing (from 0 to F): ')
        tstart = tic;
        for ith_hex = 0:15
            folderfirstCharacter = dec2hex(ith_hex);
            fprintf(1,'%s ',folderfirstCharacter);
            for jth_hex = 0:15
                foldersecondCharacter = dec2hex(jth_hex);
                folderCharacters = lower(cat(2,folderfirstCharacter,foldersecondCharacter));

                % if strcmp(folderCharacters,'39')
                %     disp('Stop here');
                % end

                % Build the zip command string
                sourceZipFile = cat(2, sourceHashFolderName, filesep,folderCharacters,'.7z');
                destinationFolder     = cat(2, destinationTempFolder, filesep); %,folderCharacters,filesep);
                letterFolder     = cat(2, destinationTempFolder, filesep,folderCharacters,filesep);

                % % Check to see if the source folder is empty
                % listing_command = sprintf('7zr l "%s"',sourceZipFile);
                % [status,cmdout] = system(listing_command);

                % If the letterFolder already exists, do NOT overwrite and hence
                % delete the contents. Just skip.
                if 7~=exist(letterFolder,'dir')
                    unzip_command = sprintf('7zr x "%s" -o"%s"',sourceZipFile, destinationFolder);


                    % [status,cmdout] = system(zip_command,'-echo');
                    [status,cmdout] = system(unzip_command);
                    if ~contains(cmdout,'Everything is Ok') || status~=0
                        if ~contains(cmdout,'The system cannot find the file specified.')
                            warning('on','backtrace');
                            warning('Something went wrong during unzip - must debug.');
                            disp('The unzip command was:');
                            disp(unzip_command);
                            disp('The following results were received for cmdout:');
                            disp(cmdout);
                            disp('The following results were received for status:');
                            disp(status);                            
                            disp('Press any button to continue');
                            pause;
                        end
                    end
                    if contains(cmdout,'No files to process')
                        [mkdirSuccess, mkdirMessage, mkdirMessageID] = mkdir(destinationTempFolder,folderCharacters);
                        if 1~=mkdirSuccess
                            warning('on','backtrace');
                            warning('Something went wrong during directory creation of %s within root folder %s. Message received is:\n %s \n with messageID: %s.',folderCharacters, destinationTempFolder, mkdirMessage, mkdirMessageID)
                        end
                    end
                end
            end
        end
        telapsed = toc(tstart); 

        % Update the average estimate for processing speeds
        thisAveProcessingSpeed = thisAveProcessingSpeed + telapsed/NtoProcess;

        if 1==flag_processElseWhere

            % Now delete zip files, safely
            % For each zip file in the destination folder, make sure
            % there is a matching folder with the same name.
            flag_allFound = 1;
            hashFolderZipContents = dir(cat(2,sourceHashFolderName,filesep,'*.7z'));
            for ith_zip = 1:length(hashFolderZipContents)
                thisZipFullName = hashFolderZipContents(ith_zip).name;
                thisZipName = thisZipFullName(1:2);
                expectedFolder = fullfile(destinationTempFolder,thisZipName);
                if 7~=exist(expectedFolder,'dir')
                    flag_allFound = 0;
                    warning('on','backtrace');
                    warning('Zip file %s is directory %s does not have an associated unzipped folder! The unzip process will be stopped without moving unzip folders. Check the temporary file location to debug.',thisZipFullName, sourceHashFolderName);
                    pause;

                end
            end

            if 1==flag_allFound
                % Move all files into the source directory
                fprintf(1, '... Moving files from temp processing back to source...');
                [status,message,messageId] = movefile(cat(2,tempZipDirectory,filesep,'*.*'),cat(2,sourceHashFolderName,filesep),'f');
                fprintf(1,'Done! \n');
                % Check results of move
                temp = dir(tempZipDirectory);
                if length(temp)>2 || status~=1 || ~isempty(message) || ~isempty(messageId)
                    warning('on','backtrace');
                    warning('Unexpected error encountered when moving files!');
                    fprintf(1,'Hit any key to continue\n');
                    pause;
                end

                % flags_folderWasPreviouslyUnzipped = fcn_INTERNAL_checkIfFolderPreviouslyUnzipped(hashFullNames)
                
            end
        end

    end

    alltelapsed = toc(alltstart);

    % Check prediction
    fprintf(1,'\nAverage processing speed per operation: %.2f seconds',thisAveProcessingSpeed);
    fprintf(1,'\nTotal time summary: \n');
    fcn_INTERNAL_printTimeEstimate(timeEstimateInSeconds, 'Estimated total', 'unzip hashes');
    fcn_INTERNAL_printTimeEstimate(alltelapsed, 'Actual total', 'unzip hashes');
    fprintf(1,'\nProcess to %s complete. Check the above messages for errors.\n', 'unzip hashes');
    fprintf(1,'Hit any key to continue.\n');
    pause;

    cd(currentPath);
end

end % Ends fcn_INTERNAL_unzipHashTablesInParsed


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
fcn_INTERNAL_confirmDirectoryExists(sourceRootOrSubroot,1);
fcn_INTERNAL_confirmDirectoryExists(destinationRootOrSubroot,1);


%% Step 2: Query which of the sources were already processed into the destinations
if ~strcmp(stringSourceQuery,'hash')
    directoryListing_allSources = fcn_ParseRaw_listDirectoryContents(...
        {sourceRootOrSubroot}, stringSourceQuery, (flag_sourceIsFileOrDirectory), (-1));

    % Summarize results
    fprintf(1,['\n\nFound %.0f source data folders/files in the following \n ' ...
        'data folder (and its subfolders): \n\t%s\n'],length(directoryListing_allSources), sourceRootOrSubroot);
else

    directory_allVelodyneHashes = fcn_ParseRaw_listDirectoryContents(...
        {sourceRootOrSubroot}, 'hashVelodyne_*', (flag_sourceIsFileOrDirectory), (-1));
    directory_allCamerasHashes = fcn_ParseRaw_listDirectoryContents(...
        {sourceRootOrSubroot}, 'hashCameras_*', (flag_sourceIsFileOrDirectory), (-1));
    directory_allOusterO1Hashes = fcn_ParseRaw_listDirectoryContents(...
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

if strcmp(oneStepCommand,'zip hash files')
    flags_folderWasPreviouslyProcessed = fcn_INTERNAL_checkIfFolderPreviouslyZipped(sourceDirectoryFullNames);
    goodDirectories = directoryListing_allSources;
elseif strcmp(oneStepCommand,'merge MAT files')
    %%%%%
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
    [sourceDirectoryFullNames, sourceDirectoryShortNames, sourceFileNames, sourceBytes, goodDirectories] = ...
    fcn_INTERNAL_extractFullAndShortNames(mergingSourceDirectoryListing, sourceRootOrSubroot, ''); %#ok<ASGLU>
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
                fcn_INTERNAL_zipHashFiles(thisSourceFullFolderName, destinationRootOrSubroot)                
            case 'create MAT files'
                fcn_INTERNAL_produceOneMatFile(thisSourceFullFolderName, thisDestinationFolder)
            case 'create FIG and PNG files'
                fcn_INTERNAL_produceOneFigFile(thisSourceFullFolderName, thisDestinationFolder)
            case 'merge MAT files'
                fcn_INTERNAL_produceOneMerge(thisSourceFullFolderName, thisDestinationFolder)                
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
flagDirectoryExists = fcn_INTERNAL_confirmDirectoryExists(directoryString,0);
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

cellArrayOfFullNames  = cell(length(queryFolders),1);
cellArrayOfShortNames = cell(length(queryFolders),1);
cellArrayOfFileNames  = cell(length(queryFolders),1);
for ith_name = 1:length(queryNames)
    fullDirectoryName = cat(2,queryFolders{ith_name},filesep,queryNames{ith_name});
    cellArrayOfFullNames{ith_name}  = fullDirectoryName;
    cellArrayOfShortNames{ith_name} = extractAfter(fullDirectoryName,directoryStub);
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



%% fcn_INTERNAL_zipHashFiles
function fcn_INTERNAL_zipHashFiles(thisSourceFullFolderName, destinationRootOrSubroot)


%%%%%%%%%%%%%%%%%%%%%%
% Change directory?
currentPath = cd;
zip_executable_file = fullfile(currentPath,"7zr.exe");
if 2~=exist(zip_executable_file,'file')
    zip_executable_file = fullfile(currentPath,'zip_code',"7zr.exe");
    if 2~=exist(zip_executable_file,'file')
        error('Unable to find folder with zip executable in it!');
    else
        cd('zip_code\')
    end
else
    % Already inside zip_code directory. Need to update the
    % currentPath variable
    cd('..');
    currentPath = cd;
    cd('zip_code\')
end

%%%%%%%%%%%%%%%%%%%%%%
% Clean out the tempZipDirectory?
% flag_processElseWhere = 1;
% if 1==flag_processElseWhere
destinationTempFolder = destinationRootOrSubroot;
fcn_INTERNAL_clearTempZipDirectory(destinationRootOrSubroot);
% else
%    destinationTempFolder = thisSourceFullFolderName;
% end

%%%%%%%%%%%%%%%%%%%%%%
% Process data
fprintf(1,'Processing (from 0 to F): ')
for ith_hex = 0:15
    folderfirstCharacter = dec2hex(ith_hex);
    fprintf(1,'%s ',folderfirstCharacter);
    for jth_hex = 0:15
        foldersecondCharacter = dec2hex(jth_hex);
        folderCharacters = lower(cat(2,folderfirstCharacter,foldersecondCharacter));

        % Build the zip command string
        destinationFile = cat(2,destinationTempFolder,filesep,folderCharacters,'.7z');

        % If the zip file already exists, do NOT run commands. It
        % will overwrite and hence delete the file
        if 2~=exist(destinationFile,'file')
            sourceFiles     = cat(2,thisSourceFullFolderName,filesep,folderCharacters,filesep);
            zip_command = sprintf('7zr a -mx1 -t7z -mmt30 -m0=LZMA2:d64k:fb32 -ms=8m -sdel "%s" "%s"',destinationFile, sourceFiles);


            % [status,cmdout] = system(zip_command,'-echo');
            [status,cmdout] = system(zip_command);
            if ~contains(cmdout,'Everything is Ok') || status~=0
                if ~contains(cmdout,'The system cannot find the file specified.')
                    warning('on','backtrace');
                    warning('Something went wrong during zip- must debug.');
                    disp('The zip command was:');
                    disp(zip_command);
                    disp('The following results were received for cmdout:');
                    disp(cmdout);
                    disp('The following results were received for status:');
                    disp(status);
                    disp('Press any button to continue');
                    pause;
                end
            end

        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%
% Go back to home directory
cd(currentPath);

%%%%%%%%%%%%%%%%%%%%%%
% Move results
if 1==1 %if 1==flag_processElseWhere
    % Move all files into the source directory
    [status,message,messageId] = movefile(cat(2,destinationRootOrSubroot,filesep,'*.7z'),cat(2,thisSourceFullFolderName,filesep),'f');
    % Check results of move
    temp = dir(destinationRootOrSubroot);
    if length(temp)>2 || status~=1 || ~isempty(message) || ~isempty(messageId)
        warning('on','backtrace');
        warning('Unexpected error encountered when moving files!');
        fprintf(1,'Hit any key to continue\n');
        pause;
    end
end
end % Ends fcn_INTERNAL_zipHashFiles

%% fcn_INTERNAL_produceOneMatFile
function fcn_INTERNAL_produceOneMatFile(thisSourceFullFolderName, thisDestinationFolder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAT FILE CREATION BEGINS HERE
% Prep inputs to call the data loading function
% FORMAT:
%      rawDataCellArray = fcn_LoadRawDataToMATLAB_loadRawDataFromDirectories(...
%      rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (figNum))

% Define rootdirs. This is the folder UNDER the bag name
lastFileSep = find(thisSourceFullFolderName==filesep,1,'last');
thisRoot    = thisSourceFullFolderName(1:lastFileSep);
thisBagFile = thisSourceFullFolderName(lastFileSep+1:end);

clear rootdirs
rootdirs{1} = thisRoot;

% Define Identifiers
% {'C:\MappingVanData\ParsedMATLAB_PoseOnly\RawData\TestTrack\BaseMap\2024-08-13\mapping_van_2024-08-13-16-03-10_0\mapping_van_2024-08-13-16-03-10_0.mat'
directoryEndingInDate = extractBefore(thisSourceFullFolderName,cat(2,filesep,'mapping_van_'));
lastFileSep = find(directoryEndingInDate==filesep,1,'last');
mappingDate = directoryEndingInDate(lastFileSep+1:end);

directoryEndingInScenario = extractBefore(directoryEndingInDate,cat(2,filesep,mappingDate));
lastFileSep = find(directoryEndingInScenario==filesep,1,'last');
scenarioString = directoryEndingInScenario(lastFileSep+1:end);

% Grab the identifiers. NOTE: this also sets the reference location for
% plotting.
Identifiers = fcn_LoadRawDataToMATLAB_identifyDataByScenarioDate(scenarioString, mappingDate, 1,-1);

bagQueryString = thisBagFile;
fid = 1;
Flags = [];

rawDataCellArray = fcn_LoadRawDataToMATLAB_loadRawDataFromDirectories(...
    rootdirs, Identifiers, (bagQueryString), (fid), (Flags), (-1));
rawDataCellArray{1}.Identifiers.SourceBagFileName = cat(2,thisBagFile,'.bag');

%%%%%%%%%%%%%%%%%%%%%%%
% Save the data

% List what will be saved
clear saveFlags
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceMATfileOverwrite = 1;

% Call function
fcn_LoadRawDataToMATLAB_saveRawDataMatFiles(rawDataCellArray, {thisDestinationFolder}, (saveFlags))

%%%%%%%%%%%

end % Ends fcn_INTERNAL_produceOneMatFile


%% fcn_INTERNAL_produceOneFigFile
function fcn_INTERNAL_produceOneFigFile(thisSourceFullFolderName, thisDestinationFolder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIG CREATION BEGINS HERE
% Prep inputs to call the MAT file loading function
% FORMAT:
% rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(...
%     rootdirs, (searchIdentifiers), (matQueryString), (fid), (figNum));

% Define rootdirs. This is the folder UNDER the bag name
% sourceLastFileSep = find(thisSourceFullFolderName==filesep,1,'last');
% sourceRoot    = thisSourceFullFolderName(1:sourceLastFileSep);
% sourceMatFile = thisSourceFullFolderName(sourceLastFileSep+1:end);

clear rootdirs
rootdirs{1} = thisSourceFullFolderName;
searchIdentifiers = [];
matQueryString = '*.mat';
fid = 1;

rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(...
    rootdirs, (searchIdentifiers), (matQueryString), (fid), (-1));

%%%%%%%%%%%%%%%%%%%%%%%
% Plot the data

destinationLastFileSep = find(thisDestinationFolder==filesep,1,'last');
destinationFigFile = thisDestinationFolder(destinationLastFileSep+1:end);

% Set the plotting origin
scenarioString = rawDataCellArray{1}.Identifiers.WorkZoneScenario;
fcn_LoadRawDataToMATLAB_identifyDataByScenarioDate(scenarioString, [], ([]), (-1));

% List what will be saved
clear saveFlags
saveFlags.flag_saveImages = 1;
saveFlags.flag_saveImages_directory  = thisDestinationFolder;
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceImageOverwrite = 1;

% List what will be plotted, and the figure numbers
clear plotFlags
if contains(destinationFigFile,'mapping_van_')
    plotFlags.fig_num_plotAllRawTogether = [];
    plotFlags.fig_num_plotAllRawIndividually = 100;
else
    plotFlags.fig_num_plotAllRawTogether = 1;
    plotFlags.fig_num_plotAllRawIndividually = [];
end
% Call function to plot data, and save plots into file formats
fcn_LoadRawDataToMATLAB_plotRawDataPositions(rawDataCellArray, (saveFlags), (plotFlags));
%%%%%%%%%%%

end % Ends fcn_INTERNAL_produceOneFigFile

%% fcn_INTERNAL_produceOneMerge
function fcn_INTERNAL_produceOneMerge(thisSourceFolderName, thisDestinationFolder)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA FOR MERGING
% Prep inputs to call the MAT file loading function
% FORMAT:
% rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(...
%     rootdirs, (searchIdentifiers), (matQueryString), (fid), (figNum));

clear rootdirs
rootdirs{1} = thisSourceFolderName;
searchIdentifiers = [];
matQueryString = '*.mat';
fid = 1;

rawDataCellArray = fcn_LoadRawDataToMATLAB_loadMatDataFromDirectories(...
    rootdirs, (searchIdentifiers), (matQueryString), (fid), (-1));

%%%%%%%%%%%%%%%%%%%%%%%
% MERGE THE DATA
% Prepare for merging
% Specify the nearby time
thresholdTimeNearby = 10;

% Spedify the fid
fid = 1; % 1 --> print to console
% consoleFname = fullfile(cd,'Data','RawDataMerged',Identifiers.ProjectStage,Identifiers.WorkZoneScenario,'MergeProcessingMessages.txt');
% fid = fopen(consoleFname,'w');

% Call the function
[mergedRawDataCellArray, ~] = ...
    fcn_LoadRawDataToMATLAB_mergeRawDataStructures(rawDataCellArray, ...
    (thresholdTimeNearby), (fid), (-1));

%%%%%%%%%%%%%%%%%%%%%%%
% SAVE THE MERGED DATA
Ndatasets = length(mergedRawDataCellArray);
destinationFolderCellArray = cell(Ndatasets,1);
destinationFolderCellArray(:) = {thisDestinationFolder};

% Set flags on how to save
clear saveFlags
saveFlags.flag_forceDirectoryCreation = 1;
saveFlags.flag_forceMATfileOverwrite = 1;

% Call function
fcn_LoadRawDataToMATLAB_saveRawDataMatFiles(mergedRawDataCellArray, destinationFolderCellArray, (saveFlags))

%%%%%%%%%%%

end % Ends fcn_INTERNAL_produceOneMerge
