clc, clear, close all
% Electrovalve closure (%), logged in Valve_Closure_pct.
% The output file name uses the electrovalve opening = 100 - closure.
valve_closure_pct = 60;
valve_opening_pct = 100 - valve_closure_pct;
% Perturbation flag toggled by keypress
perturbation = 0;
perturb_fig = figure('Name','Toggle perturbation (press any key)', ...
    'KeyPressFcn',@(src,evt) set(src,'UserData',1 - get(src,'UserData')), ...
    'UserData',0);
% Setpoint and timing configuration
setpoints = 10:5:90; % desired levels in percent
num_setpoints = length(setpoints);
time_per_setpoint = 30*60; % 30 minutes 
% Sampling time
Sample_Time=1;
% Total time
total_time= num_setpoints * time_per_setpoint;
% Number of samples
n= total_time/Sample_Time;
% Control variables
P = [];
X = [];
num = rand();
den = [1, rand(), rand()];
error_hist = [0, 0, 0];  % Error history
control_hist = [0,0];    % Control history
% Initialize storage variables (adds perturbation column)
data_log=zeros(n,12);
timestamps = datetime.empty(n, 0);
% Initialize DAQ
DAQ_Start;
% Initialize outputs
Ctrl_Signal=0;
Output_1=0;
% Initialize time control variables
tic
initial_time=toc;
%% Control and acquisition loop
sample_idx=0;
for i=1:num_setpoints % for each setpoint
    for j=1:time_per_setpoint
        sample_idx=sample_idx+1;
        current_setpoint = setpoints(i);
        
        % Acquisition
        current_level=DAQ_Read;
        % Capture current timestamp
        current_timestamp = datetime('now');
        % Error calculation
        current_error = current_setpoint - current_level;
        error_hist = [error_hist(2:end), current_error];
        % Apply RLS identification algorithm
        if sample_idx>=2 % Apply RLS starting from the second sample
             % control_hist = [u(k-2), u(k-1)] here, so the identified model is
             % y(k) = -a1*y(k-1) - a2*y(k-2) + b1*u(k-2) (two-sample input delay)
                system_input = control_hist(end-1);
                system_output = current_level;
                [num, den, P, X] = RLS(system_input, system_output, num, den, P, X, 0.9);
        end
        % Compute new control signal using Dahlin PID
            %try
            if sample_idx>=3
                [u_new, Kp, Td, Ti] = PID_dahlin(num, den, error_hist, control_hist(end), Sample_Time, 3.0);
                Ki=Kp/Ti;
                Kd=Kp*Td;
            else
           % catch
                % If Dahlin PID fails, fall back to simple PID
                Kp = 2.0;
                Ki = 0.1;
                Kd = 0.5;
                
                P_term = Kp * error_hist(end);
                I_term = Ki * sum(error_hist) * Sample_Time;
                D_term = Kd * (error_hist(end) - error_hist(end-1)) / Sample_Time;
                
                u_new = P_term + I_term + D_term + 50; % 50 offset
            end

        % Saturate control signal
        u_new = max(0, min(100, u_new));
        control_hist = [control_hist(2:end), u_new];
        % Output generation
        DAQ_Write (u_new,Output_1);
        % Read perturbation flag from figure (0/1)
        perturbation = get(perturb_fig,'UserData');
        % Store values
        a1 = den(2);  % Coefficient a1
        a2 = den(3);  % Coefficient a2
        b1 = num;     % Coefficient b1 (numerator)
        data_log(sample_idx,:)=[valve_closure_pct,current_level,u_new,current_setpoint,current_error,Kp,Ki,Kd, b1, a1, a2, perturbation];
        timestamps(sample_idx)=current_timestamp;
        % Timing control
        if((toc-initial_time)>Sample_Time)
            disp('Sample time exceeded');
            break;
        else
            pause(Sample_Time-(toc-initial_time));
        end
        initial_time=toc;
    end
end
% Stop DAQ
DAQ_Stop;
if isvalid(perturb_fig), close(perturb_fig); end
% Save to CSV
% Convert timestamps to strings
timestamp_strs = cellstr(datestr(timestamps, 'yyyy-mm-dd HH:MM:SS'));

% Create table with strings instead of datetime
table_data = table(timestamp_strs, data_log(:,1), data_log(:,2), data_log(:,3), data_log(:,4), data_log(:,5), data_log(:,6), data_log(:,7), data_log(:,8), data_log(:,9), data_log(:,10), data_log(:,11), data_log(:,12), ...
    'VariableNames', {'Timestamp','Valve_Closure_pct','Level_pct','Control_Signal_pct','Setpoint_pct','Error_pct','Kp','Ki','Kd','b1','a1','a2','perturbation'});

% Save CSV
csv_filename = sprintf('Disturbance_LowOutflow_%.0fpct.csv', valve_opening_pct);
writetable(table_data, csv_filename);
fprintf('CSV data saved to: %s\n', csv_filename);