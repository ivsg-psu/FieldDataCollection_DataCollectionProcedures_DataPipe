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
directory_allVelodyneHashes = fcn_DebugTools_listDirectoryContents({sourceRootOrSubroot}, 'hashVelodyne_*', (flag_sourceIsFileOrDirectory), (-1));
directory_allCamerasHashes = fcn_DebugTools_listDirectoryContents({sourceRootOrSubroot}, 'hashCameras_*', (flag_sourceIsFileOrDirectory), (-1));
directory_allOusterO1Hashes = fcn_DebugTools_listDirectoryContents({sourceRootOrSubroot}, 'hashOusterO1_*', (flag_sourceIsFileOrDirectory), (-1));
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