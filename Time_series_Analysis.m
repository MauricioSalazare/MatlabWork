%% UPDATE THE .CSV FILES WITH THE LATEST INFORMATION DATA (RUN ONCE)


%% ========= IMPORT DALI - BOX READINGS (TRANSFORMER SENSOR DATA) =========
close all, clear all, clc, format compact
% filename = 'ID_Names.xlsx';
[station,filename] = requestSensorDataUser();

% =========================================================================
%% IMPORT SOLAR IRRADIANCE DATA 
filenameSolar =  'KNMI_20180116_hourly.txt';
[dateSolar, dataSolar, Station]= importSolar(filenameSolar);


%% OVERRIDE THE SENSOR IMPORT READINGS
% filename = 'SALVADOR_079.073-1.csv';    % DOESN'T WORK
% filename = 'SALVADOR_VRY.POSTS-1.csv';  % - COMMERCIAL
% filename = 'SALVADOR_ESD.000376-1.csv';
% filename = 'SALVADOR_VRY.LUITS-1.csv';
% filename = 'SALVADOR_VRY.GROTE-1.csv';  % - COMMERCIAL
% filename = 'SALVADOR_VRY.ACACS-1.csv';

% filename = 'SALVADOR_VRY.LANGS-1_mod.csv';
% filename = 'SALVADOR_VRY.LANGS-1.csv';  % - NO SOLAR PROBABLY - RESIDENTIAL
% filename = 'SALVADOR_VRY.KAMFO-1.csv';
% filename = 'SALVADOR_VRY.HOESW-1.csv';
% filename = 'SALVADOR_VRY.URSUS-1_mod.csv';
% filename = 'SALVADOR_VRY.URSUS-1.csv';  % - SOLAR RESIDENTIAL 


% filename = 'DAVINCI_029.504.csv';
% filename = 'DAVINCI_029.505.csv';
% filename = 'DAVINCI_029.506.csv';
% filename = 'DAVINCI_029.507.csv';
% filename = 'DAVINCI_029.517.csv';

% Load information from the station
% station = readtable(filename);


%% FIX DATA
% This section will clean data and resample the time series to:
% tableHour  : from 15 min res. to hour time (averaged)
% tableDay   : from 15 min res. to day time (averaged)
% table15min : from 15 min res. timestamped with correct intervals of time.

[table15min tableHour tableDay originalTable dateGapIndexes] = dataFix(station);


powerData  = table15min.Variables;
data       = table15min.SumPhases;
dateValues = table15min.Time;
m          = length(data);

% % powerData  = tableHour.Variables;
% % data       = powerData(:,4);
% % dateValues = tableHour.Time;
% % m          = length(data);
% 


%% LOAD DATA - OLD STYLE (COMMENT WHEN USING THE FIX DATA SECTION)
% powerData = station{1:end, 4:end};
% data = powerData(:,4);                   % Sum power for all phases
% dateValues = station{:,3};               % Time stamp of the power
% m = length(data);
% data = checkUnits(data); % Check Unit dimension


%% INFORMATION

% Count the number of days that the station has been taking data
daysNumber = floor(days(dateValues(end)-dateValues(1)));
% [dateInit,dateEnd,missingCount] = valuesMissing(data,dateValues);
disp('=================================================================');
disp(['Meter box: ' filename]);
disp(['Days of data: ' num2str(daysNumber) ' days']);
disp(['Initial date: ' char(dateValues(1))]);
disp(['Last date: ' char(dateValues(end))]);
disp('=================================================================');

% % =========================================================================
% %% SELECT THE TIME SPAN TO EVALUATE THE INFORMATION
% % Don't run this section if you want to get ALL the available data
% 
% initialDate = datetime(2017,7,1);
% finalDate = datetime(2017,7,30);
% 
% initialDate = datetime([initialDate.Year initialDate.Month ...
%                         initialDate.Day 0 0 0], ...
%                         'Format','yyyy-MM-dd HH:00:00');
% finalDate = datetime([finalDate.Year  finalDate.Month ...
%                       finalDate.Day   0 0 0], ...
%                         'Format','yyyy-MM-dd HH:00:00');
% begining = datefind(initialDate,dateValues);
% finale   = datefind(finalDate,dateValues);
% dateValues = dateValues(begining:finale);
% data = data(begining:finale);
% % =========================================================================


%% FIND AVERAGE DAILY CONSUMPTION PROFILES OF ONE MONTH
monthNumber = 1;
yearNumber = 2018;

