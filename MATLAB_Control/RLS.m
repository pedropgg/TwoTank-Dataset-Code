function [num, den, P, X] = RLS(entrada_sistema, salida_sistema, n, d, P, X, f_olvido)
    % Función para la ejecución del algoritmo RLS
    %
    % Argumentos:
    %   - entrada_sistema: entrada actual al sistema (double)
    %   - salida_sistema: salida actual del sistema (double)
    %   - n: numerador de la función de transferencia (double)
    %   - d: denominador de la función de transferencia (vector)
    %   - P: matriz de covarianzas (matrix)
    %   - X: vector regresor de entrada y salidas (vector columna)
    %   - f_olvido: factor de olvido (por defecto 0.9) (double)
    %
    % Returns:
    %   - num: numerador de la función de transferencia actualizado (double)
    %   - den: denominador de la función de transferencia actualizado (vector)
    %   - P: matriz de covarianzas actualizada (matrix)
    %   - X: vector regresor de entradas y salidas actualizado (vector)
    
    % Valor por defecto del factor de olvido
    if nargin < 7
        f_olvido = 0.9;
    end
    
    % Creamos un par de variables internas
    % La función RLS implementada corresponde con un sistema de 2º orden
    
    % Comprobamos si se crearon las matrices X y P
    if isempty(X) || isempty(P)
        X = rand(3,1) / 1000;           % Vector aleatorio pequeño
        P = eye(3) * 10000;             % Matriz identidad con valor grande inicial
    end
    
    % Obtenemos el vector Theta
    Theta = [n; -d(2); -d(3)];
    
    % Actualización del vector X
    X(1,1) = entrada_sistema;
    
    % Calculamos la matriz K del sistema para el instante actual
    K = (P * X) / (f_olvido + X' * P * X);
    
    % Cálculo del error
    Error = salida_sistema - X' * Theta;
    
    % Nuevos coeficientes
    Theta = Theta + K * Error;
    
    % Cálculo matriz P para la siguiente iteración
    P = (1 / f_olvido) * (P - K * X' * P);
    
    % Actualizamos el vector X con los nuevos valores de entrada y salida
    X(3,1) = X(2,1);
    X(2,1) = salida_sistema;
    
    % Obtenemos el valor del numerador y denominador a partir del vector theta
    num = Theta(1,1);
    den = [1, -Theta(2,1), -Theta(3,1)];
    
end