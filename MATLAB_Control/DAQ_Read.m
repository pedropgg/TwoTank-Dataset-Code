function [Channel_0,Channel_1]=DAQ_Read()
% This function read the value in the configured input in the DAQ

global Arduino_COM

Comando=uint8(136); % We command the Arduino to send the values of the
% first two input channels

fwrite(Arduino_COM,Comando,'uchar');

Channel_0=fscanf(Arduino_COM,'%d');
% Arduino reading range is 0@1023, them the measure is scaled to 0@100
Channel_0=100*Channel_0/255;
Channel_1=fscanf(Arduino_COM,'%d');
% Arduino reading range is 0@1023, them the measure is scaled to 0@100
Channel_1=100*Channel_1/255;

end
