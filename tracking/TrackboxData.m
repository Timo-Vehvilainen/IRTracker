classdef TrackboxData < handle
    %TRACKBOXDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Matrix
        Size
    end
    
    methods
        
        function [obj] = TrackboxData(varargin)
            obj.Matrix = eye(4);
            obj.Size = [1, 1];
            obj.parseInput(varargin);
        end
        
        
        function set(obj, varargin)
            obj.parseInput(varargin);
        end
<<<<<<< Updated upstream
        
=======
     
      
>>>>>>> Stashed changes
        
        function setMatrix(obj, M)
            [scale, rotation, translation] = splitMatrix(M);
            obj.Matrix = translation * rotation;
            obj.Size = scale * obj.Size;
        end
        
        function parseInput(obj, args)
            %PARSEINPUT  Parse P/V pairs
            for c = 1:floor(length(args)/2)
                try
                    switch lower(args{c*2-1})
                        case 'data'
                            % Copy constructor
                            other = args{c*2};
                            obj.Matrix = other.Matrix;
                            obj.Size = other.Size;
                        case 'matrix'
                            obj.Matrix = args{c*2};
                        case 'parent',
                        case 'position'
                            pos = args{c*2};
                            obj.Matrix = makehgtform('translate', ...
                                                     [pos(1:2), 0]) ...
                                         * obj.Matrix;
                        case 'size'
                            obj.Size = args{c*2};
                    end
                catch
                    fprintf('unrecognized property or value for: %s\n', ...
                            args{c*2-1});
                end
            end
        end
        
    end  % methods
    
end


function [scale, rotation, translation] = splitMatrix(M)
    % get scale and angle
    scale = hypot(M(1,1), M(1,2));
    angle = sign(M(2,1)) * acos(1/scale * M(1,1));
    rotation = makehgtform('zrotate', angle);
    translation = makehgtform('translate', M(1:3, 4));
end
