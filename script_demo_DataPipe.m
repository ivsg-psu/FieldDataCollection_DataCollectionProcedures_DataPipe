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
%
% 2025_12_13 by Sean Brennan, sbrennan@psu.edu
% - added unzip operations to menu 
% - moved fcn_INTERNAL_clearTempZipDirectory to external function
%   % * Now fcn_DataPipe_zippingClearTempZipDirectory
% - deprecated fcn_INTERNAL_unzipHashTablesInParsed by converting it to
%   % unzip menu option
% - moved fcn_INTERNAL_confirmDirectoryExists to external function
%   % * Now fcn_DataPipe_helperConfirmDirectoryExists
% - moved fcn_INTERNAL_checkIfFilesStaged to external function
%   % * Now fcn_DataPipe_parsingCheckIfFilesStaged
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
% - moved fcn_INTERNAL_stageUnsortedBagFoldersForCopyIntoRawBags to external function
%   % * Now fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy
% - moved fcn_INTERNAL_measureParsingSpeed to external function
%   % * Now fcn_DataPipe_parsingMeasureParsingSpeed
% - moved fcn_INTERNAL_parseBagsInRawBags to external function
%   % * Now fcn_DataPipe_parsingParseBagsInRawBags
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
% - moved fcn_INTERNAL_checkIfFolderPreviouslyZipped to external function
%   % * Now fcn_DataPipe_zippingCheckIfFolderPreviouslyZipped
% - moved fcn_INTERNAL_checkIfFolderPreviouslyUnzipped to external function
%   % * Now fcn_DataPipe_zippingCheckIfFolderPreviouslyUnzipped
%
% 2025_12_16 by Sean Brennan, sbrennan@psu.edu
% - moved fcn_INTERNAL_produceOneMerge to external function
%   % * Now fcn_DataPipe_processOneMerge
% - moved fcn_INTERNAL_produceOneFigFile to external function
%   % * Now fcn_DataPipe_processOneFigFile
% - moved fcn_INTERNAL_produceOneMatFile to external function
%   % * Now fcn_DataPipe_processOneMatFile
% - moved fcn_INTERNAL_unzipOneFile to external function
%   % * Now fcn_DataPipe_processOneUnzipFolder
% - moved fcn_INTERNAL_zipHashFiles to external function
%   % * Now fcn_DataPipe_processOneZipOfHashFolders
% - moved main menu out of this demo script
%   % * Now fcn_DataPipe_mainDataPipeMenu

%%%%%
% Known issues:
% 
% 2025_06_19 - Aneesh Batchu
% -- For macs, Volumes can be found by doing: dir("/Volumes")

%%%%
% TO_DO:
% 2025_12_03 by Sean Brennan, sbrennan@psu.edu
% - need to functionalize the main menu, suggest DataPipe_mainDataPipeMenu
% - need to add timeclean operations


%% Prep the workspace
close all

%% Make sure we are running out of root directory
st = dbstack; 
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% Clear paths and folders, if needed
if 1==0
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
