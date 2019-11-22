function main

    close all
    clear
    rng(4)
    
    X=load("data1.txt"); % 2240x256 dimensional, 10 class handwritten number data
    
    % labels for handwritten digit data, the location in the array
    % corresponds to the digit, first 224 are 0, next 224 are 1, ...
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

    Yp=BackpropagationNetwork(X,Y); % (2240x10) get the results
    
    % convert Y and Yp to 1-D integer labels (1 to 10) so my confusion
    % matrix function can work on them
    Ynew=zeros(2240,1);
    Ypnew=zeros(2240,1);
    for i=1:2240
            Ynew(i)=find(Y(i,:)==1);
            Ypnew(i)=find(Yp(i,:)==max(Yp(i,:)));
    end
    [Cm error]=ConfusionMatrix(Ynew,Ypnew);
    Cm
    error
    
    % example image
    figure(1)
    showImage(X(500,:));
end



function Yp=BackpropagationNetwork(X,Y)
    [Nsamps D]=size(X); % Nsamps is number of samples (2240), D is dimension (256)
    N=D; M=10; % number of input layer nodes and output layer nodes, respectively
    L1=150; % number of hidden layer 1 nodes
    L2=150; % number of hidden layer 2 nodes
    %L3=30; % number of hidden layer 3 nodes
    % convert X to Q16.  Shift right by 16
    xscale=256;
    X = X/xscale;
    yscale = 10;
    Y=Y/yscale;
    wscale=50;
    Wh1new=(2*rand(N+1,L1)-ones(N+1,L1))/wscale; % (257xL1) randomly initialize N+1 dimensional (includes bias b) augmented hidden weight vectors Wh1=[wh1 wh2...whL].  Values between -0.25 and 0.25
    Wh2new=(2*rand(L1+1,L2)-ones(L1+1,L2))/wscale; % (L1+1xL2) randomly initialize L1+1 dimensional (includes bias b) augmented hidden weight vectors Wh2=[wh1 wh2...whL].  Values between -0.25 and 0.25
    %Wh3new=(2*rand(L2+1,L3)-ones(L2+1,L3))/wscale; % (L2+1xL3) randomly initialize L1+1 dimensional (includes bias b) augmented hidden weight vectors Wh3=[wh1 wh2...whL].  Values between -0.25 and 0.25
    Wonew=(2*rand(L2+1,M)-ones(L2+1,M))/wscale; % (L2+1x10) randomly initialize L2+1 dimensional (includes bias b) augmented output weight vectors Wo=[wo1 wo2...woM].  Values between -0.25 and 0.25
    eta=0.01; % learning rate
    tolerance=2*10^-2;
    error=inf;
    iter=0;
    dgh1 = ones(L1,1);
    dgh2 = ones(L2,1);
    %dgh3 = ones(L3,1);
    dgo = ones(M,1);
    while error>tolerance
        iter=iter+1;
        Wh1old=Wh1new;
        Wh2old=Wh2new;
        %Wh3old=Wh3new;
        Woold=Wonew;
        n=randi(Nsamps);
        xtrain=X(n,:)'; % (256x1) randomly select a training sample
        xtrain=[1;xtrain]; % (257x1) D+1 augmented training sample to include bias b=1
        ytrain=Y(n,:); % (1x10) randomly selected training sample's corresponding label
        flag=0; % overflow flag
        
        % forward pass
        ah1=Wh1old'*xtrain; % activation (net input) of hidden layer 1
        for i=1:length(ah1) % Relu activation function
            if (ah1(i) >= 1) || (ah1(i) <= -1) % prevent overflow
                flag=1;
                break;
            end
            if ah1(i) < 0
                ah1(i) = 0;
                dgh1(i) = 0;
            else
                dgh1(i) = 1;
            end
        end
        if flag==1
            break;
        end
        z1=[1;ah1]; % augmented output of hidden layer 1
        ah2=Wh2old'*z1; % activation (net input) of hidden layer 2
        for i=1:length(ah2) % Relu activation function
            if (ah2(i) >= 1) || (ah2(i) <= -1) % prevent overflow
                flag=1;
                break;
            end
            if ah2(i) < 0
                ah2(i) = 0;
                dgh2(i) = 0;
            else
                dgh2(i) = 1;
            end
        end
        if flag==1
            break;
        end
        z2=[1;ah2]; % augmented output of hidden layer 2
%         ah3=Wh3old'*z2; % activation (net input) of hidden layer 3
%         for i=1:length(ah3) % Relu activation function
%             if (ah3(i) >= 1) || (ah3(i) <= -1) % prevent overflow
%                 flag=1;
%                 break;
%             end
%             if ah3(i) < 0
%                 ah3(i) = 0;
%                 dgh3(i) = 0;
%             else
%                 dgh3(i) = 1;
%             end
%         end
%         if flag==1
%             break;
%         end
%         z3=[1;ah3]; % augmented output of hidden layer 3
        ao=Woold'*z2; % activation (net input) of output layer
        for i=1:length(ao) % Relu activation function
            if (ao(i) >= 1) || (ao(i) <= -1) % prevent overflow
                flag=1;
                break;
            end
            if ao(i) < 0
                ao(i) = 0;
                dgo(i) = 0;
            else
                dgo(i) = 1;
            end
        end
        if flag==1
            break;
        end
        yp=ao'; % output of output layer
        
        % backward error propagation
        % 3 layers
