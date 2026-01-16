clc, clear, close all
%Configuraci�n de setpoints y tiempos
setpoints = 50:5:60; %niveles deseados en por ciento
num_setpoints = length(setpoints);
tiempo_por_setpoint = 5 *60; %5 minutos 
%Tiempo de muestreo
Sample_Time=1;
%Tiempo total
Total_Time= num_setpoints * tiempo_por_setpoint;
%Cantidad de muestras
n= Total_Time/Sample_Time;
%Variables de control
P = [];
X = [];
num = rand();
den = [1, rand(), rand()];
e_hist = [0, 0, 0];  % Historial de errores
u_hist = [0,0];       % Historial de control
nivel_anterior = NaN;  % Para detector de fallos simple
%Inicializar variables de almacenamiento
Data=zeros(n,7);
Timestamps = datetime.empty(n, 0);
%Inicializar DAQ
DAQ_Start;
%Inicializar las salidas
Ctrl_Signal=0;
Output_1=0;
%Inicializar las variables de control de tiempo
tic
Initial_Time=toc;
%% Bucle de control y adqusici�n
contador=0;
for i=1:num_setpoints %para cada setpoint
    for j=1:tiempo_por_setpoint
        contador=contador+1;
        setpoint_actual = setpoints(i);
        
        %Adquisicion
        nivel_raw=DAQ_Read;
        if isfinite(nivel_anterior)
        cambio = abs(nivel_actual - nivel_anterior);
            if cambio > 6  % Umbral de cambio máximo
                nivel_actual = nivel_anterior+rand();
            else
                nivel_actual = nivel_raw;
            end
        else
            nivel_actual = nivel_raw;
        end    
        nivel_anterior=nivel_actual;
        % Capturar timestamp actual
        timestamp_actual = datetime('now');
        %Calculo del error
        error_actual = setpoint_actual - nivel_actual;
        e_hist = [e_hist(2:end), error_actual];
        %Aplicar algoritmo RLS para identificaci�n
        if contador>=2 % A partir de la segunda muestra se aplica RLS
             % Usar datos hist�ricos para RLS
                entrada_sistema = u_hist(end-1);
                salida_sistema = nivel_actual;
                [num, den, P, X] = RLS(entrada_sistema, salida_sistema, num, den, P, X, 0.9);
        end
        % Calcular nueva se�al de control usando PID Dahlin
            %try
            if contador>=3
                [u_new, Kp, Ti, Td] = PID_dahlin(num, den, e_hist, u_hist(end), Sample_Time, 3.0);
                Ki=Kp/Ti;
                Kd=Kp*Td;
            else
           % catch
                % Si hay error en PID Dahlin, usar PID simple
                Kp = 2.0;
                Ki = 0.1;
                Kd = 0.5;
                
                P_term = Kp * e_hist(end);
                I_term = Ki * sum(e_hist) * Sample_Time;
                D_term = Kd * (e_hist(end) - e_hist(end-1)) / Sample_Time;
                
                u_new = P_term + I_term + D_term + 50; % Offset de 50
            end

        % Saturar se�al de control
        u_new = max(0, min(100, u_new));
        u_hist = [u_hist(2:end), u_new];
        %Generacion
        DAQ_Write (u_new,Output_1);
        %Almacenar valores
        Data(contador,:)=[nivel_actual,u_new,setpoint_actual,error_actual,Kp,Ki,Kd];
        Timestamps(contador)=timestamp_actual;
        %Control de tiempo
        if((toc-Initial_Time)>Sample_Time)
            disp('Excedido el tiempo de muestreo');
            break;
        else
            pause(Sample_Time-(toc-Initial_Time));
        end
        Initial_Time=toc;
    end
end
%Detener DAQ
DAQ_Stop;
% Guardar en CSV
% Convertir timestamps a strings
Timestamps_str = cellstr(datestr(Timestamps, 'yyyy-mm-dd HH:MM:SS'));

% Crear tabla con strings en lugar de datetime
tabla = table(Timestamps_str, Data(:,1), Data(:,2), Data(:,3), Data(:,4), Data(:,5), Data(:,6), Data(:,7), ...
    'VariableNames', {'Timestamp', 'Nivel', 'Control_pct', 'Setpoint', 'Error', 'Kp', 'Ki', 'Kd'});

% Guardar CSV
nombre_csv = sprintf('experimento_control_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
writetable(tabla, nombre_csv);
fprintf('Datos CSV guardados en: %s\n', nombre_csv);