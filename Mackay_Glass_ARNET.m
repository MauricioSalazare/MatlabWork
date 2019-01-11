close all, clear all, clc, format compact
% Este es un cambio tonto, quiero que esto quede en github
    
% data settings
N  = 700; % number of samples
Nu = 300; % number of learning samples

% Mackay-Glass time series
b   = 0.1;
c   = 0.2;
tau = 17;

% initialization
y = [0.9697 0.9699 0.9794 1.0003 1.0319 1.0703 1.1076 1.1352 1.1485 ...
     1.1482 1.1383 1.1234 1.1072 1.0928 1.0820 1.0756 1.0739 1.0759]';
% generate Mackay-Glass time series
for n=18:N+99
  y(n+1) = y(n) - b*y(n) + c*y(n-tau)/(1+y(n-tau).^10);
end
% remove initial values
y(1:100) = [];

% plot training and validation data

plot(y,'m-')
grid on, hold on
plot(y(1:Nu),'b')
plot(y,'+k','markersize',2)
legend('validation data','training data','sampling markers','location','southwest')
xlabel('time (steps)')
ylabel('y')
ylim([-.5 1.5])
set(gcf,'position',[1 60 800 400])

% prepare training data
yt = con2seq(y(1:Nu)');

% prepare validation data
yv = con2seq(y(Nu+1:end)');
% yv = con2seq(1:400);

%---------- network parameters -------------
% good parameters (you don't know 'tau' for unknown process)
inputDelays = 1:6:19;  % input delay vector
hiddenSizes = [6 3];   % network structure (number of neurons)
%-------------------------------------

% nonlinear autoregressive neural network
net = narnet(inputDelays, hiddenSizes);

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
[Xs,Xi,Ai,Ts] = preparets(net,{},{},yt);

% train net with prepared training data
net = train(net,Xs,Ts,Xi,Ai);
% view trained net
view(net)

% close feedback for recursive prediction
net = closeloop(net);
% view closeloop version of a net
view(net);

% prepare validation data for network simulation
yini = yt(end-max(inputDelays)+1:end); % initial values from training data
% combine initial values and validation data 'yv'
[Xs,Xi,Ai] = preparets(net,{},{},[yini yv]);

% predict on validation data
predict = net(Xs,Xi,Ai);

% validation data
Yv = cell2mat(yv);
% prediction
Yp = cell2mat(predict);
% error
e = Yv - Yp;

% plot results of recursive simulation
figure(1)
plot(Nu+1:N,Yp,'r')
plot(Nu+1:N,e,'g')
legend('validation data','training data','sampling markers',...
  'prediction','error','location','southwest')

