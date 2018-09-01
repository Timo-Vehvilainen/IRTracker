function [arrow_handle] = update_arrow(arrow_handle, varargin)

% return if no update data is given
if isempty(varargin)
    return;
end

% TODO: validate arrow_handle


alpha       = 0.15;   % head length
beta        = 0.07;   % head width
max_length  = 22;

% =============================================
% fetch updated arrow start/end points
% =============================================
% get old start/end points
x1 = arrow_handle(1).XData(1);
x2 = arrow_handle(1).XData(2);
y1 = arrow_handle(1).YData(1);
y2 = arrow_handle(1).YData(2);
% fetch new start and/or end point
for c = 1:floor(length(varargin)/2)
    try
        switch lower(varargin{c*2-1})
        case 'start',
            x1 = varargin{c*2}(1);
            y1 = varargin{c*2}(2);
        case 'end', 
            x2 = varargin{c*2}(1);
            y2 = varargin{c*2}(2);
        end
    catch
        fprintf( 'unrecognized property or value for: %s\n',varargin{c*2-1} );
    end
end

% =============================================
% calculate the arrow head coordinates
% =============================================
den         = x2 - x1 + eps;                                % make sure no devision by zero occurs
teta        = atan( (y2-y1)/den ) + pi*(x2<x1) - pi/2;      % angle of arrow
cs          = cos(teta);                                    % rotation matrix
ss          = sin(teta);
R           = [cs -ss;ss cs];
line_length = sqrt( (y2-y1)^2 + (x2-x1)^2 );                % sizes
head_length = min( line_length*alpha,max_length );
head_width  = min( line_length*beta,max_length );
x0          = x2*cs + y2*ss;                                % build head coordinats
y0          = -x2*ss + y2*cs;
coords      = R*[x0 x0+head_width/2 x0-head_width/2; y0 y0-head_length y0-head_length];


% =============================================
% update arrow  (= line + patch of a triangle)
% =============================================
arrow_handle(1).XData = [x1, x2];
arrow_handle(1).YData = [y1, y2];
arrow_handle(2).XData = coords(1,:);
arrow_handle(2).YData = coords(2,:);
