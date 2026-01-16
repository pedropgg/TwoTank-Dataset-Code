function [u, Kp, Td, Ti] = PID_dahlin(numerador, denominador, e, u_prev, Tm, B)
    % Función para ejecutar el PID de Dahlin (autoajustable)
    %
    % Se obtienen los valores de las constantes a partir de los valores de los coeficientes
    % de la función de transferencia (b0, a0 y a1)
    %
    % Argumentos:
    %   - numerador: coeficientes del numerador de la función de transferencia (double)
    %   - denominador: coeficientes del denominador de la función de transferencia (vector)
    %   - e: valores de error (sp-pv) (vector)
    %   - u_prev: valores de la señal de control (vector)
    %   - Tm: tiempo de muestreo (double)
    %   - B: factor de ajuste. Cuanto menor valor de B la respuesta del sistema es más rápida (double)
    %
    % Returns:
    %   - u: señal de control (double)
    
    % Valor por defecto de B
    if nargin < 6
        B = 1;
    end
    
    % Extraemos los coeficientes
    b1 = numerador;
    a1 = denominador(2);  % MATLAB indexa desde 1
    a2 = denominador(3);  % MATLAB indexa desde 1
    
    % Calculamos las constantes del PID de Dahlin
    Q = 1 - exp(-Tm / B);
    Kp = -((a1 + 2*a2) * Q) / b1;
    Td = (Tm * a2 * Q) / (Kp * b1);
    Ti = -Tm / (1 / (a1 + 2*a2) + 1 + (Td / Tm));
    
    % Calculamos la señal de control
    
    % Términos del PID
    termino_P = e(end) - e(end-1);
    termino_I = (Tm / Ti) * e(end);
    termino_D = (Td/Tm) * (e(end) - 2*e(end-1) + e(end-2));
    
    % Señal de control
    u = Kp * (termino_P + termino_I + termino_D) + u_prev(end);
    
    % Control del valor de la salida (saturación)
    if u > 100
        u = 100;
    elseif u < 0
        u = 0;
    end
    
end