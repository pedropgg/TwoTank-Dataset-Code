% Clear workspace, close figures, and clear console
clc;
close all;
clear all;

% Load data from CSV file (place the CSV in the same directory as this script)
data = readtable('Disturbance_HighOutflow_80pct.csv');

% Extract columns to use
timestamps = data.Timestamp;
setpoint = data.Setpoint_pct;
nivel = data.Level_pct;
%perturbacion = data.perturbacion;

% Find indices for data with and without disturbance
idx_sin_perturbacion = (perturbacion == 0);
idx_con_perturbacion = (perturbacion == 1);

% Create a new figure
figure;
hold on; % Allows plotting multiple lines on the same figure

% 1. Plot Setpoint
plot(timestamps, setpoint, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Setpoint');

% 2. Plot Level WITHOUT disturbance (blue)
plot(timestamps(idx_sin_perturbacion), nivel(idx_sin_perturbacion), 'b o', 'LineWidth', 1.5, 'DisplayName', 'Level (no disturbance)');

% 3. Plot Level WITH disturbance (red)
plot(timestamps(idx_con_perturbacion), nivel(idx_con_perturbacion), 'r o', 'LineWidth', 2, 'DisplayName', 'Level (with disturbance)');

% Add plot details for readability
hold off;
title('Setpoint vs. Level with Disturbance');
xlabel('Time');
ylabel('Value');
legend('show'); % Show legend with defined labels
grid on; % Add grid

% Optional: Improve time axis format
datetick('x', 'HH:MM:SS', 'keepticks');
xtickangle(45); % Rotate x-axis labels to avoid overlap