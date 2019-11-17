clear

%load weights.mat;
load weights_new.mat;

X=load("data1.txt");
X = X/65536; % convert X to Q16.  Shift right by 16
xtrain = X(2,:)';
xtrain = [1;xtrain];

ah1=Wh1new'*xtrain; % activation (net input) of hidden layer 1
for i=1:length(ah1) % Relu activation function
    if ah1(i) < 0
        ah1(i) = 0;
        dgh1(i) = 0;
    else
        dgh1(i) = 1;
    end
end
z1=[1;ah1]; % augmented output of hidden layer 1
ah2=Wh2new'*z1; % activation (net input) of hidden layer 2
for i=1:length(ah2) % Relu activation function
    if ah2(i) < 0
        ah2(i) = 0;
        dgh2(i) = 0;
    else
        dgh2(i) = 1;
    end
end
z2=[1;ah2]; % augmented output of hidden layer 2
ao=Wonew'*z2; % activation (net input) of output layer
for i=1:length(ao) % Relu activation function
    if ao(i) < 0
        ao(i) = 0;
        dgo(i) = 0;
    else
        dgo(i) = 1;
    end
end
yp=ao'; % output of output layer