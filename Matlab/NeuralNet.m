function main

    close all
    figure(1)
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
    showImage(X(500,:));
end



function Yp=BackpropagationNetwork(X,Y)
    [Nsamps D]=size(X); % Nsamps is number of samples (2240), D is dimension (256)
    N=D; M=10; % number of input layer nodes and output layer nodes, respectively
    L=30; % number of hidden layer nodes
    % convert X to Q16.  Shift right by 16
    X = X/65536;
    syms x
    Whnew=(2*rand(N+1,L)-ones(N+1,L))/2; % (257x20) randomly initialize N+1 dimensional (includes bias b) augmented hidden weight vectors Wh=[wh1 wh2...whL].  Values between -0.5 and 0.5
    Wonew=(2*rand(L+1,M)-ones(L+1,M))/2; % (31x10) randomly initialize L+1 dimensional (includes bias b) augmented output weight vectors Wh=[wo1 wo2...woM].  Values between -0.5 and 0.5
    eta=0.01; % learning rate
    tolerance=2*10^-2;
    error=inf;
    iter=0;
    dgo = ones(M,1);
    dgh = ones(L,1);
    while error>tolerance
        iter=iter+1;
        Whold=Whnew;
        Woold=Wonew;
        n=randi(Nsamps);
        xtrain=X(n,:)'; % (256x1) randomly select a training sample
        xtrain=[1;xtrain]; % (257x1) D+1 augmented training sample to include bias b=1
        ytrain=Y(n,:); % (1x10) randomly selected training sample's corresponding label
        
        % forward pass
        ah=Whold'*xtrain; % activation (net input) of hidden layer
        for i=1:length(ah) % Relu activation function
            if ah(i) < 0
                ah(i) = 0;
                dgh(i) = 0;
            else
                dgh(i) = 1;
            end
        end
        z=[1;ah]; % augmented output of hidden layer
        ao=Woold'*z; % activation (net input) of output layer
        for i=1:length(ao) % Relu activation function
            if ao(i) < 0
                ao(i) = 0;
                dgo(i) = 0;
            else
                dgo(i) = 1;
            end
        end
        yp=ao'; % output of output layer
        
        % backward error propagation
        do=(ytrain'-yp').*dgo; % find d of output layer (Mx1 vector)
        dh=(Woold(2:L+1,1:M)*do).*dgh; % find d of hidden layer (Lx1 vector).  Remove the first row of Wo: the bias offset
        Wonew=Woold+(eta*do*z')'; % update weights of output layer
        Whnew=Whold+(eta*dh*xtrain')'; % update weights of hidden layer
        
        if ~mod(iter,100000) % check error every 1000 iterations
            hidden = relu(Whnew'*[ones(Nsamps,1) X]');
            Yp=relu(Wonew'*[ones(1,Nsamps); hidden])'; % forward pass to get output Yp given X
            % convert Y and Yp to 1-D integer labels so my confusion matrix
            % function can work on them
            Ynew=zeros(Nsamps,1);
            Ypnew=zeros(Nsamps,1);
            for i=1:Nsamps
                Ynew(i)=find(Y(i,:)==1);
                %find(Yp(i,:)==max(Yp(i,:)))
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
    hidden = relu(Whnew'*[ones(Nsamps,1) X]');
    Yp=relu(Wonew'*[ones(1,Nsamps); hidden])'; % forward pass to get output Yp given X
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