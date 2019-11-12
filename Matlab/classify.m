load hidden_weights.mat;
load output_weights.mat;

X=load("data1.txt"); 
xtrain = X(1,:)';
xtrain = [1;xtrain];

syms x
g=(2/(1+exp(-x)) - 1);    % Sigmoid activation function
g=matlabFunction(g);

ah=Wh'*xtrain; % activation (net input) of hidden layer
z=[1;g(ah)]; % augmented output of hidden layer
ao=Wo'*z; % activation (net input) of output layer
yp=g(ao)'; % output of output layer