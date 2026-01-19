function [num, den, P, X] = RLS(entrada_sistema, salida_sistema, n, d, P, X, f_olvido)
    % Recursive Least Squares (RLS) algorithm
    %
% Arguments:
%   - entrada_sistema: current system input (double)
%   - salida_sistema: current system output (double)
%   - n: transfer function numerator (double)
%   - d: transfer function denominator (vector)
%   - P: covariance matrix (matrix)
%   - X: regressor vector of inputs and outputs (column vector)
%   - f_olvido: forgetting factor (default 0.9) (double)
    %
    % Returns:
%   - num: updated transfer function numerator (double)
%   - den: updated transfer function denominator (vector)
%   - P: updated covariance matrix (matrix)
%   - X: updated regressor vector (vector)
    
    % Default forgetting factor
    if nargin < 7
        f_olvido = 0.9;
    end
    
    % This RLS implementation assumes a 2nd-order system
    
    % Initialize X and P if empty
    if isempty(X) || isempty(P)
        X = rand(3,1) / 1000;           % Small random vector
        P = eye(3) * 10000;             % Identity matrix with large initial value
    end
    
    % Build Theta vector
    Theta = [n; -d(2); -d(3)];
    
    % Update regressor X
    X(1,1) = entrada_sistema;
    
    % Compute gain matrix K for current step
    K = (P * X) / (f_olvido + X' * P * X);
    
    % Error
    Error = salida_sistema - X' * Theta;
    
    % Update coefficients
    Theta = Theta + K * Error;
    
    % Update P for next iteration
    P = (1 / f_olvido) * (P - K * X' * P);
    
    % Shift regressor with new input/output values
    X(3,1) = X(2,1);
    X(2,1) = salida_sistema;
    
    % Extract numerator and denominator from Theta
    num = Theta(1,1);
    den = [1, -Theta(2,1), -Theta(3,1)];
    
end