function [u, Kp, Td, Ti] = PID_dahlin(numerator, denominator, errors, u_history, Tm, B)
    % Function to run the Dahlin PID (self-tuning)
    %
    % Gains are computed from the transfer function coefficients (b0, a0, a1)
    %
    % Arguments:
    %   - numerator: numerator coefficients of the transfer function (double)
    %   - denominator: denominator coefficients of the transfer function (vector)
    %   - errors: error values (sp - pv) (vector)
    %   - u_history: control signal history (vector)
    %   - Tm: sampling time (double)
    %   - B: tuning factor. Smaller B → faster system response (double)
    %
    % Returns:
    %   - u: control signal (double)
    
    % Default B value
    if nargin < 6
        B = 1;
    end
    
    % Extract coefficients
    b1 = numerator;
    a1 = denominator(2);  % MATLAB indexing starts at 1
    a2 = denominator(3);  % MATLAB indexing starts at 1
    
    % Compute Dahlin PID gains
    Q = 1 - exp(-Tm / B);
    Kp = -((a1 + 2*a2) * Q) / b1;
    Td = (Tm * a2 * Q) / (Kp * b1);
    Ti = -Tm / (1 / (a1 + 2*a2) + 1 + (Td / Tm));
    
    % Compute control signal
    
    % PID terms
    term_P = errors(end) - errors(end-1);
    term_I = (Tm / Ti) * errors(end);
    term_D = (Td/Tm) * (errors(end) - 2*errors(end-1) + errors(end-2));
    
    % Control signal
    u = Kp * (term_P + term_I + term_D) + u_history(end);
    
    % Output saturation
    if u > 100
        u = 100;
    elseif u < 0
        u = 0;
    end
    
end