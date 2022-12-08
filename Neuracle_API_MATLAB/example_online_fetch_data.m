% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Junying FANG , fangjunying@neuracle.cn 
%
% Versions:
%    v1.0: 2020-06-20, orignal
% Demo : online receive data stream 
clear;
clc;
instrreset
% 初始化DataServer对象
deviceMontage = {"Pz","POz","PO3","PO4","PO5","PO6","Oz","O1","O2","TRG"};
device = 'Neuracle';     % see DataParser for supported devices
ipAddress = '127.0.0.1'; % IP address of the DataSerive in EEG Recorder
serverPort = 8712;       % port of the DataSerive in EEG Recorder
nChan = length(deviceMontage);
sampleRate = 1000;       % Hz
timeRingbuffer = 4;      % Second
dataServer = DataServer(device, nChan, ipAddress, serverPort, sampleRate, timeRingbuffer); 
dataServer.Open();
figure
while i<100
    data = dataServer.GetBufferData(); % 
    
    subplot(2,1,1)
    plot(data(1,:));
    subplot(2,1,2)
    plot(data(end-1,:));
    
    pause(0.2)
    i=i+1;
end
dataServer.Close();