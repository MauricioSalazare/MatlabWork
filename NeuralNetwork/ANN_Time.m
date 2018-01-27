%% IMPORT DATA FROM DALI FILES (CSV - FILES) 

close all, clear all, clc, format compact

% filename = 'SALVADOR_079.073-1.csv';  % DOESN'T WORK
% filename = 'SALVADOR_VRY.POSTS-1.csv';
% filename = 'SALVADOR_ESD.000376-1.csv';
% filename = 'SALVADOR_VRY.LUITS-1.csv';
% filename = 'SALVADOR_VRY.GROTE-1.csv';
% filename = 'SALVADOR_VRY.ACACS-1.csv';

% filename = 'SALVADOR_VRY.LANGS-1_mod.csv';
% filename = 'SALVADOR_VRY.LANGS-1.csv';
% filename = 'SALVADOR_VRY.KAMFO-1.csv';
% filename = 'SALVADOR_VRY.HOESW-1.csv';
filename = 'SALVADOR_VRY.URSUS-1_mod.csv';
% filename = 'SALVADOR_VRY.URSUS-1.csv';


% filename = 'DAVINCI_029.504.csv';
% filename = 'DAVINCI_029.505.csv';
% filename = 'DAVINCI_029.506.csv';
% filename = 'DAVINCI_029.507.csv';
% filename = 'DAVINCI_029.517.csv';

% Load information from the station
station = readtable(filename);
station = rmmissing(station);
powerData = station{1:end, 4:end};
data = powerData(:,4);                   % Sum power for all phases
dateValues = station{:,3};


%% RESAMPLING AND INFORMATION

% Count the number of days that the station has been taking data
daysNumber = floor(days(dateValues(end)-dateValues(1)));
% [dateInit,dateEnd,missingCount] = valuesMissing(data,dateValues);

disp(['Meter box: ' filename]);
disp(['Days of data: ' num2str(daysNumber) ' days']);
disp(['Initial date: ' char(dateValues(1))]);
disp(['Last date: ' char(dateValues(end))]);


% Resample the time series to:
% 'hour'  : from 15 min res. to hour time (averaged)
% 'day'   : from 15 min res. to day time (averaged)
% 'month' : from 15 min res. to month time (averaged)
% [dataResampled, dateResampled] = resampleData(data,dateValues,'hour');


% % =========================================================================
% %% SELECT THE TIME SPAN TO EVALUATE THE INFORMATION
% % Don't run this section if you want to get all the available data
% 
% initialDate = datetime(2017,11,12);
% finalDate = datetime(2017,12,1);
% % 
% % initialDate = datetime([initialDate.Year initialDate.Month ...
% %                         initialDate.Day 0 0 0], ...
% %                         'Format','yyyy-MM-dd HH:00:00');
% % finalDate = datetime([finalDate.Year  finalDate.Month ...
% %                       finalDate.Day   0 0 0], ...
% %                         'Format','yyyy-MM-dd HH:00:00');
% begining = datefind(initialDate,datetime(dateValues.Year(:),dateValues.Month(:),dateValues.Day(:)));
% finale   = datefind(finalDate,datetime(dateValues.Year(:),dateValues.Month(:),dateValues.Day(:)));
% dateValues = dateValues(begining(1):finale(1));
% data = data(begining(1):finale(1));
% % =========================================================================



%% CHECK UNITS DIMENSIONS

data = checkUnits(data);



norm = max(data);
data = data/norm;
m = length(data);

% Testing data set
percent = 0.8
dataTraining = data(1:ceil(m* percent));     % '%' of the Data for Training 
dataTesting = data(ceil(m * percent):end);   % '%' of the Data for prediction


%
sizeTraining = length(dataTraining)
figure(2)
plot(dateValues,data,'+k','markersize',2);
grid on, hold on
plot(dateValues(1:sizeTraining),dataTraining,'b');
plot(dateValues(sizeTraining:m),dataTesting,'r');
title(filename);
legend('Sampling Markers','Training data','Validation data','location','SouthWest');
xlim([dateValues(1) dateValues(m)])
set(gca, 'Xtick', (dateValues(1):1:dateValues(m)));
datetick('x','dd-mmm','keepticks');
xtickangle(45);
hold off




