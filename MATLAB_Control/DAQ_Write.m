function []=DAQ_Write(Channel_0,Channel_1)
% This function write de desired value in the configured DAQ output

global Arduino_COM

% Ensure that the value is inside the operation range
if Channel_0>100
    Channel_0=100;
elseif Channel_0<0
    Channel_0=0;
end
if Channel_1>100
    Channel_1=100;
elseif Channel_1<0
    Channel_1=0;
end

% As the range of the values is 0@100, the values are scaled to 0@255
Channel_0=round(255*Channel_0/100);
Channel_1=round(255*Channel_1/100);

% Once the values are in the correct scale, they are "sent" to the DAQ

Comando=uint8(65); % We command the Arduino to send the values of the first
% two input channels

fwrite(Arduino_COM,Comando,'uchar');
fwrite(Arduino_COM,Channel_0,'uchar');
fwrite(Arduino_COM,Channel_1,'uchar');

end