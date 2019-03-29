%clear memory
clear;

load data2
y=1;
% calculate combinatorial Laplacian Matrix
d = sum(WW,2);
L = diag(d)-WW;
% calculate  Laplacian Matrix

% find eigenvector and eigenvalues of combinatorial Laplacian
[u v]=eig(L);

% make eignevalue as vector
v=diag(v);
% get maximum eigenvalue
lmax=max(v);
v(v<0)=0;

% create signal where first node is 1 rest of them zero
s=randn(size(WW,1),2);
%s(1)=1;
n=size(WW,1);
nf=size(s,2);

K=40;
nv=linspace(0,8,K);
basis=bspline_basis(K, nv,v, 3);

% hidden layer features
hfeat=[10 20];
%hfeat=[1 1];

W1 = 0.01*randn(K*nf, hfeat(1));
W2 = 0.01*randn(K*hfeat(1), hfeat(2));
W3 = 0.01*randn(hfeat(2), 1);
%W3 = 0.01*randn(1, 1);
m_W1 = 0; v_W1 = 0;
m_W2 = 0; v_W2 = 0;
m_W3 = 0; v_W3 = 0;
step = 0;

Sx=createS(u,s,basis);

for epoch = 1:10000
    
    
    %K1=u*diag(basis*W1)*u';
    K11=u*diag(basis*W1(1:K,1))*u';
    K21=u*diag(basis*W1(1:K,2))*u';
    
    K12=u*diag(basis*W1(K+1:end,1))*u';
    K22=u*diag(basis*W1(K+1:end,2))*u';
    %K2=u*diag(basis*W2)*u';
    
    y11 =activation_tanh([K11 K12;K21 K22]*s(:));
    
    %y1 =activation_tanh(K1*s);
    y1=activation_tanh(Sx*W1);
    Sy1=createS(u,y1,basis);
    %y2 =activation_tanh(K2*y1);
    y2=activation_tanh(Sy1*W2);
    
    %y3=y2'*W3;
    y3=sum(y2*W3);
    
    error = mean((y3-y).^2)
    
    dedy3=2*(y3-y);
%     dedw3=y2*dedy3;
    dedw3=sum(y2)*dedy3;
    
    dedy2=(dedy3*W3).*activation_tanh_gradient(y2);
    Sy1=createS(u,y1,basis);
    dedw2=Sy1'*dedy2;
    
    dedy1=(dedy2'*K2 )'.*activation_tanh_gradient(y1);
    dedw1=Sx'*dedy1;
    
    step = step + 1;
    m_W1 = (0.9 * m_W1 + 0.1 * dedw1);
    v_W1 = (0.999 * v_W1 + 0.001 * dedw1.^2);
    W1 = W1 - 0.01 * (m_W1/(1-0.9^step)) ./ sqrt(v_W1/(1-0.999^step) + 1e-8);
    
    m_W2 = (0.9 * m_W2 + 0.1 * dedw2);
    v_W2 = (0.999 * v_W2 + 0.001 * dedw2.^2)/(1-0.999^step);
    W2 = W2 - 0.01 * (m_W2/(1-0.9^step)) ./ sqrt(v_W2/(1-0.999^step) + 1e-8);
    
    m_W3 = (0.9 * m_W3 + 0.1 * dedw3);
    v_W3 = (0.999 * v_W3 + 0.001 * dedw3.^2);
    W3 = W3 - 0.01 * (m_W3/(1-0.9^step)) ./ sqrt(v_W3/(1-0.999^step) + 1e-8);
end






% prepare data and initialize the network
% Generate 1000 training data points
X_all = [0.001 * (1 : 1000)' 0.001*(1000-(1:1000))' 0.001*(1000-(1:1000))']; % shape [1000, 2]
y_all = [cos(3 * pi * X_all(:, 1))  sin(pi* X_all(:, 2)) + 2]; % shape [1000, 1]
n_sample = length(X_all(:, 1));

% Initialization network parameters.
% The training data are split to many "batches".
% In this lab, each batch has 50 data points
% Model training (the forward-backward propagation)
% is performed on batch-by-batch.
batch_size = 100;

nfin=size(X_all,2);
nfout=size(y_all,2);


W1 = 0.01*randn(nfin, 256);
W2 = 0.01*randn(256, 256);
W3 = 0.01*randn(256, nfout);

m_W1 = 0; v_W1 = 0;
m_W2 = 0; v_W2 = 0;
m_W3 = 0; v_W3 = 0;
step = 0;

for epoch = 1:550
    
    % permute the training dataset for each epoch
    perm = randperm(n_sample);
    Xp = X_all(perm,:);
    yp = y_all(perm,:);
    y_pred = zeros(n_sample, nfout);
    total_error=0;
    
    
    for i = 1:(n_sample/batch_size)
        
        % Prepare data for the current batch
        d_start = batch_size * (i - 1);
        x = Xp(d_start+(1:batch_size), :);
        y = yp(d_start+(1:batch_size),:);
        
        
        y1=activation_tanh(x*W1);
        y2=activation_tanh(y1*W2);
        y3=y2*W3;
        
        error = mean((y3-y).^2);
        %error = ((y3-y).^2);
        total_error = total_error + error;
        y_pred(d_start+(1:batch_size),:) = y3;
        
        
        dedy3=2*(y3-y);
        dedw3=y2'*dedy3;
        
        dedy2=(dedy3*W3').*activation_tanh_gradient(y2);
        dedw2=y1'*dedy2;
        
        dedy1=(dedy2*W2 ).*activation_tanh_gradient(y1);
        dedw1=x'*dedy1;
        
        %         W1=W1-0.001*dedw1;
        %         W2=W2-0.001*dedw2;
        %         W3=W3-0.001*dedw3;
        
        
        % ---------------------Update-------------------------
        % Using optimizer: Adam SGD
        % For reference see: https://arxiv.org/abs/1412.6980
        % for this lab, you do not have to know it
        % just regard optimizer as a function (blackbox).
        
        step = step + 1;
        m_W1 = (0.9 * m_W1 + 0.1 * dedw1);
        v_W1 = (0.999 * v_W1 + 0.001 * dedw1.^2);
        W1 = W1 - 0.01 * (m_W1/(1-0.9^step)) ./ sqrt(v_W1/(1-0.999^step) + 1e-8);
        
        m_W2 = (0.9 * m_W2 + 0.1 * dedw2);
        v_W2 = (0.999 * v_W2 + 0.001 * dedw2.^2)/(1-0.999^step);
        W2 = W2 - 0.01 * (m_W2/(1-0.9^step)) ./ sqrt(v_W2/(1-0.999^step) + 1e-8);
        
        m_W3 = (0.9 * m_W3 + 0.1 * dedw3);
        v_W3 = (0.999 * v_W3 + 0.001 * dedw3.^2);
        W3 = W3 - 0.01 * (m_W3/(1-0.9^step)) ./ sqrt(v_W3/(1-0.999^step) + 1e-8);
    end
    total_error
    
end

