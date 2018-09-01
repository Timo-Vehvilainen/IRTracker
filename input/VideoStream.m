classdef VideoStream < handle
    %VIDEOSTREAM  Interface between tracker and video frames
    %   VIDEOSTREAM manages the extracted frame data that is located in the
    %   given folder. The user can ask for frames in the folder, get the
    %   frame index listing and check the FPS of the stream.
    
    properties
        is_opened   % indicator if the path is set or not
        path        % path to the folder that contains the frame data
        frames      % all valid frame indexes in the set path
        i_current   % current frame index of the frames listing
    end
    
    methods
        
        function [obj] = VideoStream()
            %VIDEOSTREAM  Create new VideoStream object
            obj.is_opened = false;
            obj.path = '';
        end
        
        
        function open(obj, path)
            %OPEN Open stream from the given path
            obj.is_opened = true;
            obj.path = path;
            obj.updateFrameListing();
            obj.i_current = 0;
        end
        
        
        function [video_frame] = getFirstFrame(obj)
            %GETFIRSTFRAME  Get the first frame of the stream
            obj.i_current = 1;
            video_frame = obj.getFrame(obj.frames(obj.i_current));
            if video_frame.exists == false
                error('VideoStream:FrameNotFound', ...
                      'First frame not found!')
            end
        end
        
        
        function [video_frame] = step(obj)
            %STEP  Get next frame of the stream
            obj.i_current = obj.i_current + 1;
            video_frame = obj.getFrame(obj.frames(obj.i_current));
        end
        
        
        function [video_frame] = getFrame(obj, idx)
            %GETFRAME  Get a frame with a specific index
            varname = ['MAT', num2str(idx)];
            filename = fullfile(obj.path, [varname, '.MAT']);
            video_frame = VideoFrame(idx);
            if exist(filename, 'file')
                obj.i_current = find(obj.frames >= idx, 1);
                frame = open(filename);
                video_frame.setImg(flipud(frame.(varname)));
                video_frame.setDateTime(frame.([varname, '_DateTime']));
            end
        end
        
        
        function [lim] = getFrameLimits(obj)
            %GETFRAMELIMITS  Get indices of the first and the last frame
            lim = [obj.frames(1), obj.frames(end)];
        end
        
        
        function [frame_idx] = getValidFrames(obj)
            %GETVALIDFRAMES  Get valid frame indices of the stream
            frame_idx = obj.frames';
        end
        
        
        function [fps] = getFPS(obj)
            %GETFPS  Get the frame rate of the stream
            frame1 = obj.getFrame(obj.frames(1));
            frame2 = obj.getFrame(obj.frames(2));
            d_date_time = frame2.date_time - frame1.date_time;
            dt = dateTime2ms(d_date_time);
            fps = 1000/dt;
        end
        
    end
    
    methods (Access = private)
        
        function updateFrameListing(obj)
            %UPDATEFRAMELISTING  Get valid frames in the set path
            listing = dir(fullfile(obj.path, '*.MAT'));
            names = cell(size(listing));
            for i = 1 : numel(listing)
                split = strsplit(listing(i).name(4:end), '.');
                names{i} = split{1};
            end
            obj.frames = sort(str2double(names));
        end
    end
    
end


function [ms] = dateTime2ms(date_time)
    %DATETIME2MS Hack conversion from datetime to ms
    coeffs = [31536e6, ...
              2628e6, ...
              864e5, ...
              36e5, ...
              6e4, ...
              1e3, ...
              1];
    ms = sum(date_time .* coeffs);
end