% Plot the time series
sizeTraining = length(dataTraining)
figure(1)
plot(1:m,data,'+k','markersize',2);
grid on, hold on
plot(1:sizeTraining,dataTraining,'b');
plot(sizeTraining:m,dataTesting,'r');
title(filename);
legend('Sampling Markers','Training data','Validation data','location','SouthWest');
xlim([1 m])
hold off

% figure(2)
% autocorr(dataTraining)

% figure(2)
% m2 = size(data_test,1);
% time2 = linspace(1,m2,m2)';
% plot(time2,data_test);
% title('Data Testing');

%% ---------------------------------------------------------------------
% Train the Nonlinear autoregressive neural network (NARNET)

% Good performance, BAYESIAN better, takes 57 min to run
% timeDelay = 50 and hiddenLayer = 50 para LANGS-1-mod.csv
% timeDelay = 26 and hiddenLayer = 24 para URSUS-1-mod.csv (0.067419)
timeDelay=26;
hiddenLayer=24;
rng(0)
% timeDelay=10
% hiddenLayer=100;
net = narnet(1:timeDelay,hiddenLayer);
net.trainParam.showWindow = false;

%T=tonndata(data_train,false,false); % Fancy way to convert data to cells

Training = con2seq(dataTraining'); 
Testing  = con2seq(dataTesting');


% [Xs,Xi,Ai,Ts,EWs,shift] = preparets(net,Xnf,Tnf,Tf,EW)
%
% This function simplifies the normally complex and error prone task of
% reformatting input and target timeseries. It automatically shifts input
% and target time series as many steps as are needed to fill the initial
% input and layer delay states. If the network has open loop feedback,
% then it copies feedback targets into the inputs as needed to define the
% open loop inputs.
%
%  net : Neural network
%  Xnf : Non-feedback inputs
%  Tnf : Non-feedback targets
%   Tf : Feedback targets
%   EW : Error weights (default = {1})
%
%   Xs : Shifted inputs
%   Xi : Initial input delay states
%   Ai : Initial layer delay states
%   Ts : Shifted targets

[Xs,Xi,Ai,Ts] = preparets(net,{},{},Training);

% Train the net with the training data set:
% net.trainFcn = 'trainbr';   % Enable Bayesian regularization
tic
net = train(net,Xs,Ts,Xi,Ai);
toc
% view(net)


%% ----------------------------------------------------------------------
% Prediction of the time series

% Close feedback for recursive prediction
netc = closeloop(net);
% view(netc)

% Take the last values of the training data set (length of time delay)
yini = Training(end-timeDelay+1:end);

% Prepare the values: Last values(timeDelay) + data testing
% For testing values only matters the number of input of cells t
% i.e. if Testing data has 24 cells, will predict 24 time steps, no matter
% what is in the values of the 24 cells (the values on the cells could be 
% sequence of numbers [1, 2, 3, 4, ..., 24])

[Xs, Xi, Ai] = preparets(netc,{},{},[yini Testing]);

predict = netc(Xs,Xi,Ai);

% Convert cell data to matrix
testing = cell2mat(Testing);
prediction = cell2mat(predict);
% error
e = testing - prediction;
RMSE = sqrt(mean((testing-prediction).^2))

figure(1)
hold on
plot(sizeTraining:m,prediction,'k')
plot(sizeTraining:m,e,'g')
legend('Sampling Markers','Training data','Validation data',...
    'Prediction','Error','location','SouthWest');



% 
% %%-----------------------------------------------------------------------
% %% Use Bayesian prediction net (Previously trained - 57 min)
% predict2 = ANN_time_bayesian(cell2mat(Testing), cell2mat(yini));
% e2 =  testing - predict2;
% figure(1)
% hold on
% plot(sizeTraining:m,predict2,'m');
% plot(sizeTraining:m,e2,'b');
% legend('Sampling Markers','Training data','Validation data',...
%     'Prediction','Error','Bayesian Regularization','Error bayesian','location','SouthWest');
% 
% predict3 = ANN_time_bayesian([eye(1,482)], cell2mat(yini));
% e2 =  testing - predict2;
% 
% m3 = length(predict3);
% 
% figure(2)
% hold on
% 
% plot(1:m3,predict3,'m');
% % plot(sizeTraining:m,e2,'b');

