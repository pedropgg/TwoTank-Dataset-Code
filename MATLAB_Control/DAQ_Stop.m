function []=DAQ_Stop()
% This function is used to finaliced the uses of the DAQ

global Arduino_COM
if ~isempty(Arduino_COM)
    if isvalid(Arduino_COM) %Only when communication is stablished, it stop the comunication
        % Clear the outputs channels
        DAQ_Write(0,0); % Ensure the output channels are resetted

        % The COM port is closed
        fclose(Arduino_COM);

        % The variable of the DAQ is deleted
        delete(Arduino_COM);
    end
end
end