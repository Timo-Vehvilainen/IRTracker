classdef TrackerData < handle
    %TRACKERDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    	img         % image data that has been tracked
        pts         % detected track points in the frame
        features    % extracted features of the frame
        valid_pts   % points in the frame that are valid
    end
    
    methods
        function [obj] = TrackerData(img)
            obj.img = img;
        end
    end
    
end
