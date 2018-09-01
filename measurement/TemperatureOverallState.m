classdef TemperatureOverallState < handle
    %TEMPERATUREOVERALLSTATE Temperature image error measurement
    %   TEMPERATUREOVERALLSTATE measures the errors in the temperature
    %   image. The error is measured from background temperature
    %   fluctuation and is done in parts. The parts are determined by the
    %   points where either the camera is calibrated or the signal is lost.
    %
    %  See also TEMPERATUREDATA.
    
    properties (Constant)
        CAL_THRESHOLD = 310         % calibration detection threshold
        BODY_TEMP_MIN = 302         % min recognized body temperature (in K)
        BACKGROUND_TEMP_MAX = 298   % max recognized background temperature
    end
    
    
    properties
        data                    % Error data (type: TemperatureData)
        streams                 % Output visualization streams
        error_signal            % Extracted error signal
        update_error            % Flag indicating if the error signal should be computed
        err_unhandled_start     % Index of the first error data element that is not yet handled
    end
    
    
    methods
        
        function [obj] = TemperatureOverallState(axes_handle)
            %TEMPERATUREOVERALLSTATE  Create new TemperatureOverallState object.
            if nargin == 0 
                obj.streams(1,2) = matlab.graphics.GraphicsPlaceholder;
            else
                % preserve old NextPlot setting
                old_nplot = axes_handle.NextPlot;
                axes_handle.NextPlot = 'add';
                axes_handle.YLim = [294 307];
                obj.streams = [plot(NaN, NaN, 'Parent', axes_handle), ...
                               plot(NaN, NaN, 'Parent', axes_handle)];
                % revert to the old setting
                axes_handle.NextPlot = old_nplot; 
            end
            d(1,2) = TemperatureData;
            obj.data = d;
            obj.error_signal = [];
            obj.update_error = false;
            obj.err_unhandled_start = 1;
        end
        
        
        function [ret] = isPlotting(obj)
            %ISPLOTTING  Check if the visual output stream is open.
            ret = isgraphics(obj.streams(1), 'line');
        end
        
        
        function skip(obj)
            %SKIP  Skip one element.
            for i = 1 : 2
                obj.data(i).skip();
                if obj.isPlotting()
                    obj.streams(i).XData = [obj.streams(i).XData, NaN];
                    obj.streams(i).YData = [obj.streams(i).YData, NaN];
                end
            end
            obj.requestUpdate();
        end
        
        
        function step(obj, t_in, img)
            %STEP  Add measurement point to the stream.
            val_in = [getBodyMeanTemp(img), getBackgroundMeanTemp(img)];
            for i = 1 : 2
                [t, val] = obj.data(i).step(t_in, val_in(i));
                if obj.isPlotting()
                    obj.streams(i).XData = [obj.streams(i).XData, t];
                    obj.streams(i).YData = [obj.streams(i).YData, val];
                end
            end
            % detect calibration
            if val_in(1) > TemperatureOverallState.CAL_THRESHOLD
                obj.requestUpdate();
            end
        end
        
        
        function requestUpdate(obj)
            %REQUESTUPDATE  Request error stream update.
            obj.update_error = true;
        end
        
        
        function [err_signal, idx_start] = updateError(obj)
            %UPDATEERROR  Update error stream.
            err_signal = [];
            idx_start = 0;
            if obj.update_error
                [err_signal, idx_start] = obj.getErrorInterval();
                obj.error_signal = [obj.error_signal, err_signal];
                obj.update_error = false;
            end
        end
        
    end  % public methods
    
    
    methods (Access = protected)
        
        function [err_signal, idx_start] = getErrorInterval(obj)
            %GETERRORINTERVAL  Get error signal for previously unhandled frames.
            idx_start = obj.err_unhandled_start;
            idx_end = obj.data(2).i_back - 2;
            data_in = obj.data(2).val_data(idx_start:idx_end);
            err_signal = [data_in - mean(data_in), 0];
            obj.err_unhandled_start = obj.data(2).i_back;
        end
        
    end  % protected methods
    
end


function [T] = getBodyMeanTemp(img)
    T = mean(img(img > TemperatureOverallState.BODY_TEMP_MIN));
end


function [T] = getBackgroundMeanTemp(img)
    T = mean(img(img < TemperatureOverallState.BACKGROUND_TEMP_MAX));
end
