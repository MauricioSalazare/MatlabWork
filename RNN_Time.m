%% IMPORT DATA FROM DALI FILES (CSV - FILES) 

close all, clear all, clc, format compact

% Training data set
data = csvread('SALVADOR_VRY.LANGS-1_mod.csv',1,6);
norm = max(data);
data = data/norm;
m = length(data);

% Testing data set
percent = 0.8
dataTraining = data(1:ceil(m* percent));     % '%' of the Data for Training 
dataTesting = data(ceil(m * percent):end);   % '%' of the Data for prediction

% Plot the time series
sizeTraining = length(dataTraining)
figure(1)
plot(1:m,data,'+k','markersize',2);
grid on, hold on
plot(1:sizeTraining,dataTraining,'b');
plot(sizeTraining:m,dataTesting,'r');
title('SALVADOR VRY.LANGS-1.csv');
legend('Sampling Markers','Training data','Validation data','location','SouthWest');
xlim([0 m])
hold off

% figure(2)
% autocorr(dataTraining)

% figure(2)
% m2 = size(data_test,1);
% time2 = linspace(1,m2,m2)';
% plot(time2,data_test);
% title('Data Testing');

%% ---------------------------------------------------------------------
% RECURRENT NEURAL NETWORK

% Good performance, BAYESIAN better, takes 57 min to run
%timeDelay=50;
%hiddenLayer=50;

timeDelay=50;
hiddenLayer=20;
net = layrecnet(1:timeDelay,hiddenLayer);
% net.trainParam.showWindow = false;

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

[Xs,Xi,Ai,Ts] = preparets(net,Training,Training);

% Train the net with the training data set:
% net.trainFcn = 'trainbr';   % Enable Bayesian regularization
net = train(net,Xs,Ts,Xi,Ai);
% view(net)


%% ----------------------------------------------------------------------
% Prediction of the time series

% Close feedback for recursive prediction
% netc = closeloop(net);
netc=net;
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

figure(1)
hold on
plot(sizeTraining:m,prediction,'k')
plot(sizeTraining:m,e,'g')
legend('Sampling Markers','Training data','Validation data',...
    'Prediction','Error','location','SouthWest');

%%-----------------------------------------------------------------------
%% Use Bayesian prediction net (Previously trained - 57 min)
predict2 = ANN_time_bayesian(cell2mat(Testing), cell2mat(yini));
e2 =  testing - predict2;
figure(1)
hold on
plot(sizeTraining:m,predict2,'y');
plot(sizeTraining:m,e2,'b');
legend('Sampling Markers','Training data','Validation data',...
    'Prediction','Error','Bayesian Regularization','Error bayesian','location','SouthWest');
