%% UPDATE THE .CSV FILES WITH THE LATEST INFORMATION DATA (RUN ONCE)


%% ========= IMPORT DALI - BOX READINGS (TRANSFORMER SENSOR DATA) =========
close all, clear all, clc, format compact
T  = table;
T2 = table;
structSeries = [];
prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};

for ii = 2:26
    BoxSelection = 1;     % Look the prefix variable to select this number
    [station,filename] = requestSensorData(BoxSelection,ii);


    %% FIX DATA
    % This section will clean data and resample the time series to:
    % tableHour  : from 15 min res. to hour time (averaged)
    % tableDay   : from 15 min res. to day time (averaged)
    % table15min : from 15 min res. timestamped with correct intervals of time.

    [table15min tableHour tableDay originalTable dateGapIndexes] = dataFix(station);


    % SAVE DIFFERENT TIME SERIES RESOLUTIONS
    tempSeries.StationName      = {filename(length(prefix{BoxSelection})+1:end-4)};   
    tempSeries.originalTable    = originalTable;
    tempSeries.timeTable15min   = table15min;
    tempSeries.timeTableHour    = tableHour;
    tempSeries.gapTable         = dateGapIndexes;
    structSeries                = [structSeries; tempSeries];
    
%     powerData  = table15min.Variables;
%     data       = table15min.SumPhases;
%     dateValues = table15min.Time;
%     m          = length(data);
    
    powerData  = tableHour.Variables;
    data       = tableHour.SumPhases;
    dateValues = tableHour.Time;
    m          = length(data);
    

    %% INFORMATION FROM THE IME SERIES

    % Count the number of days that the station has been taking data
    daysNumber = floor(days(dateValues(end)-dateValues(1)));
    % [dateInit,dateEnd,missingCount] = valuesMissing(data,dateValues);
    disp('=================================================================');
    disp(['Meter box: ' filename]);
    disp(['Days of data: ' num2str(daysNumber) ' days']);
    disp(['Initial date: ' char(dateValues(1))]);
    disp(['Last date: ' char(dateValues(end))]);
    disp('=================================================================');

    %% FIND AVERAGE DAILY CONSUMPTION PROFILES OF ONE MONTH
    monthNumber = 1;
    yearNumber = 2018;

    disp(['AVERAGE DAILY CONSUMPTION OF: ' cell2mat(month(datetime(1,monthNumber,1),'name'))]); 
    % periodSelect:
    % 1 - Weekdays
    % 2 - Weekends
    % 3 - The whole week

   
    weekdayProfile = avgProfile(data,dateValues,monthNumber,yearNumber,1);
    weekendProfile = avgProfile(data,dateValues,monthNumber,yearNumber,2);
    weekProfile    = avgProfile(data,dateValues,monthNumber,yearNumber,3);
    x = 1:length(weekdayProfile);
    
    
    % Save it in the Temporary Table Variable for further FILE saving.
    % Only Weekday Profile is saved
    tempTable.name = {filename(length(prefix{BoxSelection})+1:end-4)};
    tempTable.data = (weekdayProfile/max(weekdayProfile))';
    T = [T; struct2table(tempTable)];
    
    tempTable2.name = {filename(length(prefix{BoxSelection})+1:end-4)};
    tempTable2.data = (weekdayProfile/max(weekdayProfile))';
    T2 = [T2; struct2table(tempTable2)];
    
    
    figure(1)
    subplot(6,5,ii)
    plot(x,weekdayProfile,x,weekendProfile,x,weekProfile);
    title(['ID: ' filename(1:end-4)]);
%     legend('Avg Weekday','Avg. Weekend','Avg. Week','location','NorthEast'); 
%     title(['Averaged consumption ' 'ID: ' filename(1:end-4) newline 'Month: ' ...
%             cell2mat(month(datetime(1,monthNumber,1),'name')) ...
%             '  Year: ' num2str(yearNumber)]);
%     xlabel('Time stamp')
%     ylabel('Real Power (kW)');

    disp('=================================================================');

end

%% SAVE AVERAGE PROFILE - the Results in a .mat file variable for futher use;
prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};
monthName = cell2mat(month(datetime(1,monthNumber,1),'name'));
dateFileName = [prefix{BoxSelection} 'Normalized_Profiles_' monthName '.mat'];
save(dateFileName,'T');



%% SAVE TIME SERIES PROFILES - the Results in a .mat file variable for futher use;
prefix = {'SALVADOR_','DAVINCI_','LAADPLEIN_','ONBEKEND_'};
fileName = [prefix{BoxSelection} 'TimeSeries_Profiles.mat'];
save(fileName,'structSeries');



% Correlation coefficients plot - (Time series comparison)
R = corrcoef(T.data');
xvalues = T.name';
figure;
h = heatmap(xvalues,xvalues,R);
h.title(['Correlation of ' prefix{BoxSelection}(1:end-1) ' Boxes '...
         ' -- Month: ' monthName ' Year: ' num2str(yearNumber)]);
     

     
%% K-MEANS CLUSTERING

cleanTable = rmmissing(T);
for k=1:length(cleanTable.name)
    [idx,C,sumd,D] = kmeans(cleanTable.data,k,'Replicates',100,'Display','off');
    clusterDistance(k) = sum(sumd);
    theMeans{k}.idx = idx;
    theMeans{k}.C   = C;
    theMeans{k}.idx = idx;
    theMeans{k}.sumd= sumd;
    theMeans{k}.D   = D;
    
    disp(['Number of clusters: ' num2str(k)]);
    disp(['Best sum of total distances: ' num2str(sum(sumd))]);
end

derivate = abs(diff(clusterDistance));
derivateDis = derivate-1;
bestClusterDistance = min(derivateDis((derivateDis)>0));
[rox,clusterNum] = find(bestClusterDistance == derivateDis);


clusterNum=5;   % Over ride the clustering number

% Display the Bend of Cluster distances
figure;
plot(1:length(cleanTable.name),clusterDistance,'-rx');
hold on
plot(clusterNum,clusterDistance(clusterNum),'-bo','MarkerSize',10);
legend('Sum-Within Cluster','Optimal Cluster','location','NorthEast');
title('Cluster Number Selection - Elbow Method');
axis square
hold off


% Display result of the clustering
disCol = ceil(sqrt(clusterNum));
disRow = ceil(clusterNum/disCol);

[n,m] = size(theMeans{clusterNum}.C);
vectorGrid = 1:1:m;                   % This size depends if data is:
                                      % - 15 min resolution: 96 time steps
                                      % - hourly resolution: 24 time steps
                                        
[X,Y]=meshgrid(vectorGrid,vectorGrid);

figure;
hold on
for ii=1:clusterNum
    subplot(disRow,disCol,ii)    
    [X,Y]=meshgrid(vectorGrid,vectorGrid);              % Take Y
    numberOfBoxes = sum(theMeans{clusterNum}.idx==ii);  % # of boxes in the cluster
    plot(Y(:,1:numberOfBoxes), cleanTable.data(theMeans{clusterNum}.idx==ii,:)');
    legend(cleanTable.name(theMeans{clusterNum}.idx==ii,:)','location','bestoutside','fontsize',8);
    title(['Cluster #: ' num2str(ii) ' -> Tot. Boxes: ' num2str(numberOfBoxes)]);
end
hold off;




