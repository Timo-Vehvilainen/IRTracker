function [img_in_rect] = getImgInsideRect(tb_data, img, fig2axes, upsample)
%GETIMGINSIDERECT Get image values inside the given rectangle

% IMAGE INSIDE RECT
tform = fig2axes * tb_data.Matrix;
img_in_rect = interpolateFromImg(tb_data, img, tform, upsample);



function uv = getRectUVCoordinates(tb_data, img, tform)
M = tform;
rect_size = tb_data.Size;
img_size = size(img);
% create rect corner coordinates
p = [0, 0, rect_size(1), rect_size(1); ...
     0, rect_size(2), rect_size(2), 0; ...
     0, 0, 0, 0; ...
     1, 1, 1, 1];
% transform to img space
p_img = M * p;
% convert to uv
uv = p_img(1:2, 1:4);
uv(1,:) = uv(1,:) / img_size(2);
uv(2,:) = uv(2,:) / img_size(1);


function img_out = interpolateFromImg(tb_data, img, tform, upsample)
rect_uv = getRectUVCoordinates(tb_data, img, tform);
% get uv value for each image pixel
img_size = size(img);
[u_orig, v_orig] = meshgrid(linspace(0, 1, img_size(2)), ...
                            linspace(0, 1, img_size(1)));
% get uv value for each output pixel
img_out_size = floor(upsample * tb_data.Size);
[u, v] = rotatedGrid(rect_uv, img_out_size);
% fetch the value of the pixel from the original image
img_out = interp2(u_orig, v_orig, img, u, v);


function [u, v] = rotatedGrid(rect_uv, grid_size)
x_dim = grid_size(1); 
y_dim = grid_size(2);
u = zeros(y_dim, x_dim);
v = zeros(y_dim, x_dim);
edge1 = [linspace(rect_uv(1,1), rect_uv(1,2), y_dim); ...
         linspace(rect_uv(2,1), rect_uv(2,2), y_dim)];
edge2 = [linspace(rect_uv(1,4), rect_uv(1,3), y_dim); ...
         linspace(rect_uv(2,4), rect_uv(2,3), y_dim)];
for i = 1 : y_dim
    u(i, :) = linspace(edge1(1,i), edge2(1,i), x_dim);
    v(i, :) = linspace(edge1(2,i), edge2(2,i), x_dim);
end


% function plotRectInImgCoordinates(rect, img)
% rect_uv = getRectUVCoordinates(rect, img);
% img_size = size(img);
% x = rect_uv(1,:) * img_size(2);
% y = rect_uv(2,:) * img_size(1);
% plot([x, x(1)], [y, y(1)], 'Color', [0.75, 0.0, 0.6])
