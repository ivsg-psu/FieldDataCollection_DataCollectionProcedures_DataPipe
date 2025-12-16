function fcn_DataPipe_processOneUnzipFolder(thisSourceFullFolderName, destinationRootOrSubroot, varargin)
%% fcn_DataPipe_processOneUnzipFolder
% Unzips all zip files in a zipped hash folder
%
% FORMAT:
%
%      fcn_DataPipe_processOneUnzipFolder(thisSourceFullFolderName, destinationRootOrSubroot, (figNum));
%
% INPUTS:
%
%      thisSourceFullFolderName: a string containing the path of the 
%      directory containing the unmerged mat files.
%
%      destinationRootOrSubroot: a string containing the path of the 
%      directory where the merged mat files should be placed
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
%     fcn_DataPipe_zippingClearTempZipDirectory
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataPipe_processOneUnzipFolder
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

        % Check the directorySourceRawBags to be sure it is an existing
        % directory
        fcn_DebugTools_checkInputsToFunctions(thisSourceFullFolderName, 'DoesDirectoryExist');

        % % Check the directoryDestinationParsedBags_PoseOnly to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(destinationRootOrSubroot, 'DoesDirectoryExist');

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

% flag_processElseWhere = 1;

sourceHashFolderName = thisSourceFullFolderName;

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


% (OLD)
%%%%%%%%%%%%%%%%%%%%%%
% Clean out the tempZipDirectory?
% flag_processElseWhere = 1;
% if 1==flag_processElseWhere
destinationTempFolder = destinationRootOrSubroot;
fcn_DataPipe_zippingClearTempZipDirectory(destinationRootOrSubroot, (-1))
% else
%    destinationTempFolder = thisSourceFullFolderName;
% end
% (END OLD)



%%%%%%%%%%%%%%%%%%%%%%
% Process data
fprintf(1,'Processing (from 0 to F): ')
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

%%%%%%%%%%%%%%%%%%%%%%
% Go back to home directory
cd(currentPath);

%%%%%%%%%%%%%%%%%%%%%%
% Move results
if 1==1 %if 1==flag_processElseWhere
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
        [status,message,messageId] = movefile(cat(2,destinationRootOrSubroot,filesep,'*.*'),cat(2,sourceHashFolderName,filesep),'f');
        fprintf(1,'Done! \n');
        % Check results of move
        temp = dir(destinationRootOrSubroot);
        if length(temp)>2 || status~=1 || ~isempty(message) || ~isempty(messageId)
            warning('on','backtrace');
            warning('Unexpected error encountered when moving files!');
            fprintf(1,'Hit any key to continue\n');
            pause;
        end

        % flags_folderWasPreviouslyUnzipped = fcn_DataPipe_zippingCheckIfFolderPreviouslyUnzipped(hashFullNames)
    end
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
