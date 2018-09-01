function [mask] = getPixelMask(trackbox, img)
% PIXEL MASK
% transformation matrix
M = trackbox.fig2axes.Matrix * trackbox.tform.Matrix;
tb_size = trackbox.getSize();
% side points
v = M * [0, 0, tb_size(1), tb_size(1);
         0, tb_size(2), tb_size(2), 0;
         0, 0, 0, 0;
         1, 1, 1, 1];
% point coordinates w.r.t. the origin
min_x = floor(min(v(1, :)));
max_x = ceil(max(v(1, :)));
min_y = floor(min(v(2, :)));
max_y = ceil(max(v(2, :)));
img_size = size(img);

x = max(1, min_x) : min(max_x, img_size(2));
y = max(1, min_y) : min(max_y, img_size(1));
[X, Y] = meshgrid(x, y);
% mask
in = inpolygon(X, Y, v(1, :), v(2, :));
mask = zeros(img_size);
mask(y, x) = in;
mask = logical(mask);

% % DEBUG
% figure(1);
% imagesc(mask);
% h = gca;
% h.YDir = 'normal';