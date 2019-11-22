clear

load weights_2layers_150nodes.mat;

%% Do this for 30 node layers
% split weights matrices in half columnwise - ignore for 15 node layers
%Wh1half = [Wh1new(:,16:29) zeros(1,257)'];
%Wh2half = [Wh2new(:,16:29) zeros(1,30)'];
%Wopadded = [Wonew(:,1:10) zeros(5,30)'];
%Wohalf = [zeros(15,30)'];
% stack each matrix half on top of the other rowwise - ignore for 15 node layers
%wh1 = [Wh1new(:,1:15); Wh1half];
%wh2 = [Wh2new(:,1:15); Wh2half];
%wo = [Wopadded; Wohalf];
%% Do this for 15 node layers
wh1 = Wh1old;
wh2 = Wh2old;
wo = [Woold zeros(16,5)];
Wh1new = Wh1old;
Wh2new = Wh2old;
Wonew = Woold;
% make cells
wh1c = num2cell(arrayfun(@dec2q,wh1));
wh2c = num2cell(arrayfun(@dec2q,wh2));
woc = num2cell(arrayfun(@dec2q,wo));
% write csv's
csvwrite('wh1.csv', wh1);
csvwrite('wh2.csv', wh2);
csvwrite('wo.csv', wo);
cell2csv('wh1_q15.csv', wh1c);
cell2csv('wh2_q15.csv', wh2c);
cell2csv('wo_q15.csv', woc);

X=load("data1.txt");
xtrain = X(2,:)';
xtrain = [255;xtrain]; % do 255 because that will become effectively 1 when we do dec2hex
xconverted = dec2hex(xtrain);
xt = cellstr(xconverted);
csvwrite('xtrain.csv', xtrain);
cell2csv('xtrain_q15.csv', xt);

xtrain = xtrain/256;
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
z2=[1;ah2]; % augmented output of hidden layer 2
ao=Wonew'*z2; % activation (net input) of output layer
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
