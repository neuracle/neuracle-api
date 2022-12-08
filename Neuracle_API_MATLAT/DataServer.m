classdef DataServer < handle
%
% Syntax:  
%     
%
% Inputs:
%     
%
% Outputs:
%     
%
% Example:
%     
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Xiaoshan Huang, hxs@neuracle.cn
%
% Versions:
%    v0.1: 2016-11-02, orignal
%
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (Constant)
        updateInterval = 0.04; % 40ms
    end
    
    properties
        nChan;
        sampleRate;
        TCPIP;
        dataParser;
        ringBuffer;
    end
    
    methods
        
        function obj = DataServer(device, nChan, ipAddress, serverPort, sampleRate, bufferSize)
            obj.nChan = nChan;
            obj.sampleRate = sampleRate;
            obj.ringBuffer = RingBuffer(obj.nChan, round(bufferSize*obj.sampleRate));
            obj.dataParser = DataParser(device, obj.nChan,obj.sampleRate);
            
            obj.TCPIP = tcpip(ipAddress, serverPort);
            obj.TCPIP.InputBufferSize = obj.updateInterval*4*obj.nChan*obj.sampleRate*10;
            obj.TCPIP.TimerPeriod = obj.updateInterval;
            obj.TCPIP.TimerFcn = {@timerCallBack, obj.dataParser, obj.ringBuffer};
        end
        
        function Open(obj)
            fopen(obj.TCPIP);
        end
        
        function Close(obj)
            fclose(obj.TCPIP);
        end
        
        function [data] = GetBufferData(obj)
            data = obj.ringBuffer.GetData;
        end

        function [data] = GetRingBufferData(obj)
            data = obj.ringBuffer.buffer;
        end
                function ResetDataLenCounter(obj,count)
            if nargin < 2
                count = 0;
            end
            obj.ringBuffer.nUpdate = count;
        end
        
        function ResetTriggerChanOfBuff(obj,data)
            if nargin < 2
                obj.ringBuffer.buffer(end-obj.nVector,:) = zeros(1,size(obj.ringBuffer.buffer,2));
                return
            end
            if length(data) == size(obj.ringBuffer.buffer,2)
                obj.ringBuffer.buffer(end-obj.nVector,:) = data;
            else
                fprintf('Error: length of data not equal to that of buffer,(%i) vs (%i), Failed for resetting buffer \n',length(data), size(obj.ringBuffer.buffer,2));
                return;
            end
        end

    end
    
end

function timerCallBack(obj, event, dataParser, ringBuffer)
    if obj.BytesAvailable > 0
        raw = fread(obj, obj.BytesAvailable, 'uint8');
        dataParser.WriteData(raw, ringBuffer);
    end
end

