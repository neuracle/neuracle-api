classdef TriggerBox < handle
% TRIGGERBOX TriggerBox Configuration
% Author: Xiaoshan Huang, hxs@neuracle.cn
%
% Versions:
%    v1.0: 2016-08-01
%    v1.1: 2018-05-04, modify event data direct output
%
% Copyright © 2018 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (Constant)
        functionIDSensorParaGet = 1;
        functionIDSensorParaSet = 2;
        functionIDDeviceInfoGet = 3;
        functionIDDeviceNameGet = 4;
        functionIDSensorSampleGet = 5;
        functionIDSensorInfoGet = 6;
        functionIDOutputEventData = 225;
        functionIDError = 131;
        
        sensorTypeDigitalIN = 1;
        sensorTypeLight = 2;
        sensorTypeLineIN = 3;
        sensorTypeMic = 4;
        sensorTypeKey = 5;
        sensorTypeTemperature = 6;
        sensorTypeHumidity = 7;
        sensorTypeAmbientlight = 8;
        sensorTypeDebug = 9;
        sensorTypeAll = 255;

        deviceID = 1; % TODO: get device ID
    end
    
    properties
        comportHandle;
        deviceName;
        deviceInfo;
        sensorInfo;
    end
    
    methods
        
        %% TriggerBox: constructor function
        function obj = TriggerBox(varargin)
            IOPort('CloseAll');
            if nargin < 1
                serialInfo = instrhwinfo('serial');
                if length(serialInfo.AvailableSerialPorts) < 1
                    return;
                end
                validPort = [];
                for i = 1:length(serialInfo.AvailableSerialPorts)
                    port = serialInfo.AvailableSerialPorts{i};
                    if ~isempty(strfind(port, 'cu.usbserial')) || ~isempty(strfind(port, 'COM'))
	                    isValidDevice = obj.ValidateDevice(port);
	                    if isValidDevice
	                        validPort = port;
	                        break;
	                    end
	                end
                end
                if isempty(validPort)
                    disp('No triggerbox available');
                    return;
                end
            end
            IOPort('CloseAll');
            obj.comportHandle = IOPort('OpenSerialPort', port, 'BaudRate=115200');
            IOPort('Purge', obj.comportHandle);
            obj.GetDeviceName;
            obj.GetDeviceInfo;
            obj.GetSensorInfo;
        end
        %% ValidateDevice 
        function isValidDevice = ValidateDevice(obj, port)
            IOPort('CloseAll');
            handle = IOPort('OpenSerialPort', port, 'BaudRate=115200');
            IOPort('Purge', handle);
            message = [obj.deviceID 4 typecast(uint16(0), 'uint8')];
            IOPort('Write', handle, uint8(message));
            message = IOPort('Read', handle, 1, 4);
            if isempty(message)
                isValidDevice = false;
            else
                isValidDevice = true;
            end
            IOPort('Purge', handle);
        end
        %% InitLightSensor: Init light sensor
        function InitLightSensor(obj, sensorID)
            sensorPara = obj.GetSensorPara(sensorID);
            sensorPara.OutputChannel = 3;
            sensorPara.TriggerToBeOut = 0;
            sensorPara.EventData = 0;
            obj.SetSensorPara(sensorID, sensorPara);
            obj.SetLightSensorThreshold(sensorID);
        end
        %% SetLightSensorThreshold: Set light sensor threshold
        function SetLightSensorThreshold(obj, sensorID, dotSize)
            if nargin < 3
                dotSize = 50;
            end
            AssertOpenGL;
            Screens = Screen('Screens'); 
            ScreenNum = max(Screens); 
            [w, rect] = Screen('OpenWindow', ScreenNum); 
            [width, height] = RectSize(rect);
            black = BlackIndex(w);
            white = WhiteIndex(w);
            Screen('FillRect',w, black);
            
            sensorPara = obj.GetSensorPara(sensorID);
            
            Screen('DrawDots', w, [width-dotSize/2 height-dotSize/2], dotSize, white);
            Screen('Flip', w);
            WaitSecs(0.5);
            
            sensorWhite = obj.GetSensorSample(sensorID);
            
            Screen('DrawDots', w, [width-dotSize/2 height-dotSize/2], dotSize, black);
            Screen('Flip', w);
            WaitSecs(0.5);
            sensorBlack = obj.GetSensorSample(sensorID);

            disp('Light sensor data');
            disp(['White: ' num2str(sensorWhite) ', Black: ' num2str(sensorBlack)]);
            
            if (sensorWhite - sensorBlack) < sensorBlack * 0.5
                disp('Light sensor data out of range.');
            else
                sensorPara.Threshold = 0.8*(sensorWhite - sensorBlack) + sensorBlack;
                disp(['Light sensor threshold: ' num2str(sensorPara.Threshold)]);
                obj.SetSensorPara(sensorID, sensorPara);
            end

            Screen('CloseAll');
        end
        %% InitAudioSensor: Init auditory sensor
        function InitAudioSensor(obj, sensorID)
            sensorPara = obj.GetSensorPara(sensorID);
            sensorPara.OutputChannel = 3;
            sensorPara.TriggerToBeOut = 0;
            sensorPara.EventData = 0;
            obj.SetSensorPara(sensorID, sensorPara);
            obj.SetAudioSensorThreshold(sensorID);
        end
        %% SetAudioSensorThreshold: Set auditory sensor threshold
        function SetAudioSensorThreshold(obj, sensorID)
             
            sensorPara = obj.GetSensorPara(sensorID);
            
            %generate a pure tone, 1s long
            InitializePsychSound;
            nrchannels=2;
            freq = 48000;
            t_index=0:1/freq:1-1/freq;
            Y=sin(2*pi*1000*t_index)';
            Y(end+1:end+0.1*freq)=0;
            [samplecount, ninchannels] = size(Y);
            Y=transpose(Y);
            audiodata = repmat(Y, nrchannels / ninchannels, 1);
            y_cue=length(audiodata)/freq;
            buffer = PsychPortAudio('CreateBuffer', [], audiodata);
            pahandle = PsychPortAudio('Open', [], [], 1, freq, nrchannels);

            %play the sound, three times
            for i = 1:3
                PsychPortAudio('UseSchedule', pahandle, 1);
                PsychPortAudio('AddToSchedule', pahandle, buffer, 1);
                PsychPortAudio('Start', pahandle, [], 0, [],[],0);
                WaitSecs(0.55);
                sensorWhite = obj.GetSensorSample(sensorID);           
                PsychPortAudio('Stop', pahandle);
                WaitSecs(0.55);           
                sensorBlack = obj.GetSensorSample(sensorID);
                [sensorWhite sensorBlack]
            end                      
            sensorPara.Threshold = 0.8*(sensorWhite - sensorBlack) + sensorBlack;
            obj.SetSensorPara(sensorID, sensorPara);
            Screen('CloseAll');
        end
        %% OutputEventData: output event data directly
        function isSucceed = OutputEventData(obj, eventData)
            obj.SendCommand(obj.functionIDOutputEventData, uint8(eventData));
            resp = obj.ReadResponse(obj.functionIDOutputEventData);
            isSucceed = resp(1) == obj.functionIDOutputEventData;
        end
        %% SetEventData: set outputting event data
        function SetEventData(obj, sensorID, eventData, triggerToBeOut)
            if nargin < 4
                triggerToBeOut = 1;
            end
            sensorPara = obj.GetSensorPara(sensorID);
            sensorPara.TriggerToBeOut = triggerToBeOut;
            sensorPara.EventData = eventData;
            obj.SetSensorPara(sensorID, sensorPara);
        end
        %% GetDeviceName: get device name
        function [name] = GetDeviceName(obj)
            obj.SendCommand(obj.functionIDDeviceNameGet);
            name = obj.ReadResponse(obj.functionIDDeviceNameGet);
            name = char(name);
            obj.deviceName = name;
        end

        %% GetDeviceInfo: get device information
        function [deviceInfo] = GetDeviceInfo(obj)
            obj.SendCommand(obj.functionIDDeviceInfoGet, 1);
            info = obj.ReadResponse(obj.functionIDDeviceInfoGet);
            deviceInfo = struct('HardwareVersion', info(1),...
                                'FirmwareVersion', info(2),...
                                'SensorSum', info(3),...
                                'ID', typecast(uint8(info(5:8)), 'uint32'));
            obj.deviceInfo = deviceInfo;
        end
        
        %% GetSensorInfo: get sensor info
        function [sensorInfo] = GetSensorInfo(obj)
            obj.SendCommand(obj.functionIDSensorInfoGet);
            info = obj.ReadResponse(obj.functionIDSensorInfoGet);
            sensorInfo = cell(length(info)/2,1);
            for i = 1:length(sensorInfo)
                type = info((i-1)*2+1);
                switch type
                    case obj.sensorTypeDigitalIN
                        sensorType = 'DigitalIN';
                    case obj.sensorTypeLight
                        sensorType = 'Light';
                    case obj.sensorTypeLineIN
                        sensorType = 'LineIN';
                    case obj.sensorTypeMic
                        sensorType = 'Mic';
                    case obj.sensorTypeKey
                        sensorType = 'Key';
                    case obj.sensorTypeTemperature
                        sensorType = 'Temperature';
                    case obj.sensorTypeHumidity
                        sensorType = 'Humidity';
                    case obj.sensorTypeAmbientlight
                        sensorType = 'Ambientlight';
                    case obj.sensorTypeDebug
                        sensorType = 'Debug';
                    otherwise
                        sensorType = 'Undefined';
                        disp('Undefined sensor type');
                end
                sensorNum = info((i-1)*2+2);
                sensorInfo{i} = struct('Type', sensorType, 'Number', sensorNum);
            end
            obj.sensorInfo = sensorInfo;
        end

        %% GetSensorPara: get sensor parameter
        function [sensorPara] = GetSensorPara(obj, sensorID)
            sensor = obj.sensorInfo{sensorID};
            cmd = [obj.SensorType(sensor.Type) sensor.Number];
            obj.SendCommand(obj.functionIDSensorParaGet, cmd);
            para = obj.ReadResponse(obj.functionIDSensorParaGet);
            sensorPara = struct('Edge', para(1),...
                                'OutputChannel', para(2),...
                                'TriggerToBeOut', typecast(uint8(para(3:4)), 'uint16'),...
                                'Threshold', typecast(uint8(para(5:6)), 'uint16'),...
                                'EventData', typecast(uint8(para(7:8)), 'uint16'));
        end

        %% SetSensorPara: set sensor parameter
        function [isSucceed] = SetSensorPara(obj, sensorID, sensorPara)
            sensor = obj.sensorInfo{sensorID};
            cmd = [obj.SensorType(sensor.Type) sensor.Number sensorPara.Edge, sensorPara.OutputChannel,...
                        typecast(uint16(sensorPara.TriggerToBeOut), 'uint8'),...
                        typecast(uint16(sensorPara.Threshold), 'uint8'),...
                        typecast(uint16(sensorPara.EventData), 'uint8')];
            obj.SendCommand(obj.functionIDSensorParaSet, cmd);
            resp = obj.ReadResponse(obj.functionIDSensorParaSet);
            isSucceed = resp(1) == obj.SensorType(sensor.Type) && resp(2) == sensor.Number;
        end        
        %% GetSensorSample: get sensor sample
        function [adcResult] = GetSensorSample(obj, sensorID)
            sensor = obj.sensorInfo{sensorID};
            obj.SendCommand(obj.functionIDSensorSampleGet, [obj.SensorType(sensor.Type) sensor.Number]);
            result = obj.ReadResponse(obj.functionIDSensorSampleGet);
            if result(1) ~= obj.SensorType(sensor.Type) || result(2) ~= sensor.Number
                error('Get sensor sample error');
            end
            adcResult = typecast(uint8(result(3:4)), 'uint16');
        end
        
        %% sensorType: convert sensor type string to number
        function [typeNum] = SensorType(obj, typeString)
            switch typeString
                case 'DigitalIN'
                    typeNum = obj.sensorTypeDigitalIN;
                case 'Light'
                    typeNum = obj.sensorTypeLight;
                case 'LineIN'
                    typeNum = obj.sensorTypeLineIN;
                case 'Mic'
                    typeNum = obj.sensorTypeMic;
                case 'Key'
                    typeNum = obj.sensorTypeKey;
                case 'Temperature'
                    typeNum = obj.sensorTypeTemperature;
                case 'Humidity'
                    typeNum = obj.sensorTypeHumidity;
                case 'Ambientlight'
                    typeNum = obj.sensorTypeAmbientlight;
                case 'Debug'
                    typeNum = obj.sensorTypeDebug;
                otherwise
                    error('Undefined sensor type');
            end
        end        

        %% SendCommand: send command message
        function SendCommand(obj, functionID, command)
            if nargin < 3
                command = [];
            end
            payload = length(command);
            message = [obj.deviceID functionID typecast(uint16(payload), 'uint8') command];
            IOPort('Write', obj.comportHandle, uint8(message));
        end

        %% ReadResponse: read response
        function [DataBuf] = ReadResponse(obj, functionID)
            message = IOPort('Read', obj.comportHandle, 1, 4);
              if message(1) ~= obj.deviceID
                error('Response error: request deviceID %d, return deviceID %d', obj.deviceID, message(1));
            end

            if message(2) ~= functionID
                if message(2) == obj.functionIDError
                    errorType = IOPort('Read', obj.comportHandle, 1, 1);
                    switch errorType
                        case 0
                            errorMessage = 'None';
                        case 1
                            errorMessage = 'FrameHeader';
                        case 2
                            errorMessage = 'FramePayload';
                        case 3
                            errorMessage = 'ChannelNotExist';
                        case 4
                            errorMessage = 'DeviceID';
                        case 5
                            errorMessage = 'FunctionID';
                        case 6
                            errorMessage = 'SensorType';
                        otherwise
                            error('Undefined error type');
                    end
                    error(['Response error: ' errorMessage]);
                else
                    error('Response error: request functionID %d, return functionID %d', functionID, message(2));
                end
            end
            payload = message(3) + message(4) *256;
            DataBuf = IOPort('Read', obj.comportHandle, 1, payload);
        end
    end
end

