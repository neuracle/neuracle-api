

% triggerbox test
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Junying FANG, fangjunying@neuracle.cn
%
% Versions: 
%    v0.1: 2016-08-24, orignal
%    v1.0: 2021-02-19, add trigger
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
clc
close all
instrreset
N = 10;
waitTime = 1;
%% Global configuration
% Default parameters
isTriggerLight = false;
isTriggerCOM = true;
% input parameters
prompt = {'TriggerBox COM:',...
            'TriggerBox Light:'};
dlgTitle = 'Configurate devices';
dlgSize = [1 50];
defaultans = {num2str(isTriggerCOM),...
            num2str(isTriggerLight)};
answer = inputdlg(prompt,dlgTitle,dlgSize,defaultans,'on');
isTriggerCOM = logical(str2double(answer{1}));
isTriggerLight = logical(str2double(answer{2}));

%% System configuration
% TriggerBox
if isTriggerLight
    triggerBoxLight = TriggerBox();
    sensorID = 1;
    triggerBoxLight.InitLightSensor(sensorID);
    triggerBoxLight.SetEventData(sensorID, 0, 0);
end
if isTriggerCOM
    triggerBoxCOM = TriggerBox();
end

%% send trigger
for n  = 1: N
    for i = 1:251
        if isTriggerCOM
            triggerBoxCOM.OutputEventData(i);
             fprintf('send trigger %d by com\n',i)
        end
        if isTriggerLight 
            triggerBoxLight.SetEventData(sensorID, i);
            fprintf('send trigger %d by light\n',i)
        end
        pause(waitTime);
    end
end
IOPort('Close all');
