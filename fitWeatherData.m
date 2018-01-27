function [tableFit] = fitWeatherData(weatherInfo,timeTableHour,gapTable)
%% STRUCTURE OF THE INPUTS
% EXAMPLES:
% weatherInfo: (Assumed to be hourly resolution)
% ans = 
%   struct with fields:
% 
%              Description: 'KNMI (Koninklijk Nederlands Meteorologisch Instituut)'
%                 UserData: []
%           DimensionNames: {'Time'  'Variables'}
%            VariableNames: {'DD'  'FH'  'FF'  'FX'  'T'  'T10'  'TD'  'SQ'  'Q'  'DR'  'RH'  'P'  'VV'  'N'  'U'  'WW'  'IX'  'M'  'R'  'S'  'O'  'Y'}
%     VariableDescriptions: {}
%            VariableUnits: {}
%       VariableContinuity: []
%                 RowTimes: [9263×1 datetime]
% 
%
% timeTableHour:
% ans = 
%   struct with fields:
% 
%              Description: ''
%                 UserData: []
%           DimensionNames: {'Time'  'Variables'}
%            VariableNames: {'L1'  'L2'  'L3'  'SumPhases'}
%     VariableDescriptions: {}
%            VariableUnits: {}
%       VariableContinuity: []
%                 RowTimes: [1488×1 datetime]
%
% gapTable:
% ans = 
%   1×2 datetime array
%    2017-11-23 13:45:00   2017-11-27 11:00:00



dateValues = timeTableHour.Time;
data       = timeTableHour.SumPhases;
m          = length(data);


initialDate = datetime([dateValues.Year(1) dateValues.Month(1) ...
                        dateValues.Day(1) dateValues.Hour(1) 0 0], ...
                        'Format','yyyy-MM-dd HH:00:00');
finalDate = datetime([dateValues.Year(end) dateValues.Month(end) ...
                        dateValues.Day(end) dateValues.Hour(end) 0 0], ...
                        'Format','yyyy-MM-dd HH:00:00');
begining = datefind(initialDate,weatherInfo.Time);
finale   = datefind(finalDate,weatherInfo.Time);

dateSolarFiltered = weatherInfo.Time(begining:finale);


weekendFlag          = detectWeekend(dateSolarFiltered);
weekendTableFiltered = array2timetable(weekendFlag,'RowTimes',weatherInfo.Time(begining:finale),'VariableNames',{'Weekend'});
weatherInfoFiltered  = weatherInfo(begining:finale,:);


if ~isempty(gapTable)
    % Chop weekendTable and weatherInfo tables
    toDelete = false(size(weatherInfoFiltered,1),1);
    for i=1:size(gapTable,1)
        toDelete = toDelete | (weatherInfoFiltered.Time > gapTable(i,1)) & (weatherInfoFiltered.Time < gapTable(i,2));
    end
    weatherInfoFiltered(toDelete,:) = [];
    weekendTableFiltered(toDelete,:) = [];
    tableFit = [timeTableHour weatherInfoFiltered weekendTableFiltered];   

else    
    tableFit = [timeTableHour weatherInfoFiltered weekendTableFiltered];
end



end