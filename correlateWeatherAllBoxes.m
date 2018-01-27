
clear all, clc, close all, format compact;
% 'KNMI_20180122_hourly_GUILZE.txt';  % FOR DAVINCI BOXES
filename={'KNMI_20180121_hourly.txt','KNMI_20180122_hourly_GUILZE.txt'};


prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};
BoxSelection = 2;
[weatherInfo, Station] = importWeather(filename{BoxSelection});
fileName = [prefix{BoxSelection} 'TimeSeries_Profiles.mat'];
load(fileName)
% Once the file is loaded, the variable structSeries contains all data
%
% structSeries -> Variable Name of the series for each box
% Example:  
% structSeries(1)
% ans = 
%   struct with fields:
% 
%        StationName: {'VRY.POSTS-1'}
%      originalTable: [5947×4 timetable]
%     timeTable15min: [5953×4 timetable]
%      timeTableHour: [1488×4 timetable]
%           gapTable: [2017-11-24 10:30:00    2017-11-27 11:15:00]
%           
          
          
%% FIND TIME RANGE OVERLAP BETWEEN DALI BOX AND WEATHER DATA

%%%% EXPORT COMPLETE SET OF SOLAR IRRADIANCE DATA %%%%%%%%%%%%%%%%%%%%%%%%%
numberOfBoxes = length(structSeries)

for ii=1:numberOfBoxes
    boxNumber = ii;
    % boxNumber = 23;   
    % 23 - DAVINCI - StationName: {'170.548'}
    % 3 - URSUS - solar
    % 4 - LANGS - no solar
    % 7 - HOESW - high solar
    dateSolar = weatherInfo.Time;
    dataSolar = weatherInfo.Q;

    dateValues = structSeries(boxNumber).timeTableHour.Time;
    data       = structSeries(boxNumber).timeTableHour.SumPhases;
    m          = length(data);

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


    %%%% SET OF WEATHER DATA CHOPED ACCORDING TO TIME SERIES DATA %%%%%%%%%%%%%

    [tableFit] = fitWeatherData(weatherInfo,structSeries(boxNumber).timeTableHour,structSeries(boxNumber).gapTable);

    %% CORRELATION CALCULATION
    indexingg = tableFit.Q>0;
    A = [tableFit.SumPhases./max(tableFit.SumPhases) tableFit.Q./max(tableFit.Q) tableFit.T/max(tableFit.T)];
    [R,P,UB,LB] = corrcoef(A);

    B = [tableFit.SumPhases(indexingg)./max(tableFit.SumPhases) tableFit.Q(indexingg)./max(tableFit.Q) tableFit.T(indexingg)/max(tableFit.T)];
    [R2,P2,UB2,LB2] = corrcoef(B);
    
    structSeries(boxNumber).weatherDataHour = tableFit;
    
    structSeries(boxNumber).corrComplete.R = R;
    structSeries(boxNumber).corrComplete.P = P;
    structSeries(boxNumber).corrComplete.UB = UB;
    structSeries(boxNumber).corrComplete.LB = LB;
    
    structSeries(boxNumber).corrSunlight.R = R2;
    structSeries(boxNumber).corrSunlight.P = P2;
    structSeries(boxNumber).corrSunlight.UB = UB2;
    structSeries(boxNumber).corrSunlight.LB = LB2;


end

% SAVE TIME SERIES WITH CORRELATION INFORMATION
prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};
fileName = [prefix{BoxSelection} 'TimeSeries_Profiles_Corr.mat'];
save(fileName,'structSeries');



%% PLOT OF ORIGINAL SOLAR IRRADIANCE DATA
figure
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

%% PLOT OF CHOPED SOLAR IRRADIANCE DATA WITH TIME SERIES OVERLAY
figure
hold on
plot(tableFit.Time,tableFit.SumPhases./max(tableFit.SumPhases),'b');
title(['Weather Station: ' Station.station]);
xlim([tableFit.Time(1) tableFit.Time(end)]);
set(gca, 'Xtick', (tableFit.Time(1):1:tableFit.Time(end)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(tableFit.Time,tableFit.Weekend, ...
     'LineStyle','None','FaceAlpha',0.1,'FaceColor','b');

plot(tableFit.Time,tableFit.Q./max(tableFit.Q),'color',[1 0.8 0]);
legend('Sum Phases','Weekend','Solar Irradiance','location','SouthWest');

hold off



%% PLOT OF THE SOLAR IRRADIANCE, TEMPERATURE, CLOUDINESS, WEATHER DATA

figure
subplot(3,1,1)
hold on
plot(tableFit.Time,tableFit.Q./max(tableFit.Q),'color',[1 0.8 0]);
% plot(tableFit.Time,tableFit.SumPhases./max(tableFit.SumPhases),'b');
title(['Weather Station: ' Station.station]);
xlim([tableFit.Time(1) tableFit.Time(end)]);
set(gca, 'Xtick', (tableFit.Time(1):1:tableFit.Time(end)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(tableFit.Time,tableFit.Weekend, ...
     'LineStyle','None','FaceAlpha',0.1,'FaceColor','b');
legend('Solar Irradiance','Weekend','location','SouthWest');
grid on
hold off

 
subplot(3,1,2)
hold on
plot(tableFit.Time,tableFit.T.*0.1,'color','b');
xlim([tableFit.Time(1) tableFit.Time(end)]);
set(gca, 'Xtick', (tableFit.Time(1):1:tableFit.Time(end)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(tableFit.Time,tableFit.Weekend, ...
     'LineStyle','None','FaceAlpha',0.1,'FaceColor','b');
legend('Temperature (ºC)','Weekend','location','SouthWest');
grid on
hold off


subplot(3,1,3)
hold on
plot(tableFit.Time,tableFit.FH.*0.1,'color','m');
xlim([tableFit.Time(1) tableFit.Time(end)]);
set(gca, 'Xtick', (tableFit.Time(1):1:tableFit.Time(end)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
area(tableFit.Time,tableFit.Weekend, ...
     'LineStyle','None','FaceAlpha',0.1,'FaceColor','b');
legend('Wind Speed (m/s)','Weekend','location','SouthWest');
grid on
hold off
