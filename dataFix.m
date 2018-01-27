function [table15min tableHour tableDay theTableOriginal dateGapIndexes] = dataFix(station)
% THE DATA SHOULD BE RECORDED AT APPROXIMATELY 15 MIN TIME RESOLUTION
% station - this should be a table data type
% HEADER ----> STATION TABLE
% TimeStampCounter - Device - L1 - L2 - ... - L{N} - Sum of Feeders
%
% By L1 - L{N}... for N feeders connected to the same transformer

% filename = 'SALVADOR_VRY.LANGS-1.csv';  % - NO SOLAR PROBABLY - RESIDENTIAL
% station = readtable(filename);

if ~istable(station)
    table15min = [];
    tableHour = [];
    tableDay = [];
    disp('The table should be timetable type');
    return
end

% Read raw data from the .csv file that its in the "station" variable.
station = table2timetable(station(:,3:end));
[dateCount,feeders] = size(station);


%% REMOVE MISSING ENTRIES AND SORT ROWS
% Entries with incomplete data are removed from the analysis

missingCount = sum(sum(ismissing(station)));
disp(['Total entries available: ' num2str(dateCount)]);
disp(['Missing entries removed: ' num2str(missingCount)]);

station = rmmissing(station); % Remove missing entries
station = sortrows(station);  % Sort by date
[dateCount,feeders] = size(station);


%% RENAME VARIABLE NAMES
% The original table variable names registries for each DALI box,
% This section will rename the variables for a more generic format

powerData = station.Variables;
dateValues = station.date;

powerLabels = {'SumPhases'; 'L1'; 'L2'; 'L3'; 'L4'; 'L5'; 'L6'; 'L7'; 'L8';'L9';'L10';'L11'};
labelFeeder = vertcat(powerLabels(2:feeders),powerLabels(1));
theTable = array2timetable(powerData,'RowTimes',dateValues,'VariableNames', labelFeeder(1:feeders));
theTableOriginal = theTable;

%% REMOVE DUPLICATE ROWS
% Time stamps that are the same are removed (first time stamp lasts)
uniqueTimes = unique(theTable.Time);
theTable = retime(theTable,uniqueTimes);


% ==============================================================================================
%% FILLING MISSING DATA
% This section will create a time table with exactly 15 min resolution
% it will eliminate minor glitches in the data time stamp.
%
% Also, this section will detect if there is more that 3 hours of missing data,
% in the case it exist, it will label the section as irreparable. In the
% case that is less than 3 hours, the retiming will be done using mean
% value. This option can be changed to see results

gapThreshold = [2 0 0];  % Threshold [hh mm ss] / hours minutes seconds
missingGap = unique(diff(theTable.Time));
missingGap = missingGap(missingGap > duration(gapThreshold));

gapIndexes = [];
for i=1:length(missingGap)
    numero = find(diff(theTable.Time)== missingGap(i));
    gapIndexes = [gapIndexes; numero];
end

% Detecting and reporting the gap holes that won't be fixed
dateGapIndexes = [];
disp('THE FOLLOWING TIME GAPS WILL NOT BE FIXED:');
for i=1:length(gapIndexes)
    dateGapIndexes = [dateGapIndexes; theTable.Time(gapIndexes(i)) ...
                                      theTable.Time(gapIndexes(i)+1)]; 
    disp(['Missing data from: ' datestr(theTable.Time(gapIndexes(i))) ' to ' ...
                               datestr(theTable.Time(gapIndexes(i)+1))]); 
end



% =========================================================================================
%% ROUNDING OF TIME STAMPS
% Example:  First Time Stamp value, rounded up:
%           01:00:01 --- Transformed to --> 01:15:00
%           01:17:13 --- Transformed to --> 01:30:00
%           10:43:01 --- Transformed to --> 10:45:00
%
%           Last Time Stamp value, rounded down:
%           12:03:19 --- Transformed to --> 12:00:00
%           14:59:01 --- Transformed to --> 14:45:00

minReference = [60 45 30 15 0];
timeStart    = theTable.Time(1);
timeStartR   = dateshift(timeStart,'end','minute');
minDifference= minReference - minute(timeStartR);
gapToAdd     = minutes(min(minDifference(minDifference>0)));
if ~isempty(gapToAdd)
    timeStart    = timeStartR + gapToAdd; 
end

minReference = [60 45 30 15 0];
timeEnd    = theTable.Time(end);
timeEndR   = dateshift(timeEnd,'start','minute');
minDifference= minReference - minute(timeEndR);
gapToAdd     = minutes(max(minDifference(minDifference<0)));
if ~isempty(gapToAdd)
    timeEnd    = timeEndR + gapToAdd; 
end

newTimes = [timeStart:minutes(15):timeEnd]';

