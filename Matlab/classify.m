%% load tensorflow weights

clear

%load weights_2layers_15nodes.mat;
w0=load("w0.txt");
w1=load("w1.txt");
w2=load("w2.txt");
w3=load("w3.txt");
b0=load("b0.txt");
b1=load("b1.txt");
b2=load("b2.txt");
b3=load("b3.txt");
Wh1old = [b0';w0];
Wh2old = [b1';w1;];
Wh3old = [b2';w2];
Woold = [b3';w3];

%% Do this for 3 layer 15 node networks
wh1 = Wh1old;
wh2 = Wh2old;
wh3 = Wh3old;
wo = [Woold zeros(16,5)];
Wh1new = Wh1old;
Wh2new = Wh2old;
Wh3new = Wh3old;
Wonew = Woold;
% make cells
wh1c = num2cell(arrayfun(@dec2q,wh1));
wh2c = num2cell(arrayfun(@dec2q,wh2));
wh3c = num2cell(arrayfun(@dec2q,wh3));
woc = num2cell(arrayfun(@dec2q,wo));
% write csv's
csvwrite('wh1.csv', wh1);
csvwrite('wh2.csv', wh2);
csvwrite('wh3.csv', wh3);
csvwrite('wo.csv', wo);
cell2csv('wh1_q15.csv', wh1c);
cell2csv('wh2_q15.csv', wh2c);
cell2csv('wh3_q15.csv', wh3c);
cell2csv('wo_q15.csv', woc);

X=load("data1.txt");
xtrain = X(2,:)';
xtrain = [255;xtrain]; % do 255 because that will become effectively 1 when we do dec2hex
xconverted = dec2hex(xtrain);
xt = cellstr(xconverted);
csvwrite('xtrain.csv', xtrain);
cell2csv('xtrain_q15.csv', xt);

xtrain = xtrain/1024; % did /512 in TF
ah1=Wh1new'*xtrain; % activation (net input) of hidden layer 1
h1 = num2cell(arrayfun(@dec2q,ah1));
csvwrite('h1.csv', ah1);
cell2csv('h1_q15.csv', h1);
for i=1:length(ah1) % Relu activation function
    if ah1(i) < 0
        ah1(i) = 0;
    end
end
reluh1 = num2cell(arrayfun(@dec2q,ah1));
z1=[1;ah1]; % augmented output of hidden layer 1
ah2=Wh2new'*z1; % activation (net input) of hidden layer 2
h2 = num2cell(arrayfun(@dec2q,ah2));
csvwrite('h2.csv', ah2);
cell2csv('h2_q15.csv', h2);
for i=1:length(ah2) % Relu activation function
    if ah2(i) < 0
        ah2(i) = 0;
    end
end
reluh2 = num2cell(arrayfun(@dec2q,ah2));
z2=[1;ah2]; % augmented output of hidden layer 1
ah3=Wh3new'*z2; % activation (net input) of hidden layer 2
h3 = num2cell(arrayfun(@dec2q,ah3));
csvwrite('h3.csv', ah3);
cell2csv('h3_q15.csv', h3);
for i=1:length(ah3) % Relu activation function
    if ah3(i) < 0
        ah3(i) = 0;
    end
end
z3=[1;ah3]; % augmented output of hidden layer 2
ao=Wonew'*z3; % activation (net input) of output layer
ol = num2cell(arrayfun(@dec2q,ao));
csvwrite('ol.csv', ao);
cell2csv('ol_q15.csv', ol);
for i=1:length(ao) % Relu activation function
    if ao(i) < 0
        ao(i) = 0;
    end
end
yp=ao'; % output of output layer

expected = num2cell(arrayfun(@dec2q,yp));
csvwrite('expected.csv', yp);
cell2csv('expected_q15.csv', expected);

%% Do this for 2 layer 15 node networks
clear
%load weights_2layers_15nodes_new.mat % this overflows -1 to 1.  But
%minimum value is -6.  Max is 4.  So use Q3_12 => 4 integer, 12 decimal -
%range of -8 to 8
load weights_2layers_15nodes_99percent.mat % could maybe use Q2_13 but use Q3_12 to be safe

wh1 = Wh1new;
wh2 = Wh2new;
wo = [Wonew zeros(16,5)];
% make cells
wh1c = num2cell(arrayfun(@(o) dec2q(o,3,12), wh1));
wh2c = num2cell(arrayfun(@(o) dec2q(o,3,12), wh2));
woc = num2cell(arrayfun(@(o) dec2q(o,3,12), wo));
% write csv's
csvwrite('wh1.csv', wh1);
csvwrite('wh2.csv', wh2);
csvwrite('wo.csv', wo);
cell2csv('wh1_q.csv', wh1c);
cell2csv('wh2_q.csv', wh2c);
cell2csv('wo_q.csv', woc);

X=load("data1.txt");
xtrain = X(1,:)';
xtrain = [255;xtrain]; % do 255 because that will become effectively 1 when we do dec2hex
xconverted = dec2hex(xtrain);
xt = cellstr(xconverted);
csvwrite('xtrain.csv', xtrain);
cell2csv('xtrain_hex.csv', xt);

xtrain = xtrain/256;
ah1=Wh1new'*xtrain; % activation (net input) of hidden layer 1
h1 = num2cell(arrayfun(@(o) dec2q(o,3,12), ah1));
csvwrite('h1.csv', ah1);
cell2csv('h1_q.csv', h1);
for i=1:length(ah1) % Relu activation function
    if ah1(i) < 0
        ah1(i) = 0;
    end
end
reluh1 = num2cell(arrayfun(@(o) dec2q(o,3,12), ah1));
z1=[1;ah1]; % augmented output of hidden layer 1
ah2=Wh2new'*z1; % activation (net input) of hidden layer 2
h2 = num2cell(arrayfun(@(o) dec2q(o,3,12), ah2));
csvwrite('h2.csv', ah2);
cell2csv('h2_q.csv', h2);
for i=1:length(ah2) % Relu activation function
    if ah2(i) < 0
        ah2(i) = 0;
    end
end
reluh2 = num2cell(arrayfun(@(o) dec2q(o,3,12), ah2));
z2=[1;ah2]; % augmented output of hidden layer 1
ao=Wonew'*z2; % activation (net input) of output layer
ol = num2cell(arrayfun(@(o) dec2q(o,3,12), ao));
csvwrite('ol.csv', ao);
cell2csv('ol_q.csv', ol);
for i=1:length(ao) % Relu activation function
    if ao(i) < 0
        ao(i) = 0;
    end
end
yp=ao'; % output of output layer

expected = num2cell(arrayfun(@(o) dec2q(o,3,12), yp));
csvwrite('expected.csv', yp);
cell2csv('expected_q.csv', expected);
%% test accuracy 3 layers
Nsamps = 2240;
X=load("data1.txt");
%X=X/1024;
hidden1 = relu(Wh1old'*[ones(Nsamps,1) X]');
hidden2 = relu(Wh2old'*[ones(1,Nsamps); hidden1]);
hidden3 = relu(Wh3old'*[ones(1,Nsamps); hidden2]);
Yp=relu(Woold'*[ones(1,Nsamps); hidden3])'; % forward pass to get output Yp given X

Y=zeros(2240,10);
Y(1:224,:)=[ones(224,1) zeros(224,9)];
Y(225:448,:)=[zeros(224,1) ones(224,1) zeros(224,8)];
Y(449:672,:)=[zeros(224,2) ones(224,1) zeros(224,7)];
Y(673:896,:)=[zeros(224,3) ones(224,1) zeros(224,6)];
Y(897:1120,:)=[zeros(224,4) ones(224,1) zeros(224,5)];
Y(1121:1344,:)=[zeros(224,5) ones(224,1) zeros(224,4)];
Y(1345:1568,:)=[zeros(224,6) ones(224,1) zeros(224,3)];
Y(1569:1792,:)=[zeros(224,7) ones(224,1) zeros(224,2)];
Y(1793:2016,:)=[zeros(224,8) ones(224,1) zeros(224,1)];
Y(2017:2240,:)=[zeros(224,9) ones(224,1)];

Ynew=zeros(Nsamps,1);
Ypnew=zeros(Nsamps,1);
for i=1:Nsamps
    Ynew(i)=find(Y(i,:)==1);
    val = find(Yp(i,:)==max(Yp(i,:)));
    if length(val) ~= 1
        Ypnew(i) = randi(10);
    else
        Ypnew(i) = val;
    end
end
[Cm error]=ConfusionMatrix(Ynew,Ypnew);

%% test accuracy - 2 layers
Nsamps = 2240;
X=load("data1.txt");
X=X/256;
hidden1 = relu(Wh1new'*[ones(Nsamps,1) X]');
hidden2 = relu(Wh2new'*[ones(1,Nsamps); hidden1]);
Yp=relu(Wonew'*[ones(1,Nsamps); hidden2])'; % forward pass to get output Yp given X

Y=zeros(2240,10);
Y(1:224,:)=[ones(224,1) zeros(224,9)];
Y(225:448,:)=[zeros(224,1) ones(224,1) zeros(224,8)];
Y(449:672,:)=[zeros(224,2) ones(224,1) zeros(224,7)];
Y(673:896,:)=[zeros(224,3) ones(224,1) zeros(224,6)];
Y(897:1120,:)=[zeros(224,4) ones(224,1) zeros(224,5)];
Y(1121:1344,:)=[zeros(224,5) ones(224,1) zeros(224,4)];
Y(1345:1568,:)=[zeros(224,6) ones(224,1) zeros(224,3)];
Y(1569:1792,:)=[zeros(224,7) ones(224,1) zeros(224,2)];
Y(1793:2016,:)=[zeros(224,8) ones(224,1) zeros(224,1)];
Y(2017:2240,:)=[zeros(224,9) ones(224,1)];

Ynew=zeros(Nsamps,1);
Ypnew=zeros(Nsamps,1);
for i=1:Nsamps
    Ynew(i)=find(Y(i,:)==1);
    val = find(Yp(i,:)==max(Yp(i,:)));
    if length(val) ~= 1
        Ypnew(i) = randi(10);
    else
        Ypnew(i) = val;
    end
end
[Cm error]=ConfusionMatrix(Ynew,Ypnew);
%%
function ret=relu(nodes) % compute relu for nodes for all samples (nodes is 30x2240 for hidden)
    [D Nsamps]=size(nodes); % Nsamps is number of samples, D is dimension
    ret = ones(D, Nsamps);
    for i = 1:D
       for j = 1:Nsamps
           if nodes(i,j) < 0
               ret(i,j) = 0;
           else
               ret(i,j) = nodes(i,j);
           end
       end
    end
end

function [Cm er]=ConfusionMatrix(y,yp)
    N=length(y);            % number of samples
    K=length(unique(y));    % number of classes
	Cm=zeros(K);            % initialize confusion matrix
    for n=1:N
        Cm(y(n),yp(n))=Cm(y(n),yp(n))+1; % fill in confusion matrix
    end
    er=1-trace(Cm)/sum(sum(Cm)); % er=0 means 0% error.  All classifications are correct
end
