% Este cambio es en un segundo archivo para Github
% Otro cambio pequeño

T = simplenar_dataset;
net = narnet(1:2,10);
[Xs,Xi,Ai,Ts] = preparets(net,{},{},T);
net = train(net,Xs,Ts,Xi,Ai);

[Y,Xf,Af] = net(Xs,Xi,Ai);
perf = perform(net,Ts,Y)

[netc,Xic,Aic] = closeloop(net,Xf,Af);

y2 = netc(cell(0,20),Xic,Aic)

y2=cell2mat(y2)
plot(1:size(y2,2),y2)
