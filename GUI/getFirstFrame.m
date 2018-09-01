function [video_frame] = getFirstFrame(path)
%GETFIRSTFRAME Summary of this function goes here
%   Detailed explanation goes here

    % TODO: do this smarter!
    i_max = 90;
    for i = 1 : i_max
        video_frame = getFrame(i, path);
        if video_frame.exists == true
            return;
        end;
    end;
    error('getFirstFrame: first frame not found!')
end

