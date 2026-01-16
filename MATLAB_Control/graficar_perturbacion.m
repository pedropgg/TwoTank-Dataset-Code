% Limpiar el entorno de trabajo, cerrar figuras y limpiar la consola
clc;
close all;
clear all;

% Cargar los datos desde el archivo CSV
% Asegúrate de que el archivo CSV esté en el mismo directorio que este script
data = readtable('experimento_control_20251027_185929.csv');

% Extraer las columnas que vamos a utilizar
timestamps = data.Timestamp;
setpoint = data.Setpoint_pct;
nivel = data.Level_pct;
%perturbacion = data.perturbacion;

% Encontrar los índices (las posiciones) para los datos con y sin perturbación
idx_sin_perturbacion = (perturbacion == 0);
idx_con_perturbacion = (perturbacion == 1);

% Crear una nueva figura para la gráfica
figure;
hold on; % Permite dibujar múltiples líneas en la misma gráfica

% 1. Graficar el Setpoint
plot(timestamps, setpoint, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Setpoint');

% 2. Graficar el Nivel SIN perturbación (en color azul)
plot(timestamps(idx_sin_perturbacion), nivel(idx_sin_perturbacion), 'b o', 'LineWidth', 1.5, 'DisplayName', 'Nivel (sin perturbación)');

% 3. Graficar el Nivel CON perturbación (en color rojo)
plot(timestamps(idx_con_perturbacion), nivel(idx_con_perturbacion), 'r o', 'LineWidth', 2, 'DisplayName', 'Nivel (con perturbación)');

% Añadir detalles a la gráfica para que se entienda mejor
hold off;
title('Comparativa de Setpoint vs. Nivel con Perturbación');
xlabel('Tiempo');
ylabel('Valor');
legend('show'); % Muestra la leyenda con los nombres que definimos
grid on; % Añade una cuadrícula

% Opcional: Mejorar el formato del eje de tiempo
datetick('x', 'HH:MM:SS', 'keepticks');
xtickangle(45); % Gira las etiquetas del eje x para que no se solapen