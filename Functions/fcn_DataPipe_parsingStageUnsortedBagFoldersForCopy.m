function fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy(directoryUnsortedBags, directoryStaging, varargin)
%% fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy
% Finds all bag files in a given directory, sorts them by time, prints
% listings into README, and moves files into "date" folder
%
% The purpose of this function is to repare bag files, README, etc. for
% copy into archival storage. The readme includes file listings organized
% by date/time, and sub-folders. These prepared files are NOT automatically
% moved into the MappingVanData folders because this is dangerious
% (overwrite!). Rather, this function prepares the files for move and
% requires the user to manually do the move after this step is done.
%
% The input to this is a directory containing files that are usually
% captured directly from the mapping van and stored in a "ReadyToParse"
% area with subfolders indicating details about the test, for example "Lane
% 1 CCW with cameras". It then produces a README file whose subsections
% each list the directory names (as details) and the files within, all in
% time-ordered sequence. It then moves all the files into a date-organized
% folder for the test so that the files can be moved into the organized and
% permanent raw bag file storage area.
%
% FORMAT:
%
%      fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy(directoryUnsortedBags, directoryStaging, (figNum));
%
% INPUTS:
%
%      directoryUnsortedBags: a string containing the path of the 
%      directory containing the unsorted bags.
%
%      directoryStaging: a string containing the path of the 
%      directory containing the staged bags.
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
%     See the script: script_test_fcn_DataPipe_parsingStageUnsortedBagFoldersForCopy
%     for a full test suite.
%
% This version of the function was written on 2025_12_14 by S. Brennan
% Questions or comments? sbrennan@psu.edu


% REVISION HISTORY:
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
% - wrote the code originally, pulling code out of DataPipe demo

% TO-DO:
%
% 2025_12_14 by Sean Brennan, sbrennan@psu.edu
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

        % % Check the directoryUnsortedBags to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(directoryUnsortedBags, 'DoesDirectoryExist');
        % 
        % % Check the directoryStaging to be sure it is an existing
        % % directory
        % fcn_DebugTools_checkInputsToFunctions(directoryStaging, 'DoesDirectoryExist');

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

warning('backtrace','on');
warning('This function has not yet been tested, nor has a test script been finished. Use this function with caution and expect some bug fixing to be required.')

fig_num = [];

% Make sure folders exist!
fcn_DataPipe_helperConfirmDirectoryExists(directoryUnsortedBags, (1), (-1));
fcn_DataPipe_helperConfirmDirectoryExists(directoryStaging, (1), (-1));

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
