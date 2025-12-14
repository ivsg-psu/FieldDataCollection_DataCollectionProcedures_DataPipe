%% fcn_INTERNAL_unzipHashTablesInParsedda
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
directory_allVelodyneHashes = fcn_DebugTools_listDirectoryContents({fullParsedBagRootDirectory}, 'hashVelodyne_*', (flag_fileOrDirectory), (-1));
directory_allCamerasHashes = fcn_DebugTools_listDirectoryContents({fullParsedBagRootDirectory}, 'hashCameras_*', (flag_fileOrDirectory), (-1));
directory_allOusterO1Hashes = fcn_DebugTools_listDirectoryContents({fullParsedBagRootDirectory}, 'hashOusterO1_*', (flag_fileOrDirectory), (-1));
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

    % % Change directory?
    % currentPath = cd;
    % zip_executable_file = fullfile(currentPath,"7zr.exe");
    % if 2~=exist(zip_executable_file,'file')
    %     zip_executable_file = fullfile(currentPath,'zip_code',"7zr.exe");
    %     if 2~=exist(zip_executable_file,'file')
    %         error('Unable to find folder with zip executable in it!');
    %     else
    %         cd('zip_code\')
    %     end
    % else
    %     % Already inside zip_code directory. Need to update the
    %     % currentPath variable
    %     cd('..');
    %     currentPath = cd;
    %     cd('zip_code\')
    % end

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

        % % Clean out the tempZipDirectory?
        % if 1==flag_processElseWhere
        %     destinationTempFolder = tempZipDirectory;
        %     fcn_DataPipe_zippingClearTempZipDirectory(tempZipDirectory, (-1))
        % else
        %     destinationTempFolder = sourceHashFolderName;
        % end

        fprintf(1,'\n\nProcessing file: %d (file %d of %d)\n', ith_hashTable, Ndone, NtoProcess);
        fprintf(1,'Initiating unzip for hash table: %s\n',thisFile);
        fprintf(1,'Pulling from folder: %s\n',sourceHashFolderName);
        fprintf(1,'Pushing to temp folder: %s\n',destinationTempFolder);
        
        
        % fprintf(1,'Processing (from 0 to F): ')
        % tstart = tic;
        % for ith_hex = 0:15
        %     folderfirstCharacter = dec2hex(ith_hex);
        %     fprintf(1,'%s ',folderfirstCharacter);
        %     for jth_hex = 0:15
        %         foldersecondCharacter = dec2hex(jth_hex);
        %         folderCharacters = lower(cat(2,folderfirstCharacter,foldersecondCharacter));
        % 
        %         % if strcmp(folderCharacters,'39')
        %         %     disp('Stop here');
        %         % end
        % 
        %         % Build the zip command string
        %         sourceZipFile = cat(2, sourceHashFolderName, filesep,folderCharacters,'.7z');
        %         destinationFolder     = cat(2, destinationTempFolder, filesep); %,folderCharacters,filesep);
        %         letterFolder     = cat(2, destinationTempFolder, filesep,folderCharacters,filesep);
        % 
        %         % % Check to see if the source folder is empty
        %         % listing_command = sprintf('7zr l "%s"',sourceZipFile);
        %         % [status,cmdout] = system(listing_command);
        % 
        %         % If the letterFolder already exists, do NOT overwrite and hence
        %         % delete the contents. Just skip.
        %         if 7~=exist(letterFolder,'dir')
        %             unzip_command = sprintf('7zr x "%s" -o"%s"',sourceZipFile, destinationFolder);
        % 
        % 
        %             % [status,cmdout] = system(zip_command,'-echo');
        %             [status,cmdout] = system(unzip_command);
        %             if ~contains(cmdout,'Everything is Ok') || status~=0
        %                 if ~contains(cmdout,'The system cannot find the file specified.')
        %                     warning('on','backtrace');
        %                     warning('Something went wrong during unzip - must debug.');
        %                     disp('The unzip command was:');
        %                     disp(unzip_command);
        %                     disp('The following results were received for cmdout:');
        %                     disp(cmdout);
        %                     disp('The following results were received for status:');
        %                     disp(status);                            
        %                     disp('Press any button to continue');
        %                     pause;
        %                 end
        %             end
        %             if contains(cmdout,'No files to process')
        %                 [mkdirSuccess, mkdirMessage, mkdirMessageID] = mkdir(destinationTempFolder,folderCharacters);
        %                 if 1~=mkdirSuccess
        %                     warning('on','backtrace');
        %                     warning('Something went wrong during directory creation of %s within root folder %s. Message received is:\n %s \n with messageID: %s.',folderCharacters, destinationTempFolder, mkdirMessage, mkdirMessageID)
        %                 end
        %             end
        %         end
        %     end
        % end
        % telapsed = toc(tstart); 
        % 
        % % Update the average estimate for processing speeds
        % thisAveProcessingSpeed = thisAveProcessingSpeed + telapsed/NtoProcess;

        % if 1==flag_processElseWhere
        % 
        %     % Now delete zip files, safely
        %     % For each zip file in the destination folder, make sure
        %     % there is a matching folder with the same name.
        %     flag_allFound = 1;
        %     hashFolderZipContents = dir(cat(2,sourceHashFolderName,filesep,'*.7z'));
        %     for ith_zip = 1:length(hashFolderZipContents)
        %         thisZipFullName = hashFolderZipContents(ith_zip).name;
        %         thisZipName = thisZipFullName(1:2);
        %         expectedFolder = fullfile(destinationTempFolder,thisZipName);
        %         if 7~=exist(expectedFolder,'dir')
        %             flag_allFound = 0;
        %             warning('on','backtrace');
        %             warning('Zip file %s is directory %s does not have an associated unzipped folder! The unzip process will be stopped without moving unzip folders. Check the temporary file location to debug.',thisZipFullName, sourceHashFolderName);
        %             pause;
        % 
        %         end
        %     end
        % 
        %     if 1==flag_allFound
        %         % Move all files into the source directory
        %         fprintf(1, '... Moving files from temp processing back to source...');
        %         [status,message,messageId] = movefile(cat(2,tempZipDirectory,filesep,'*.*'),cat(2,sourceHashFolderName,filesep),'f');
        %         fprintf(1,'Done! \n');
        %         % Check results of move
        %         temp = dir(tempZipDirectory);
        %         if length(temp)>2 || status~=1 || ~isempty(message) || ~isempty(messageId)
        %             warning('on','backtrace');
        %             warning('Unexpected error encountered when moving files!');
        %             fprintf(1,'Hit any key to continue\n');
        %             pause;
        %         end
        % 
        %         % flags_folderWasPreviouslyUnzipped = fcn_INTERNAL_checkIfFolderPreviouslyUnzipped(hashFullNames)
        % 
        %     end
        % end

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

    % cd(currentPath);
end

end % Ends fcn_INTERNAL_unzipHashTablesInParsed