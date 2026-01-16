function []=DAQ_Start()
% This function configures the DAQ input and output

global Arduino_COM
if ~isempty(Arduino_COM)
    DAQ_Stop  %Ensure the comunication is ended befeore stablish a new comunication
end
    % The COM number depends on each system; it is neccesary to confirm in the
% "Devices administrator"
Arduino_COM=serial('COM6','BaudRate',115200);

% We open the COM port to comunicate with Arduino
fopen(Arduino_COM);
pause(2) %ensure the comunication has enough time to be stablished succesfully
end