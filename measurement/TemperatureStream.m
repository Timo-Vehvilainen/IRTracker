classdef TemperatureStream < handle
    %TEMPERATURESTREAM  Stream the temperature of the measurement nodes
    %  TEMPERATURESTREAM is a top-level process for measuring temperatures
    %  of the measurement nodes. It opens temperature output streams for
    %  every measurement node and tracks the temperature changes in each of
    %  those boxes. It also applies noise and drift reduction on outptut
    %  signals.
    %
    %  See also TOUTPUT, TEMPERATUREOVERALLSTATE, TRACKBOX.
    
    properties (Constant)
        BODY_TEMP_MIN = 302  % min recognized body temperature (in K)
    end
        
    
    properties
        fig                 % output figure
        measurement_nodes   % measurement nodes to track (type: Trackbox)
        streams             % plot handle for each of the Trackbox objects
        frame_temp_stream   % stream for body/background temperatures
        n_streams           % number of output temperature streams
        n_frame             % number of the current frame
        max_temp            % temperature plot upper limit
        min_temp            % temperature plot lower limit
    end
    
    methods
        
        function [obj] = TemperatureStream(rectangles, varargin)
            %TEMPERATURESTREAM  Create new TemperatureStream object.
            obj.n_streams = 1;
            obj.measurement_nodes = {};
            % Get and count measurement nodes
            for i = 1 : length(rectangles)
                trackbox = rectangles(i).UserData.h_trackbox;
                if trackbox.is_measurement_node == true
                    obj.measurement_nodes{obj.n_streams} = trackbox;
                    obj.n_streams = obj.n_streams + 1;
                end
            end
            obj.fig = figure;
            temp(obj.n_streams, 1) = TOutput;
            obj.streams = temp;
            % Create temperature streams
            for i = 1 : obj.n_streams - 1
                h = subplot(obj.n_streams, 1, i);
                obj.streams(i) = TOutput(h);
            end
            % create img stream
            h = subplot(obj.n_streams, 1, obj.n_streams);
            obj.frame_temp_stream = TemperatureOverallState(h);
            obj.n_frame = 1;
            obj.parseInput(varargin);
        end
        
        
        function [obj] = update(obj, frame)
            %UPDATE  Update temperature stream according to VideoFrame.
            idx = frame.idx;
            img = frame.img;
            % update img stream
            stream = obj.frame_temp_stream;
            if idx - 1 ~= obj.n_frame
                % Cut the line
                stream.skip();
                stream.requestUpdate();
            end
            % Compute error if requested
            [err_val, idx_start] = stream.updateError();
            stream.step(frame.idx, img);
            % update measurement streams
            for i = 1 : obj.n_streams - 1
                stream = obj.streams(i);
                node = obj.measurement_nodes{i};
                % Check if the this and the previous frame are not
                % consequent
                if idx - 1 ~= obj.n_frame
                    % Cut the line if this is the case
                    stream.cutLine();
                end
                if idx_start ~= 0
                    stream.setErrorInterval(err_val, idx_start);
                end
                stream.step(idx, getMeanTemperature(node, img));
            end
            obj.n_frame = frame.idx;
        end         
            
    end  % methods
    
    
    methods (Access = protected)
        
        function [obj] = parseInput(obj, args)
            %PARSEINPUT  Parse P/V pairs.
            for c = 1:floor(length(args)/2)
                try
                    switch lower(args{c*2-1})
                        case 'min_temperature'
                            val = args{c*2};
                            for i = 1 : obj.n_streams - 1
                                h = subplot(obj.n_streams, 1, i);
                                h.YLim = [val, h.YLim(2)];
                                h.YLimMode = 'manual';
                            end
                        case 'max_temperature'
                            val = args{c*2};
                            for i = 1 : obj.n_streams - 1
                                h = subplot(obj.n_streams, 1, i);
                                h.YLim = [h.YLim(1), val];
                                h.YLimMode = 'manual';
                            end
                    end
                catch
                    fprintf('unrecognized property or value for: %s\n', ...
                            args{c*2-1});
                end
            end
        end
        
    end  % protected methods
    
end

        
function [T] = getMeanTemperature(node, img)
    %GETTEMPERATURE  Get the mean temperature of the node
    mask = getPixelMask(node, img);
    points = img(mask);
    T = mean(points(points > TemperatureStream.BODY_TEMP_MIN));
end

