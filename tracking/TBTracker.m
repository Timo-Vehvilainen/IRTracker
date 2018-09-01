classdef TBTracker < MovementTracker
    %TBTRACKER  Trackbox tracking logic
    %  TBTRACKER tracks the movement of one Trackbox object. 
    
    properties
        tb_data0    % data associated with the trackbox (current frame)
        tb_data1    % data associated with the trackbox (previous frame)
        
        skipped     % indicator if the previous frame was skipped
        upsample    % upsample coefficient of the input image
    end
    
    
    methods
        
        function obj = TBTracker(img, trackbox_data, varargin)
            %TBTRACKER  Construct a new Trackbox tracker object
            obj = obj@MovementTracker(varargin{:});
            if nargin == 0, return; end;  % construct a dummy
            
            obj.tb_data1 = trackbox_data;
            obj.tb_data0 = TrackboxData('data', trackbox_data);
            obj.skipped = 0;
            obj.upsample = 1;
            
            % extract features of the first frame
            obj.extractFeatures(img);
        end
       
        
        function step(obj, img)
            %STEP  Track one frame of trackbox movement
            if obj.skipped == 0
                obj.moveToNextFrame();
            end
            obj.predictFrame(img);
            % Update orientation of the trackbox
            obj.computeTBOrientation();
        end
        
        
        function [data] = getOutput(obj)
            %GETOUTPUT  Get the output of the tracker
            data = obj.tb_data1;
        end
        
    end  % public methods
    
    
    methods (Access = protected)
            
        function computeTBOrientation(obj)
            %COMPUTETBORIENTATION  Compute the orientation of the Trackbox
            
            % copy the old data 
            %  (done here instead of in advanceOneFrame method in order to 
            %   avoid trackbox oscillation)
            obj.tb_data0.set('data', obj.tb_data1);
            % How many percent the new tform affects the trackbox matrix
            new_tform_coeff = 1.0;
            obj.tb_data1.setMatrix( ...
                new_tform_coeff * obj.tform * obj.tb_data1.Matrix ...
                + (1 - new_tform_coeff) * obj.tb_data1.Matrix);
        end
        
        
        function extractFeatures(obj, img)
            %EXTRACTFEATURES  Extract features of the trackbox
            
            % Crop the image to fit the trackbox & upsample.
            rect_img = getImgInsideRect(obj.tb_data1, ...
                                        img, ...
                                        obj.fig2axes, ...
                                        obj.upsample);
            % Continue process with the cropped & upsampled image
            extractFeatures@MovementTracker(obj, rect_img);
        end
        
        
        function predictFrame(obj, img)
            %PREDICTFRAME  Estimate the movement of the image
            predictFrame@MovementTracker(obj, img);
            
            % temp variables for transformed points
            tformed0 = transformPoints(obj.matched0, obj.tb_data0.Matrix);
            tformed1 = transformPoints(obj.matched1, obj.tb_data1.Matrix);
            
            try
                % @TODO: use inliers to update data1.pts
                %        * problem: these are in the fi
                [tform2d, ~, inlier1] = ...
                    estimateGeometricTransform(tformed0, ...
                                               tformed1, ...
                                               'similarity');
                obj.skipped = 0;
                obj.data1.pts = transformPoints(...
                    inlier1, eye(4)/obj.tb_data1.Matrix);
            catch
                obj.skipped = 1;
                return;
            end
            obj.tform = affine2d2Mat4f(tform2d);
        end
        
    end  % protected methods
    
    
    methods (Access = private)
        
        function [obj] = parseInput(obj, args)
            %PARSEINPUT parse P/V pairs
            for c = 1:floor(length(args)/2)
                try
                    switch lower(args{c*2-1})
                        case 'fig2axes',
                        case 'max_points',
                        case 'upsample', obj.upsample = args{c*2};
                    end
                catch
                    fprintf('unrecognized property or value for: %s\n', ...
                            args{c*2-1});
                end
            end
        end
        
    end  % private methods
    
end


function [tform_out] = affine2d2Mat4f(tform_in)
    tform_out = eye(4);
    tform_out([1 2 4], [1 2 4]) = tform_in.T';
end


function [pts] = transformPoints(pts, tform)
    temp = [pts.Location, ones(length(pts), 1)] * (tform([1 2 4],[1 2 4]))';
    temp = temp(:, 1:2);
    mask = temp(:,1) > 0 & temp(:,2) > 0;
    pts = pts(mask);
    pts.Location = temp(mask,:);
end