%         do=(ytrain'-yp').*dgo; % find d of output layer (Mx1 vector)
%         dh3=(Woold(2:L3+1,1:M)*do).*dgh3; % find d of hidden layer 3 (L3x1 vector).  Remove the first row of Wo: the bias offset
%         dh2=(Wh3old(2:L2+1,1:L3)*dh3).*dgh2; % find d of hidden layer 2 (L2x1 vector).  Remove the first row of Wh3: the bias offset
%         dh1=(Wh2old(2:L1+1,1:L2)*dh2).*dgh1; % find d of hidden layer 1 (L1x1 vector).  Remove the first row of Wh2: the bias offset
% 
%         Wonew=Woold+(eta*do*z3')'; % update weights of output layer
%         Wh3new=Wh3old+(eta*dh3*z2')'; % update weights of hidden layer 3
%         Wh2new=Wh2old+(eta*dh2*z1')'; % update weights of hidden layer 2
%         Wh1new=Wh1old+(eta*dh1*xtrain')'; % update weights of hidden layer 1

        % 2 layers
        do=(ytrain'-yp').*dgo; % find d of output layer (Mx1 vector)
        dh2=(Woold(2:L2+1,1:M)*do).*dgh2; % find d of hidden layer 2 (L2x1 vector).  Remove the first row of Wo: the bias offset
        dh1=(Wh2old(2:L1+1,1:L2)*dh2).*dgh1; % find d of hidden layer 1 (L1x1 vector).  Remove the first row of Wh2: the bias offset
        
        Wonew=Woold+(eta*do*z2')'; % update weights of output layer
        Wh2new=Wh2old+(eta*dh2*z1')'; % update weights of hidden layer 2
        Wh1new=Wh1old+(eta*dh1*xtrain')'; % update weights of hidden layer 1

%         if ~any(do) || ~any(dh3) || ~any(dh2) || ~any(dh1) % check if the network is being trained properly
%             break;
%         end

        if min(min(Wh1new))<-1 || max(max(Wh1new))>1 || min(min(Wh2new))<-1 || max(max(Wh2new))>1 || min(min(Wonew))<-1 || max(max(Wonew))>1 % check for overflow
            break;
        end
        
        if ~mod(iter,1000) % check error every 100000 iterations
            % 2 layer
            hidden1 = relu(Wh1new'*[ones(Nsamps,1) X]');
            hidden2 = relu(Wh2new'*[ones(1,Nsamps); hidden1]);
            Yp=relu(Wonew'*[ones(1,Nsamps); hidden2])'; % forward pass to get output Yp given X
            % 3 layer
%             hidden1 = relu(Wh1new'*[ones(Nsamps,1) X]');
%             hidden2 = relu(Wh2new'*[ones(1,Nsamps); hidden1]);
%             hidden3 = relu(Wh3new'*[ones(1,Nsamps); hidden2]);
%             Yp=relu(Wonew'*[ones(1,Nsamps); hidden3])'; % forward pass to get output Yp given X
            % convert Y and Yp to 1-D integer labels so my confusion matrix
            % function can work on them
            Ynew=zeros(Nsamps,1);
            Ypnew=zeros(Nsamps,1);
            for i=1:Nsamps
                Ynew(i)=find(Y(i,:)==1/yscale);
                val = find(Yp(i,:)==max(Yp(i,:)));
                if length(val) ~= 1
                    Ypnew(i) = randi(10);
                else
                    Ypnew(i) = val;
                end
            end
            [Cm error]=ConfusionMatrix(Ynew,Ypnew);
        end
    end
    % 2 layer
    hidden1 = relu(Wh1new'*[ones(Nsamps,1) X]');
    hidden2 = relu(Wh2new'*[ones(1,Nsamps); hidden1]);
    Yp=relu(Wonew'*[ones(1,Nsamps); hidden2])'; % forward pass to get output Yp given X
    % 3 layer
%     hidden1 = relu(Wh1new'*[ones(Nsamps,1) X]');
%     hidden2 = relu(Wh2new'*[ones(1,Nsamps); hidden1]);
%     hidden3 = relu(Wh3new'*[ones(1,Nsamps); hidden2]);
%     Yp=relu(Wonew'*[ones(1,Nsamps); hidden3])'; % forward pass to get output Yp given X
end


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


function showImage(mk) % displays image.  Input is a single row of X (1x256)
    % convert x to a value from 0 to 1
    xmin=min(mk);
    xmax=max(mk);
    s=1/(xmax-xmin);
    for i=1:(length(mk))
        mk(i)=(mk(i)-xmin)*s;  % Convert to entire dynamic range  
    end   
    m=reshape(mk,[16 16]);
    hold on
    for i=1:16
        for j=1:16
            val=m(i,j);
            scatter(i,17-j,1000,[val val val],'filled','s');
        end
    end
    hold off
end



% calculate confusion matrix and error rate
function [Cm er]=ConfusionMatrix(y,yp)
    N=length(y);            % number of samples
    K=length(unique(y));    % number of classes
	Cm=zeros(K);            % initialize confusion matrix
    for n=1:N
        Cm(y(n),yp(n))=Cm(y(n),yp(n))+1; % fill in confusion matrix
    end
    er=1-trace(Cm)/sum(sum(Cm)); % er=0 means 0% error.  All classifications are correct
end
