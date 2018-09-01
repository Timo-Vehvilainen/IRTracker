classdef CumulativeHistogram < handle
    %CUMULATIVEHISTOGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        f  % handle to the figure
        h  % handle to the histogram plot
        bin_limits
    end
    
    methods
        function [obj] = CumulativeHistogram(bin_limits)
            obj.f = figure;
            obj.h = matlab.graphics.GraphicsPlaceholder;
            obj.bin_limits = bin_limits;
        end
    

        function update(obj, data)
            if isgraphics(obj.h, 'histogram')
                obj.h.Data = [obj.h.Data, data(:)];
            else
                % create histogram object
                figure(obj.f);
                obj.h = histogram(data(:), ...
                                  'Normalization', 'probability', ...
                                  'BinLimits', obj.bin_limits, ...
                                  'NumBins', 64);
            end
        end
    end
end

