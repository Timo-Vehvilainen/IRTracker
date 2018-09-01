classdef MovementTracker < handle
    %MOVEMENTTRACKER  Track the movement of the 
    %   Detailed explanation goes here
    
    properties
        fig2axes    % figure-to-axes transform matrix
        max_pts     % maximum amount of points to track
        
        data0       % data of the previous frame
        data1       % data of the current frame
        tform       % estimated transformation matrix between the frames
        
        matched0    % matched points of the previous frame
        matched1    % matched points of the current frame
    end  % properties
    
    methods
        
        function obj = MovementTracker(varargin)
            %MOVEMENTTRACKER  Construct MovementTracker object
            obj.fig2axes = eye(4);
            obj.max_pts = 1000;
            obj.tform = eye(4);
            
            obj = obj.parseInput(varargin);
        end
        
    end  % public methods
    
    
    methods (Access = protected)
        
        function obj = moveToNextFrame(obj)
            %MOVETONEXTFRAME  Advance one frame
            obj.data0 = obj.data1;
        end
        
        function obj = extractFeatures(obj, img)
            %EXTRACTFEATURES  Extract features of the input image
            obj.data1 = TrackerData(normalize0to1(img));
            data = obj.data1;
%             obj.data1.pts = detectBRISKFeatures(obj.data1.img, 'MinContrast', 0.05, 'MinQuality', 0.2);
%             obj.data1.pts = detectSURFFeatures(obj.data1.img);
            data.pts = detectMinEigenFeatures(obj.data1.img, ...
                                                   'MinQuality', 0.01, ...
                                                   'FilterSize', 5);
            data.pts = data.pts.selectStrongest(obj.max_pts);
            [data.features, data.valid_pts] = extractFeatures(data.img, ...
                                                              data.pts);
        end
        
        
        function predictFrame(obj, img)
            %PREDICTFRAME  Estimate the movement of the image
            obj.extractFeatures(img);
            
            dat0 = obj.data0;
            dat1 = obj.data1;
            % Find matching features
            idx_pairs = matchFeatures(dat0.features, dat1.features);
            %
            obj.matched0 = dat0.valid_pts(idx_pairs(:,1));
            obj.matched1 = dat1.valid_pts(idx_pairs(:,2));
            
            % This is a dummy which should be overwritten in the subclass
            obj.tform = eye(4);
        end
        
    end  % protected methods
    
    
    methods (Access = private)
        
        function [obj] = parseInput(obj, args)
            %PARSEINPUT  Parse P/V pairs
            for c = 1:floor(length(args)/2)
                try
                    switch lower(args{c*2-1})
                        case 'fig2axes', obj.fig2axes = args{c*2};
                        case 'max_points', obj.max_pts = args{c*2};
                        case 'upsample',
                    end
                catch
                    fprintf('unrecognized property or value for: %s\n', ...
                            args{c*2-1});
                end
            end
        end
        
    end  % private methods
    
end


function [img] = normalize0to1(img)
    min_temp = min(min(img));
    max_temp = max(max(img));
    img = (img - min_temp) / (max_temp - min_temp);
end