clc, clear, close all
% Setpoint and timing configuration
setpoints = 50:5:60; % desired levels in percent
num_setpoints = length(setpoints);
tiempo_por_setpoint = 5 *60; % 5 minutes
% Sampling time
Sample_Time=1;
% Total time
Total_Time= num_setpoints * tiempo_por_setpoint;
% Number of samples
n= Total_Time/Sample_Time;
% Control variables
P = [];
X = [];
num = rand();
den = [1, rand(), rand()];
e_hist = [0, 0, 0];  % Error history
u_hist = [0,0];       % Control history
nivel_anterior = NaN;  % Simple fault detector
% Initialize storage variables
Data=zeros(n,7);
Timestamps = datetime.empty(n, 0);
% Initialize DAQ
DAQ_Start;
% Initialize outputs
Ctrl_Signal=0;
Output_1=0;
% Initialize timing control variables
tic
Initial_Time=toc;
%% Control and acquisition loop
contador=0;
for i=1:num_setpoints % for each setpoint
    for j=1:tiempo_por_setpoint
        contador=contador+1;
        setpoint_actual = setpoints(i);
        
        % Acquisition
        nivel_raw=DAQ_Read;
        if isfinite(nivel_anterior)
        cambio = abs(nivel_actual - nivel_anterior);
            if cambio > 6  % Maximum change threshold
                nivel_actual = nivel_anterior+rand();
            else
                nivel_actual = nivel_raw;
            end
        else
            nivel_actual = nivel_raw;
        end    
        nivel_anterior=nivel_actual;
        % Capture current timestamp
        timestamp_actual = datetime('now');
        % Error calculation
        error_actual = setpoint_actual - nivel_actual;
        e_hist = [e_hist(2:end), error_actual];
        % Apply RLS identification algorithm
        if contador>=2 % Apply RLS starting from the second sample
             % Use historical data for RLS
                entrada_sistema = u_hist(end-1);
                salida_sistema = nivel_actual;
                [num, den, P, X] = RLS(entrada_sistema, salida_sistema, num, den, P, X, 0.9);
        end
        % Calculate new control signal using PID Dahlin
            %try
            if contador>=3
                [u_new, Kp, Ti, Td] = PID_dahlin(num, den, e_hist, u_hist(end), Sample_Time, 3.0);
                Ki=Kp/Ti;
                Kd=Kp*Td;
            else
           % catch
                % If PID Dahlin fails, use simple PID
                Kp = 2.0;
                Ki = 0.1;
                Kd = 0.5;
                
                P_term = Kp * e_hist(end);
                I_term = Ki * sum(e_hist) * Sample_Time;
                D_term = Kd * (e_hist(end) - e_hist(end-1)) / Sample_Time;
                
                u_new = P_term + I_term + D_term + 50; % Offset of 50
            end

        % Saturate control signal
        u_new = max(0, min(100, u_new));
        u_hist = [u_hist(2:end), u_new];
        % Generation
        DAQ_Write (u_new,Output_1);
        % Store values
        Data(contador,:)=[nivel_actual,u_new,setpoint_actual,error_actual,Kp,Ki,Kd];
        Timestamps(contador)=timestamp_actual;
        % Timing control
        if((toc-Initial_Time)>Sample_Time)
            disp('Sampling time exceeded');
            break;
        else
            pause(Sample_Time-(toc-Initial_Time));
        end
        Initial_Time=toc;
    end
end
% Stop DAQ
DAQ_Stop;
% Save to CSV
% Convert timestamps to strings
Timestamps_str = cellstr(datestr(Timestamps, 'yyyy-mm-dd HH:MM:SS'));

% Create table with strings instead of datetime
tabla = table(Timestamps_str, Data(:,1), Data(:,2), Data(:,3), Data(:,4), Data(:,5), Data(:,6), Data(:,7), ...
    'VariableNames', {'Timestamp', 'Nivel', 'Control_pct', 'Setpoint', 'Error', 'Kp', 'Ki', 'Kd'});

% Save CSV
nombre_csv = sprintf('experimento_control_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
writetable(tabla, nombre_csv);
fprintf('CSV data saved to: %s\n', nombre_csv);