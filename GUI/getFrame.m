function [video_frame] = getFrame(idx, folder)
    %GETFRAME generate VideoFrame object from Matlab data file
    filename = [folder, 'MAT', num2str(idx), '.MAT'];
    video_frame = VideoFrame(idx);
    if exist(filename, 'file')
        frame = open(filename);
        img = frame.(['MAT', num2str(idx)]);
        video_frame.setImg(flipud(img));
    end
end
