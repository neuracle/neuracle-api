classdef DataParser < handle
% Data parser for TCP/IP
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
%         Junying FANG , fangjunying@neuracle.cn 
% Versions:
%    v0.1: 2016-11-02, orignal
%    V1.0：2020-08-11， add HEEG data parser
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        
    end

    properties
        device;
        nChan;
        buffer;
        sampleRate;
    end

    methods
        function obj = DataParser(device, nChan,sampleRate)
            obj.device = device;
            obj.nChan = nChan;
            obj.sampleRate=sampleRate;
        end

        function WriteData(obj, buffer, ringBuffer)
            buffer = uint8(buffer(:));
            
            obj.buffer = [obj.buffer; buffer];
            if obj.nChan ~= ringBuffer.nChan
                error('Channel number mismatch.');
            end
            switch obj.device
                case 'Neuracle'
                    [data, event, obj.buffer] = ParseDataNeuracle(obj, obj.buffer, ringBuffer.nChan);
                    data = typecast(data,'single');
                    data = reshape(data, ringBuffer.nChan, numel(data)/ringBuffer.nChan);
                case 'DSI-24'
                    [data, event, obj.buffer] = ParseDataWS(obj, obj.buffer);
                    if ~isempty(data)
                        data = [data.ChannelData];
                        data = data(:);
                        data = swapbytes(typecast(data,'single'));
                    end
                    data = reshape(data, ringBuffer.nChan, numel(data)/ringBuffer.nChan);
                case 'HEEG'
                    [data, event, obj.buffer] = ParseDataHEEG(obj, obj.buffer, ringBuffer.nChan);
                    data=data';
                otherwise
                    error('Device not supported');
            end       
            ringBuffer.Append(data);%将解码到的数据分配到缓存空间

        end
        
        function [data, event, buffer] = ParseDataNeuracle(obj, buffer, nChan)
            n = numel(buffer);
            data = [];
            event = [];
            data = buffer(1:n-mod(n,4*nChan));
            buffer = buffer(n-mod(n,4*nChan)+1:n);
        end

        function [data, event, buffer] = ParseDataWS(obj, buffer)
            token = unicode2native('@ABCD')';
            n = numel(buffer);
            i = 1;
            data = [];
            iData = 1;
            event = [];
            iEvent = 1;
            while i + 12 < n
                if isequal(buffer(i:i+4), token)
                    packetType = buffer(i+5)
                    bytes = double(buffer(i+6:i+7));
                    packetLength = 256*bytes(1)+bytes(2);
                    bytes = double(buffer(i+8:i+11));
                    packetNumber = 16777216*bytes(1)+65536*bytes(2)+256*bytes(3)+bytes(4);
                    if i+12+packetLength-1 > n
                        break;
                    end
                    switch packetType
                        case 1
                            bytes = double(buffer(i+12:i+15));
                            data(iData).TimeStamp = 16777216*bytes(1)+65536*bytes(2)+256*bytes(3)+bytes(4);
                            data(iData).DataCounter = buffer(i+16);
                            data(iData).ADCStatus = buffer(i+17:i+22);
                            data(iData).ChannelData = buffer(i+23:i+12+packetLength-1);
                            iData = iData+1;
                        case 5
                            bytes = double(buffer(i+12:i+15));
                            event(iEvent).EventCode = 16777216*bytes(1)+65536*bytes(2)+256*bytes(3)+bytes(4);
                            bytes = double(buffer(i+16:i+19));
                            event(iEvent).SendingNode = 16777216*bytes(1)+65536*bytes(2)+256*bytes(3)+bytes(4);
%                             if packetLength > 20
%                                 bytes = double(buffer(i+20:i+23));
%                                 event(iEvent).MessageLength = 16777216*bytes(1)+65536*bytes(2)+256*bytes(3)+bytes(4);
%                                 event(iEvent).Message = buffer(i+24:i+24+event(iEvent).MessageLength-1);
%                             end
                            iEvent = iEvent+1;
                        otherwise
                    end
                    i = i+12+packetLength;
                else
                    i = i+1;
                end

            end
            buffer = buffer(i:end);
        end
        
        function [data, event, buffer] = ParseDataHEEG(obj, buffer, nbchan)
            headtoken=hex2dec({'5A','A5'});
            tailtoken={'A5','5A'};
            headerlength=26;
            triggerlength=30;
            channelcount=nbchan-1;
            samplerate=obj.sampleRate;
%             samplerate=typecast(buffer(18:21),'uint32');
            data=[];
            if samplerate<=1000
                dataperchannel=1;
            else
                dataperchannel=samplerate/1000;
            end
            event=zeros(dataperchannel,1);
            totallength=headerlength+dataperchannel*channelcount*4+triggerlength+2;%tailtokenlength=2
            i=1;
            while totallength<=numel(buffer)
                if isequal(buffer(i:i+1),headtoken)
                    nbchan_get=typecast(buffer(15:18),'uint32');
                    samplerate_get=typecast(buffer(19:22),'uint32');
                    if channelcount~=nbchan_get || samplerate~=samplerate_get
                        error('number of channels or samplerate is wrong');
                    end
                    event(1)=buffer(headerlength+dataperchannel*channelcount*4+i);
                    
                    event(isnan(event))=0;
                    data_event=[reshape(typecast(buffer(i+headerlength:i+headerlength+dataperchannel*channelcount*4-1),'single'),dataperchannel,channelcount),event];
                    data=[data;data_event];
                    buffer=buffer(totallength+i:end);
                else
                    i=i+1;
                end
            end
            
            
        end
    end
end