% Multiple methods are available to fill the data:
% 'linear' - 'previous' - 'next' - ... etc.
% to check all of them: https://nl.mathworks.com/help/matlab/ref/retime.html#inputarg_method 

table15min = retime(theTable,newTimes,'linear');

% Remove the gap that could not be fixed (variable - dateGapIndexes):
toDelete = false(size(table15min,1),1);
for i=1:size(dateGapIndexes,1)
    toDelete = toDelete | (table15min.Time > dateGapIndexes(i,1)) & (table15min.Time < dateGapIndexes(i,2));
end
table15min(toDelete,:) = [];



% ==============================================================================================
%% CHECK FOR UNITS AND RATIOS
% If the power exceeds this value, the units are [W]
% This section assures that units are [kW]
% This also assumes that if one feeder is with wrong units, all feeders
% have the wrong units as well.

tableBeforeRatioFix = table15min;
% table15min = tableBeforeRatioFix;
% STEP -1:  Detect Huge Values of power, asume that its in [W] and
%           transform it to [kW]
% STEP -2:  Detect Negative Values fix

windowFilter = 100;          % - Time steps to calculate the average
powerThreshold = 2000;       % - If the Sum of the phases is bigger than this, 
                             %   the units are assumed to be on [W]

differenceThreshold = 200;   % The sum of the phases can not have more 
                             % than 200 kW of jump difference between time
                             % stamps.

medianFilter = medfilt1(table15min.Variables,windowFilter);   
medianFilter(1,:) = medianFilter(2,:);                        % Avoid spikes at the start of the data



indexingFilter    = medianFilter > powerThreshold;             
indexingNegative  = medianFilter < 0;                         % Check for constant negative values 
                             
temporal_1 = table15min.Variables;
temporal_1(indexingFilter)   = temporal_1(indexingFilter)./1000;  % from W to kW 
temporal_1(indexingNegative) = abs(temporal_1(indexingNegative)); % Positive 
% table15min.Variables = temporal_1; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% STEP -3: Find if the ratios still have some big differences
jumps = max(abs(diff(temporal_1)));
if jumps(:,feeders) > differenceThreshold      % Check in the SumPhases variable
    % For just 1 change
    % Check if the jump is near the end of the Time Series
    miniGap = 5;            % Mini-gap between first and second window for the ration
                            % need this to avoid spikes in the transition
                            % that has the problem
    
   % Find the index where the jump is made
   [row,col] = find(abs(diff(temporal_1)) == max(abs(diff(temporal_1))));  
   
   % Check if the jump is near the end of the Time Series
   if (row(end)+miniGap+(windowFilter) < length(temporal_1))
    
        
        ratio = mean(temporal_1( (row(end)-(windowFilter)) :row(end),:)) ./ ...
                mean(temporal_1(row(end)+miniGap: row(end)+miniGap+(windowFilter) ,:));

        temporal_1(row(end)+1:end,:) = temporal_1(row(end)+1:end,:) * ratio(end); 
   elseif (row(end)+miniGap+(windowFilter) > length(temporal_1))
        miniGap = length(temporal_1) - row(end);
        
        ratio = mean(temporal_1( (row(end)-(windowFilter)) :row(end)-1,:)) ./ ...
                mean(temporal_1(row(end): row(end)+miniGap,:));
        temporal_1(row(end)+1:end,:) = temporal_1(row(end)+1:end,:) * ratio(end);
        
   end
end
max(isoutlier(temporal_1))
table15min.Variables = filloutliers(temporal_1,'linear');



% PLOT THE RESULTS OF JUST THE RATIO FIX
figure(31)
subplot(2,1,1)
plot(tableBeforeRatioFix.Time,tableBeforeRatioFix.SumPhases,'b');
hold on
plot(table15min.Time,medianFilter(:,feeders),'g');
title('Data before RATIO fix');
legend('Original data','Average value','location', 'NorthWest');
grid on
hold off
subplot(2,1,2)
plot(table15min.Time,table15min.SumPhases,'r');
title('Data after RATIO fix');
grid on


% PLOT THE RESULTS OF THE OVERALL FIX
figure(30); 
hold on
% Orginal file from the .csv (No sampling fix, no ratio fix, nothing)
subplot(2,1,1)
plot(theTableOriginal.Time,theTableOriginal.SumPhases);
title('Original Data File');
grid on

% Data repaired
subplot(2,1,2)
plot(table15min.Time,table15min.SumPhases);
title('Fixed data File');
grid on
hold off

%% CONVERT to HOUR basis

tableHour = retime(table15min,'hourly');
tableHour = rmmissing(tableHour);

%% CONVERT to DAILY basis
tableDay = retime(table15min,'daily');
tableDay = rmmissing(tableDay);


end
