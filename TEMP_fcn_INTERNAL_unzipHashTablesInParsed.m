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

% 


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