disp(['AVERAGE DAILY CONSUMPTION OF: ' cell2mat(month(datetime(1,monthNumber,1),'name'))]); 
% periodSelect:
% 1 - Weekdays
% 2 - Weekends
% 3 - The whole week

periodSelect = 1;
weekdayProfile = avgProfile(data,dateValues,monthNumber,yearNumber,1);
weekendProfile = avgProfile(data,dateValues,monthNumber,yearNumber,2);
weekProfile    = avgProfile(data,dateValues,monthNumber,yearNumber,3);
x = 1:length(weekdayProfile);

figure(20)
plot(x,weekdayProfile,x,weekendProfile,x,weekProfile);
legend('Avg Weekday','Avg. Weekend','Avg. Week','location','NorthEast'); 
title(['Averaged consumption' newline 'Month: ' ...
        cell2mat(month(datetime(1,monthNumber,1),'name')) ...
        '  Year: ' num2str(yearNumber)]);
xlabel('Time stamp')
ylabel('Real Power (kW)');

disp('=================================================================');

%% PLOT DAYS OF INTEREST

% Test to extract one day of data
dayNumber = 13;
monthNumber = 11;
yearNumber = 2017;

% figure(1)
% hold on
% dataDay = histogramPlot(data, dateValues, dayNumber, monthNumber,yearNumber);
% hold off


% Plot load consumption on the days specified by i (dayNumber = i)

figure(3)
hold on
j=1;

% dayNumber = [20 21 22];
% dayNumber = [8:12];
dayNumber = [13:17];
k = length(dayNumber);

