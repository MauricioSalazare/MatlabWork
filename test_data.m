
% Training data set
data = csvread('SALVADOR_VRY.LANGS-1_mod.csv',1,6);
% data = csvread('SALVADOR_VRY.KAMFO-1.csv',1,6);
% data = csvread('SALVADOR_VRY.HOESW-1.csv',1,6);
% data = csvread('SALVADOR_VRY.URSUS-1_mod.csv',1,6);

norm = max(data);
data = data/norm;
m = length(data);

% Testing data set
percent = 0.8
dataTraining = data(1:ceil(m* percent));     % '%' of the Data for Training 
dataTesting = data(ceil(m * percent):end);   % '%' of the Data for prediction

% Plot the time series
sizeTraining = length(dataTraining)
figure(2)
plot(1:m,data,'+k','markersize',2);
grid on, hold on
plot(1:sizeTraining,dataTraining,'b');
plot(sizeTraining:m,dataTesting,'r');
title('SALVADOR VRY.LANGS-1.csv');
legend('Sampling Markers','Training data','Validation data','location','SouthWest');
xlim([0 m])
hold off

x=1;
y=1;
load('NN_VR_LANGS-1_closed.mat','neural')
netc{x,y}=neural;

Training = con2seq(dataTraining'); 
Testing  = con2seq(dataTesting');



yini = Training(end-(netc{x,y}.numLayerDelays)+1:end);
[Xs, Xi, Ai] = preparets(netc{x,y},{},{},[yini Testing]);

predict = netc{x,y}(Xs,Xi,Ai);

% Convert cell data to matrix
testing = cell2mat(Testing);
prediction = cell2mat(predict);
% error
e = testing - prediction;
RMSE = sqrt(mean((testing-prediction).^2))

figure(2)
hold on
plot(sizeTraining:m,prediction,'k')
plot(sizeTraining:m,e,'g')
legend('Sampling Markers','Training data','Validation data',...
    'Prediction','Error','location','SouthWest');


