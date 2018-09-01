classdef VideoFrame < handle
    %VIDEOFRAME  Video frame abstraction
    %   VIDEOFRAME represents one frame in a video stream. 
    
    properties
        idx
        exists
        img
        date_time
    end
    
    methods
        
        function [obj] = VideoFrame(idx, img)
            if nargin < 2, img = []; end;
            if nargin < 1, idx = -1; end;
            obj.idx = idx;
            obj.date_time = zeros(1, 7);
            obj.setImg(img);
        end
        
        
        function setDateTime(obj, date_time)
            obj.date_time = date_time;
        end
        
        
        function setImg(obj, img)
            obj.img = img;
            if ~isempty(img)
                obj.exists = true;
            else
                obj.exists = false;
            end
        end
        
    end  % methods
    
end