for i=[1:k]
    theColor = distinguishable_colors(j);
    dayPlot(data, dateValues, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
    j = j + 1;
end
title(['Superposed daily profiles from: ' filename]);
hold off

% Plot solar radiance consumption on the days specified by i
figure(4)
hold on
j = 1;
for i=[1:k]
    dayPlot(dataSolar, dateSolar, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
    j = j + 1;
end
title(['Superposed daily profiles from: ' filenameSolar]);
hold off


%% PLOT WEEK DAYS

figure(5)
hold on
j=1;

k = length(dayNumber);

for i=[1:k]
    if ~isweekend(datetime(yearNumber, monthNumber, dayNumber(i)))
        theColor = distinguishable_colors(j);
        dayPlot(data, dateValues, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
        j = j + 1;
    end
end
title(['Superposed daily profiles from: ' filename]);
hold off

% Plot solar radiance consumption on the days specified by i
figure(6)
hold on
j = 1;
for i=[1:k]
    if ~isweekend(datetime(yearNumber, monthNumber, dayNumber(i)))
        dayPlot(dataSolar, dateSolar, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
        j = j + 1;
    end
end
title(['Superposed daily profiles from: ' filenameSolar]);
hold off



%% PLOT WEEKENDS


figure(7)
hold on
j=1;

k = length(dayNumber);

for i=[1:k]
    if isweekend(datetime(yearNumber, monthNumber, dayNumber(i)))
        theColor = distinguishable_colors(j);
        dayPlot(data, dateValues, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
        j = j + 1;
    end
end
title(['Superposed daily profiles from: ' filename]);
hold off

% Plot solar radiance consumption on the days specified by i
figure(8)
hold on
j = 1;
for i=[1:k]
    if isweekend(datetime(yearNumber, monthNumber, dayNumber(i)))
        dayPlot(dataSolar, dateSolar, dayNumber(i), monthNumber,yearNumber,theColor(j,:));
        j = j + 1;
    end
end
title(['Superposed daily profiles from: ' filenameSolar]);
hold off

% Normalize data
normalize = max(data);
dataNorm = data/normalize;


% Convert to datetime object in Matlab
% datetime(year, month, day)
datetime(2017,12,24);


% Split data in Training - Testing sets:
percent = 0.8;                                % Percentage for Training
dataTraining = dataNorm(1:ceil(length(data)* percent));     % '%' of the Data for Training 
dataTesting = dataNorm(ceil(length(data) * percent):end);   % '%' of the Data for prediction

%% PLOT LOAD CONSUMPTION - TIME SERIES
sizeTraining = length(dataTraining);
weekendFlag = detectWeekend(dateValues);
m = length(data);

figure(1)
plot(dateValues,dataNorm,'+k','markersize',2);
grid on, hold on
plot(dateValues(1:sizeTraining),dataTraining,'b');
plot(dateValues(sizeTraining:length(data)),dataTesting,'r');
title(filename);
xlim([dateValues(1) dateValues(m)])
set(gca, 'Xtick', (dateValues(1):1:dateValues(m)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(dateValues, weekendFlag,'LineStyle','None','FaceAlpha',0.1);
legend('Sampling Markers','Training data','Validation data','Weekend','location','SouthWest');

hold off

%% PLOT SOLAR IRRADIANCE - TIME SERIES
% Filter the solar data based the time length of load time-series dates.
% It is assumed that the time span of solar data is larger than the 
% load consumption time-series.

initialDate = datetime([dateValues.Year(1) dateValues.Month(1) ...
                        dateValues.Day(1) dateValues.Hour(1) 0 0], ...
                        'Format','yyyy-MM-dd HH:00:00');
finalDate = datetime([dateValues.Year(end) dateValues.Month(end) ...
                        dateValues.Day(end) dateValues.Hour(end) 0 0], ...
                        'Format','yyyy-MM-dd HH:00:00');
begining = datefind(initialDate,dateSolar);
finale   = datefind(finalDate,dateSolar);
dateSolarFiltered = dateSolar(begining:finale);
dataSolarFiltered = dataSolar(begining:finale);

weekendFlag = detectWeekend(dateSolarFiltered);

figure(2)
hold on
plot(dateSolarFiltered, dataSolarFiltered,'color',[1 0.8 0]);
title(['Weather Station: ' Station.station]);
xlim([dateSolarFiltered(1) dateSolarFiltered(end)]);
set(gca, 'Xtick', (dateValues(1):1:dateValues(m)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(dateSolarFiltered,weekendFlag.*max(dataSolarFiltered), ...
     'LineStyle','None','FaceAlpha',0.1,'FaceColor','b');
legend('Solar Irradiance','Weekend','location','SouthWest');
hold off

figure(20)




% =========================================================================
% ===== AUXILIARY FUNCTIONS SECTION =======================================
% =========================================================================

function dayProfile = avgProfile(data,dateValues,month,year,periodSelect)
    dataDay = zeros(96,1);
    count = 0;
    
    for day = 1:31
        switch periodSelect 
            case 1
                if ~isweekend(datetime(year,month,day))
                    allow = true;
                else
                    allow = false;
                end
            case 2
                if isweekend(datetime(year,month,day))
                    allow = true;
                else
                    allow = false;
                end
            case 3
                    allow = true;
            otherwise
                disp('Invalid average Profile selection.');
        end        
        
        indexed = (dateValues.Day ==  day & ...
                 dateValues.Month == month & ...
                 dateValues.Year == year);
        if sum(indexed) == 96 && allow == true
            dataDay = dataDay + data(indexed);
            count = count + 1;            
        end
    end
    if count == 0
        disp('No available data in the month');
        dayProfile = [];
    else
        dayProfile = dataDay ./ count;
        disp(['Days with data: ' num2str(count)]);
    end
end

function dataDay = histogramPlot(data, dateValues,dayNumber,monthNumber,yearNumber)
    dataDay =  data(dateValues.Day ==  dayNumber & ...
                 dateValues.Month == monthNumber & ...
                 dateValues.Year == yearNumber);
    bins = 10;
    histogram(dataDay,bins);
    xlabel('Real Power (kW)')
    ylabel('Frequency');
    title(datestr(datetime(yearNumber,monthNumber,dayNumber))); 
    
end

% dayPlot(data, dateValues, dayNumber, monthNumber,yearNumber);
function dataDay = dayPlot(data, dateValues,dayNumber,monthNumber,yearNumber, theColor)
    index = (dateValues.Day ==  dayNumber & ...
                 dateValues.Month == monthNumber & ...
                 dateValues.Year == yearNumber);
    if (sum(index)==96)         
        dataDay     =  data(index);
        dateLabels  =  dateValues(index);

        plot(1:length(dateLabels),dataDay,'color',theColor);    
        xlabel('Date')
        ylabel('Real Power (kW)');
        grid on
        
    %     title(datestr(datetime(yearNumber,monthNumber,dayNumber))); 
    elseif(sum(index) == 24)
        dataDay     =  data(index);
        dateLabels  =  dateValues(index);

        plot(1:length(dateLabels),dataDay,'color',theColor);    
        xlabel('Date')
        ylabel('Global radiation (in J / cm2) per hour compartment');
        grid on
    else
        disp(['Date (dd-mm-yyy): ' num2str(dayNumber) '-' num2str(monthNumber)...
                  '-' num2str(yearNumber) 'does not have enough data: ' ...
                  num2str(sum(index)) ' samples']);
    end
    
end

function data = checkUnits(data)
    for i=1:length(data)
       if data(i) > 600
           data(i) = data(i)./1000;
       end
    end
end
