classdef FrameTracker < handle
    %FRAMETRACKER  High level tracker logic
    %
    %  FRAMETRACKER handles the high level logic of the tracking process. 
    %  It takes VideoFrame objects as an input and passes the required
    %  information to the regional trackers.
    %
    %  See also TBTRACKER, MOVEMENTTRACKER, VIDEOFRAME.
    
    properties
        is_running  % The state of the tracker
        trackboxes  % Trackboxes under tracking
        trackers    % TBTracker objects associated with the trackboxes
        n_trackers  % Number of trackers
        h_features  % handles to the feature graphics objects
    end
    
    
    methods
        
        function [obj] = FrameTracker()
            %FRAMETRACKER  Construct FrameTracker object
            obj.is_running = 0;
            obj.n_trackers = 0;
            obj.trackers = TBTracker.empty(0);
            obj.h_features = gobjects(0);
        end
        
       
        function [obj] = setUp(obj, img, rectangles, varargin)
            %SETUP  Set up trackers for Trackbox objects
            obj.n_trackers = length(rectangles);
            if obj.n_trackers > 0
                % continue setup if we have something to track
                obj.trackboxes = getTrackboxes(rectangles);
                obj.trackers(1, obj.n_trackers) = TBTracker;
                for i = 1 : obj.n_trackers
                    trackbox = obj.trackboxes(i);
                    obj.trackers(i) = TBTracker( ...
                        img, ...
                        trackbox.getTrackboxData(), ...
                        varargin{:});
                end
                obj.setupFeatureGObjects();
            end
        end
        
        
        function [obj] = step(obj, next_frame)
            %STEP  Track next frame
            img = next_frame.img;
            %@TODO: parallelize this (if the tree functionality is no-go)
            for tracker = obj.trackers
                % run subtrackers
                tracker.step(img);
            end
            for i = 1 : obj.n_trackers
                % gather the results
                obj.trackboxes(i).setTrackboxData(...
                    obj.trackers(i).getOutput());
            end
        end
        
        
        function [obj] = plotMatchedFeatures(obj)
            %PLOTMATCHEDFEATURES  Plot features captured by the trackers
            for i = 1 : obj.n_trackers
                tracker = obj.trackers(i);
                h = obj.h_features(i);
                
                % get handles
                h1 = findobj(h, 'Tag', 'pts0');
                h2 = findobj(h, 'Tag', 'pts1');
                h3 = findobj(h, 'Tag', 'connections');

                points0 = double(tracker.matched0.Location);
                points1 = double(tracker.matched1.Location);
                % update point data
                h1.XData = points0(:,1);
                h1.YData = points0(:,2);
                h2.XData = points1(:,1); 
                h2.YData = points1(:,2);

                % Plot by using a single line object; break the line by 
                % using NaNs.
                [n_points, ~] = size(points0);
                lineX = [points0(:,1)'; points1(:,1)'; NaN(1, n_points)];
                lineY = [points0(:,2)'; points1(:,2)'; NaN(1, n_points)];

                % update line data
                h3.XData = lineX(:);
                h3.YData = lineY(:);
            end
        end
        
    end  % methods
    
    
    methods (Access = private)
        
        function [obj] = setupFeatureGObjects(obj)
            %SETUPFEATUREGOBJECTS Format feature graphics objects
            
            % clear the old graphics and set up a new graphics array
            delete(obj.h_features);
            obj.h_features = gobjects(1, obj.n_trackers);
            for i = 1 : obj.n_trackers
                tracker = obj.trackers(i);
                parent = obj.trackboxes(i).tform;
                % set up transform object of the track points
                h = hgtransform('Parent', parent);
                h.Matrix = makehgtform('scale', 1/tracker.upsample);
                % set up track point graphics
                plot(NaN, NaN, 'ro', 'Parent', h, 'Tag', 'pts0');
                plot(NaN, NaN, 'g+', 'Parent', h, 'Tag', 'pts1');
                plot(NaN, NaN, 'y-', 'Parent', h, 'Tag', 'connections');
                obj.h_features(i) = h;
            end
        end
        
    end  % private methods
    
end

function [trackboxes] = getTrackboxes(rectangles)
    %GETTRACKBOXES extract Trackbox objects from rectangles
    n_rectangles = numel(rectangles);
    trackboxes(1,n_rectangles) = Trackbox;
    for i = 1 : n_rectangles
        trackboxes(i) = rectangles(i).UserData.h_trackbox;
    end
end

% % DO NOT DO THIS HERE: You need to maximize the contrast within trackbox
% function [img] = normalize0to1(frame)
%     img = (frame.img - frame.min_temp) / (frame.max_temp - frame.min_temp);
% end
