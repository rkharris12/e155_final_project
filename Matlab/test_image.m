%% load weights and image

clear
%load weights_2layers_15nodes_new.mat % this overflows -1 to 1.  But minimum value is -6.  Max is 4.  So use Q3_12 => 4 integer, 12 decimal
load weights_2layers_15nodes_99percent.mat
%% feedforward to get classification
%xtrain = load("pic.txt");
pic = load("pic.txt");
% try making bright pixels 255
% for i=1:(length(pic))
%     for j=1:(length(pic))
%         if pic(i,j) > 75
%             pic(i,j)=255;
%         end
%     end
% end
xtrain = pic;

xtrain = reshape(xtrain',[1,256]);
xtrain = [255;xtrain'];
xtrain = xtrain/256;
ah1=Wh1new'*xtrain; % activation (net input) of hidden layer 1
for i=1:length(ah1) % Relu activation function
    if ah1(i) < 0
        ah1(i) = 0;
    end
end
z1=[1;ah1]; % augmented output of hidden layer 1
ah2=Wh2new'*z1; % activation (net input) of hidden layer 2
for i=1:length(ah2) % Relu activation function
    if ah2(i) < 0
        ah2(i) = 0;
    end
end
z2=[1;ah2]; % augmented output of hidden layer 1
ao=Wonew'*z2; % activation (net input) of output layer
for i=1:length(ao) % Relu activation function
    if ao(i) < 0
        ao(i) = 0;
    end
end
yp=ao'; % output of output layer

