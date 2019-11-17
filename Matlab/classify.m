%% Sigmoid activation function
%load hidden_weights.mat;
%load output_weights.mat;

%syms x
%g=(2/(1+exp(-x)) - 1);    % Sigmoid activation function
%g=matlabFunction(g);

% ah=Wh'*xtrain; % activation (net input) of hidden layer
% z=[1;g(ah)]; % augmented output of hidden layer
% ao=Wo'*z; % activation (net input) of output layer
% yp=g(ao)'; % output of output layer

%% Relu activation function
load weights.mat;

hw = num2cell(arrayfun(@dec2q, Whnew));
cell2csv('hiddenweights.csv', hw)
ow = num2cell(arrayfun(@dec2q, Wonew));
cell2csv('outputweights.csv', ow)

X=load("data1.txt");
X = X/65536; % convert X to Q16.  Shift right by 16
xtrain = X(4,:)';
xtrain = [1;xtrain];
csvwrite('xtrain.csv', xtrain)
xt = num2cell(arrayfun(@dec2q, xtrain));
cell2csv('xtrain_q15.csv', xt)

ah=Whnew'*xtrain; % activation (net input) of hidden layer
hl_norelu = num2cell(arrayfun(@dec2q, ah));
cell2csv('hl_norelu.csv', hl_norelu)
for i=1:length(ah) % Relu activation function
    if ah(i) < 0
        ah(i) = 0;
    end
end
z=[1;ah]; % augmented output of hidden layer
hl_relu = num2cell(arrayfun(@dec2q, z));
cell2csv('hl_relu.csv', hl_relu)
ao=Wonew'*z; % activation (net input) of output layer
for i=1:length(ao) % Relu activation function
    if ao(i) < 0
        ao(i) = 0;
    end
end
yp=ao'; % output of output layer
expected = num2cell(arrayfun(@dec2q, yp));
cell2csv('expected.csv', expected)