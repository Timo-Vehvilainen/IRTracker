classdef TOutput < handle
    %TOUTPUT  temperature stream of one measurement node
    %   TOUTPUT represents a temperature stream of one measurement node. It
    %   tracks the mean temperature of the image region that lies within
    %   the given measurement box. Basic averaging is also applied on the 
    %   measurement signal.
    %
    %  See also TEMPERATUREDATA.
    
    properties
        temp_data   % Temperature data of the stream (type: TemperatureData)
        stream      % Visualization of the temperature output stream (type: plot)
    end
    
    methods
        
        function [obj] = TOutput(h_axes, varargin)
            %TOUTPUT  Create new Toutput object.
            if nargin == 0 
                obj.stream = matlab.graphics.GraphicsPlaceholder;
            else
                obj.stream = plot(NaN, NaN, 'Parent', h_axes);
            end
            obj.temp_data = TemperatureData;
            
            obj.parseInput(varargin);
        end
        
        
        function [ret] = isPlotting(obj)
            %ISPLOTTING  Check if the visual output stream is open.
            ret = isgraphics(obj.stream, 'line');
        end
        
        
        function cutLine(obj)
            %CUTLINE  Cut the temperature stream.
            obj.temp_data.skip();
            if obj.isPlotting()
                obj.stream.XData = [obj.stream.XData, NaN];
                obj.stream.YData = [obj.stream.YData, NaN];
            end
        end
        
        
        function step(obj, t_in, val_in)
            %STEP  Add measurement point to the stream.
            [t, val] = obj.temp_data.step(t_in, val_in);
            if obj.isPlotting()
                obj.stream.XData = [obj.stream.XData, t];
                obj.stream.YData = [obj.stream.YData, val];
            end
        end
        
        
        function setErrorInterval(obj, err_signal, start_idx)
            %SETERRORINTERVAL  Set signal error for a certain sample interval.
            [t_fixed, val_fixed] = obj.temp_data.setError(err_signal, ...
                                                          start_idx);
            indices = (start_idx - 1) + (1 : length(err_signal));
            if obj.isPlotting()
                obj.stream.XData(indices) = t_fixed;
                obj.stream.YData(indices) = val_fixed;
            end
        end
        
    end  % public methods
    
    
    methods (Access = protected)
        
        function parseInput(obj, args)
            %PARSEINPUT  Parse P/V pairs.
            for c = 1:floor(length(args)/2)
                try
                    switch lower(args{c*2-1})
                        case 'color', obj.stream.Color = args{c*2};
                        case 'linestyle', obj.stream.LineStyle = args{c*2};
                    end
                catch
                    fprintf('unrecognized property or value for: %s\n', ...
                            args{c*2-1});
                end
            end
        end
        
    end  % protected methods
end

