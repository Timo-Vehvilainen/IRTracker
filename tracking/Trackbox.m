classdef Trackbox < handle
    %TRACKBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        COLOR_NORMAL = [0, 0, 0];
        COLOR_MEASUREMENT = [1, 1, 1];
        LINE_WIDTH = 1.5;
    end
    
    properties
        % Rectangle abstraction
        rect
        tform
        fig2axes
        % Information about the trackbox
        angle
        centroid
        is_measurement_node
        % Handles to the measurement tree graphics
        parent_rect
        child_rect
        edges
    end
    
    methods(Static)
        function [b_val] = exists(trackbox)
            b_val = isgraphics(trackbox.rect, 'rectangle');
        end
    end  % static methods
    
    methods
        
        function [obj] = Trackbox(box_pos, fig2axes_handle)
            if nargin == 0  % create a dummy
                obj.rect = matlab.graphics.GraphicsPlaceholder;
                return;
            end
            % set figure-to-axes transform
            obj.fig2axes = fig2axes_handle;
            % set box specific transform matrix
            obj.tform = hgtransform('Parent', obj.fig2axes);
            obj.tform.Matrix = makehgtform('translate', [box_pos(1:2), 0]);
            box_pos(1:2) = [0, 0];
            % draw a new box
            obj.rect = rectangle( ...
                'Position', box_pos, ...
                'Parent', obj.tform, ...
                'ButtonDownFcn', @(hObject,eventdata)tracker( ...
                                     'rect_ButtonDownFcn', ...
                                     hObject, ...
                                     eventdata, ...
                                     guidata(hObject)), ...
                'EdgeColor', Trackbox.COLOR_NORMAL, ...
                'LineWidth', Trackbox.LINE_WIDTH, ...
                'Tag', 'tracker');
            obj.rect.UserData.h_trackbox = obj;
            % set up trackbox info
            obj.angle = 0;
            obj.centroid = box_pos(1:2) + 0.5 * box_pos(3:4);
            obj.is_measurement_node = 0;
            
            obj.parent_rect = [];
            obj.child_rect = [];
            obj.edges = [];
        end
        
       
        function [obj] = select(obj, val)
            if nargin < 2, val = 'on'; end;
            set(obj.rect, 'selected', val);
        end
        
        
        function [obj] = setAsMeasurementNode(obj, value)
            if nargin < 2, value = 1; end;
            % set the selected node as a measurement node
            obj.is_measurement_node = value;
            if value ~= 0
                obj.rect.EdgeColor = Trackbox.COLOR_MEASUREMENT;
            else
                obj.rect.EdgeColor = Trackbox.COLOR_NORMAL;
            end
        end
        
        
        function [obj] = setPosition(obj, pos)
            obj.tform.Matrix = makehgtform('translate', [pos(1:2), 0]) ...
                               * obj.tform.Matrix;
            obj.rect.Position = [0, 0, pos(3:4)];
        end
        
        
        function [data] = getTrackboxData(obj)
            data = TrackboxData('Matrix', obj.tform.Matrix, ...
                                'Size', obj.rect.Position(3:4));
        end
        
        
        function [obj] = setTrackboxData(obj, data)
            obj.tform.Matrix = data.Matrix;
            obj.rect.Position(3:4) = data.Size;
        end
        
        
        function [ret] = getSize(obj)
            ret = obj.rect.Position(3:4);
        end
        
        
        function [obj] = addChildNode(obj, trackbox)
            h = createConnectionLine(obj, trackbox, obj.fig2axes);
            obj.edges = [obj.edges, h];
            obj.child_rect = [obj.child_rect, trackbox];
            trackbox.parent_rect = [trackbox.parent_rect, obj];
        end
        
        
        function [obj] = updateAngle(obj)
            obj.angle = ...
                sign(obj.tform.Matrix(2,1)) * acos(obj.tform.Matrix(1,1));
        end
        
        
        function [obj] = updateCentroid(obj)
            obj.centroid = obj.rect.Position(1:2) ...
                           + 0.5 * obj.rect.Position(3:4);
        end
        
        
        function [obj] = updateConnectionLines(obj)
            p = (obj.tform.Matrix * [obj.centroid, 0, 1]')';
            p = p(1:2);
            n_edges = floor(length(obj.edges)/2);
            for i = 1 : n_edges
                edge_mask = 2 * i + (-1 : 0);
                data.edges(edge_mask) = update_arrow(...
                    obj.edges(edge_mask), 'Start', p);
            end
            n_parents = length(obj.parent_rect);
            for i = 1 : n_parents
                parent = obj.parent_rect(i);
                i_edge = find(parent.child_rect == obj);
                edge_mask = 2 * i_edge + (-1 : 0);
                parent.edges(edge_mask) = update_arrow( ...
                    parent.edges(edge_mask), 'End', p);
            end
        end
        
    end  % methods
    
end

function [h] = createConnectionLine(tb1, tb2, fig2axes)
    p1 = (tb1.tform.Matrix * [tb1.centroid, 0, 1]')';
    p2 = (tb2.tform.Matrix * [tb2.centroid, 0, 1]')';
    h = plot_arrow(p1(1), p1(2), p2(1), p2(2), 'Parent', fig2axes);
end