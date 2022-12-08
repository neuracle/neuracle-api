classdef RingBuffer < handle
%RingBuffer Dummy 2D ring buffer for multichannel data
% updates along 2st dimension
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
%    v0.1: 2016-11-22, orignal
%
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        currentPtr;
        buffer;
        nPoint;
        nChan;
        nUpdate;
    end
    
    methods
        function obj = RingBuffer(nChan, nPoint)
            obj.nChan = nChan;
            obj.nPoint = nPoint;
            obj.buffer = zeros(nChan, nPoint);
            obj.currentPtr = 1;
            obj.nUpdate = 0;
        end
        
        function Append(obj, data)
            n = size(data,2);
            obj.buffer(:, ...
                mod((obj.currentPtr : obj.currentPtr+n-1)-1, obj.nPoint) + 1) = data;
            obj.currentPtr = mod(obj.currentPtr+n-2, obj.nPoint) + 1 + 1;
            obj.nUpdate = obj.nUpdate + n;
        end
        
        function [data] = GetData(obj)
            data = [obj.buffer(:, obj.currentPtr:end) obj.buffer(:, 1:obj.currentPtr-1)];
        end
        
        function Reset(obj)
            obj.buffer = zeros(obj.nChan, obj.nPoint);
            obj.nUpdate = 0;
        end
    end
    
end