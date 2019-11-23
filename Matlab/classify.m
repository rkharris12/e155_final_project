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

%% Do this for 150 node layers
% reshape weight matricies to have columns of size 15
% this allows us to fully compute the first 15 nodes of the next layer,
% followed by the next 15 nodes, and so on, by stepping through each row in
% the weights ROM
wh1 = [Wh1new(:,1:15); Wh1new(:,16:30); Wh1new(:,31:45); Wh1new(:,46:60); Wh1new(:,61:75); Wh1new(:,76:90); Wh1new(:,91:105); Wh1new(:,106:120); Wh1new(:,121:135); Wh1new(:,136:150)];
wh2 = [Wh2new(:,1:15); Wh2new(:,16:30); Wh2new(:,31:45); Wh2new(:,46:60); Wh2new(:,61:75); Wh2new(:,76:90); Wh2new(:,91:105); Wh2new(:,106:120); Wh2new(:,121:135); Wh2new(:,136:150)];
wo = [Wonew zeros(151,5)];
%% Do this for 15 node layers
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
