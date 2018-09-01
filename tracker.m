function varargout = tracker(varargin)
% TRACKER MATLAB code for tracker.fig
%      TRACKER, by itself, creates a new TRACKER or raises the existing
%      singleton*.
%
%      H = TRACKER returns the handle to a new TRACKER or the handle to
%      the existing singleton*.
%
%      TRACKER('CALLBACK',hObject,~,handles,...) calls the local
%      function named CALLBACK in TRACKER.M with the given input arguments.
%
%      TRACKER('Property','Value',...) creates a new TRACKER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tracker_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tracker_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tracker

% Last Modified by GUIDE v2.5 17-Jun-2015 10:06:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @tracker_OpeningFcn, ...
                   'gui_OutputFcn',  @tracker_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before tracker is made visible.
function tracker_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tracker (see VARARGIN)

% Choose default command line output for tracker
addpath(genpath('lib'), 'GUI', 'input', 'tracking', 'measurement');
handles.output = hObject;

% Clear axes to ensure clean start
cla(handles.img_axes);

% Set color map of the axes
cmap = getColorPalette();
colormap(handles.img_axes, cmap);
set(handles.img_axes, 'Color', cmap(1,:));

% Set video properties
handles.video_stream = VideoStream;
handles.current_frame = VideoFrame;
handles.img_handle = matlab.graphics.GraphicsPlaceholder;
handles.tracker = FrameTracker;

% set trackbox manipulators
handles = setupRectGraphics(handles);
handles.trackbox = Trackbox;

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes tracker wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = tracker_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in set_load_path_button.
function set_load_path_button_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to set_load_path_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dir_name = uigetdir();
if (dir_name ~= 0)
% <<<<<<< Updated upstream
%     handles.video_stream.open(dir_name);
%     handles.load_path_text.String = dir_name;
%     handles.current_frame = handles.video_stream.getFirstFrame();
% =======
    path = [dir_name, '/'];
    handles.load_path_text.String = path;
    handles.load_path_text.String = dir_name;
    handles.load_path_set = 1;
    handles.current_frame = getFirstFrame(path);
% >>>>>>> Stashed changes
    frame = handles.current_frame;
    % get frame slider properties
    frame_limits = handles.video_stream.getFrameLimits();
    handles.frame_slider.Min = frame_limits(1);
    handles.frame_slider.Max = frame_limits(2);
    handles.frame_slider.Value = frame.idx;
    max_n_frames = frame_limits(2) - frame_limits(1) + 1;
    handles.frame_slider.SliderStep = [1/max_n_frames, 10/max_n_frames];
    % clear current axes
    cla(handles.img_axes);
    handles = setupRectGraphics(handles);
    % load image
    handles.img_handle = image(frame.img, 'CDataMapping', 'scaled');
    caxis(handles.img_axes, [min(min(frame.img)), max(max(frame.img))]);
    
    
    uistack(handles.img_handle, 'bottom');
    handles.img_handle.ButtonDownFcn = @(hObject,eventdata)tracker('img_axes_ButtonDownFcn',hObject,eventdata,guidata(hObject));
    
    % set color bar
    colorbar(handles.img_axes, 'east')
    
    guidata(hObject, handles);
end


% --- Executes on slider movement.
function frame_slider_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
frame_idx = int32(get(hObject,'Value'));
handles.current_frame = handles.video_stream.getFrame(frame_idx);
set(handles.img_handle, 'CData', handles.current_frame.img);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function frame_slider_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in track_button.
function track_button_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to track_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.tracker.is_running == 0 && handles.video_stream.is_opened
    handles.tracker.is_running = 1;
    guidata(hObject, handles);
else
    return;
end
tracker = handles.tracker;
upsample_coeff = 2;
max_points_per_tracker = 250;
% set up trackers for each box
rectangles = findobj('Type', 'rectangle', 'Tag', 'tracker');
tracker = tracker.setUp(handles.current_frame.img, ...
                        rectangles, ...
                        'fig2axes', handles.fig2axes, ...
                        'max_points', max_points_per_tracker, ...
                        'upsample', upsample_coeff);
output = TemperatureStream(rectangles, ...
                           'max_temperature', 309.5, ...
                           'min_temperature', 306.5);
% hist = CumulativeHistogram(handles.img_axes.CLim);
guidata(hObject, handles);
tic;
fps = handles.video_stream.getFPS();
for idx = handles.video_stream.getValidFrames()
    handles = guidata(hObject);
    if handles.tracker.is_running == 0
        break;
    end
    % get new frame
    handles.current_frame = handles.video_stream.step();
    handles.frame_slider.Value = idx;
    % process the frame
    tracker = tracker.step(handles.current_frame);
    tracker = tracker.plotMatchedFeatures();
    % store the data and update GUI
    output.update(handles.current_frame);
%         hist.update(handles.current_frame.img);
    set(handles.img_handle, 'CData', handles.current_frame.img);
    guidata(hObject, handles);
    drawnow;
    pause(max(0, 1/fps - toc));
    tic;
end
handles.tracker.is_running = 0;
guidata(hObject, handles);


% --- Executes on button press in track_stop_button.
function track_stop_button_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to track_stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.tracker.is_running = 0;
guidata(hObject, handles);


% --- Executes on selection change in tool_selection_menu.
function tool_selection_menu_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to tool_selection_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tool_selection_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tool_selection_menu
tool = get(hObject,'Value');

% select current box
if Trackbox.exists(handles.trackbox) % something is selected
    trackbox = handles.trackbox;
    if tool == 3  % RESIZE
        % set handles to their correct positions
        handles.transform.resize_handles.Parent = trackbox.tform;
        handles = updateResizeHandlePositions(handles);
        % replace selection markups with resize handles
        trackbox.select('off');
        handles.transform.resize_handles.Visible = 'on';
    else
        % ensure that resize handles are hidden
        trackbox.select('on');
        handles.transform.resize_handles.Visible = 'off';
    end
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tool_selection_menu_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
% hObject    handle to tool_selection_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
                   get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in measurement_node_checkbox.
function measurement_node_checkbox_Callback(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to measurement_node_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of measurement_node_checkbox
if Trackbox.exists(handles.trackbox)
    handles.trackbox.setAsMeasurementNode(get(hObject, 'Value'));
end
guidata(hObject, handles);


% --- Executes on mouse press over axes background.
function img_axes_ButtonDownFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to img_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tool = handles.tool_selection_menu.Value;
handles = unselectRect(handles);
if tool == 1  % draw
    handles = createBox(rbbox, eventdata, handles);
end
guidata(hObject, handles);


function rect_ButtonDownFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to img_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tool = handles.tool_selection_menu.Value;
fig = gcf;
handles = setSelectedRect(hObject, handles);
trackbox = handles.trackbox;

if tool == 1
    handles = unselectRect(handles);
    handles = createBox(rbbox, eventdata, handles);
elseif tool == 2  % MOVE
    % setup ghost box
    handles.transform.M.Parent = handles.fig2axes_M;
    handles.transform.M.Matrix = trackbox.tform.Matrix;
    handles.transform.ghost_box.Position = trackbox.rect.Position;
    handles.transform.mouse_starting_pos = fig.CurrentPoint;
    % All ready: flag process as started and set things visible
    handles.transform.in_progress = 1;
    handles.transform.M.Visible = 'on';
elseif tool == 3  % RESIZE
    % reset transform helpers but do nothing in particular
    handles.transform.M.Parent = handles.fig2axes_M;
    handles.transform.M.Matrix = trackbox.tform.Matrix;
    handles.transform.ghost_box.Position = trackbox.rect.Position;
    handles.transform.in_progress = 0;
elseif tool == 4  % ROTATE
    % setup ghost box
    handles.transform.M.Parent = trackbox.tform;
    handles.transform.M.Matrix = eye(4);
    handles.transform.ghost_box.Position = trackbox.rect.Position;
    % setup rotation assist line
    box_center = trackbox.tform.Matrix * [trackbox.centroid, 0, 1]';
    mouse_pos = fig.CurrentPoint;
    handles.transform.line.XData = [mouse_pos(1), ...
                                   box_center(1), ...
                                   mouse_pos(1)];
    handles.transform.line.YData = [mouse_pos(2), ...
                                   box_center(2), ...
                                   mouse_pos(2)];
    % All ready: flag process as started and set things visible
    handles.transform.in_progress = 3;
    handles.transform.M.Visible = 'on';
    handles.transform.line.Visible = 'on';
elseif tool == 5  % CONNECT
    
    %setup connection line
    mouse_pos = fig.CurrentPoint;
    box_center = trackbox.tform.Matrix * [trackbox.centroid, 0, 1]';
    handles.transform.line.XData = [mouse_pos(1), box_center(1)];
    handles.transform.line.YData = [mouse_pos(2), box_center(2)];
    % get all possible rectangles
    handles.transform.current_candidate = ...
        matlab.graphics.GraphicsPlaceholder;
    % All ready: flag process as started and set things visible
    handles.transform.in_progress = 4;
    handles.transform.line.Visible = 'on';
end
guidata(hObject, handles);
drawnow;


function resize_handle_ButtonDownFcn(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to img_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tool = handles.tool_selection_menu.Value;
if tool == 3  % RESIZE
    trackbox = handles.trackbox;
    % setup ghost box
    handles.transform.M.Parent = handles.fig2axes_M;
    handles.transform.M.Matrix = trackbox.tform.Matrix;
    handles.transform.ghost_box.Position = trackbox.rect.Position;
    % find resize anchor position
    resize_handles = handles.transform.resize_handles.Children;
    handles.transform.click_idx = find(resize_handles == hObject);
    % record mouse starting position
    handles.transform.mouse_starting_pos = handles.figure1.CurrentPoint;
    % All ready: flag process as started and set things visible
    handles.transform.in_progress = 2;
    handles.transform.M.Visible = 'on';
    % refresh figure
    guidata(hObject, handles);
    drawnow;
end


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = handles.transform.in_progress;
if process == 0 || ~Trackbox.exists(handles.trackbox)
    return;
end
fig = gcf;
mouse_pos = fig.CurrentPoint;
trackbox = handles.trackbox;
if process == 1  % MOVE
    mouse_pos0 = handles.transform.mouse_starting_pos;
    % translate the ghost box according to mouse movement
    handles.transform.M.Matrix = ...
        makehgtform('translate', [mouse_pos - mouse_pos0, 0]) ...
        * trackbox.tform.Matrix;
elseif process == 2  % RESIZE
    mouse_pos0 = handles.transform.mouse_starting_pos;
    box_rot_angle = trackbox.angle;
    % transform mouse movement to selected box coordinates
    mouse_change = (makehgtform('zrotate', -box_rot_angle) ...
                    * [(mouse_pos - mouse_pos0), 0, 1]')';
    % update ghost box size
    new_pos = resolveResizedRect(trackbox.rect.Position, ...
                                 mouse_change(1:2), ...
                                 handles.transform.click_idx);
    handles.transform.ghost_box.Position = new_pos;
elseif process == 3  % ROTATE
    % update rotation line
    handles.transform.line.XData(3) = mouse_pos(1);
    handles.transform.line.YData(3) = mouse_pos(2);
    % get angle between the rotation lines
    x = handles.transform.line.XData;
    y = handles.transform.line.YData;
    v1 = normalized([x(1) - x(2), y(1) - y(2), 0]);
    v2 = normalized([x(3) - x(2), y(3) - y(2), 0]);
    angle = acos(dot(v1, v2));
    v1_cross_v2 = cross(v1,v2);
    if v1_cross_v2(3) < 0
        angle = -angle;
    end
    % update rotation box around its center
    box_center = trackbox.centroid;
    handles.transform.M.Matrix = ...
        makehgtform('translate', [box_center, 0]) ...
        * makehgtform('zrotate', angle) ...
        * makehgtform('translate', [-box_center, 0]);
elseif process == 4  % CONNECT
    % update connection line
    handles.transform.line.XData(1) = mouse_pos(1);
    handles.transform.line.YData(1) = mouse_pos(2);
    % highlight a candidate rectangle if mouse is on top of it
%     candidates = handles.transform.connection_candidates;
    candidate = hittest(fig);
    if (~isempty(candidate) ...
            && isgraphics(candidate, 'rectangle') ...
            && candidate ~= trackbox.rect)
        if isgraphics(handles.transform.current_candidate, 'rectangle')
            handles.transform.current_candidate.Selected = 'off';
        end
        candidate.Selected = 'on';
        handles.transform.current_candidate = candidate;
    else 
        if isgraphics(handles.transform.current_candidate, 'rectangle')
            handles.transform.current_candidate.Selected = 'off';
        end
        handles.transform.current_candidate = ...
            matlab.graphics.GraphicsPlaceholder;
    end
end
% refresh figure
guidata(hObject, handles);
drawnow;
     

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, ~, handles) %#ok<DEFNU>
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = handles.transform.in_progress;
if process == 0 || ~Trackbox.exists(handles.trackbox)
    return;
end
trackbox = handles.trackbox;
h_transform = handles.transform;
if process == 1  % MOVE
    % apply rotation on the original box
    trackbox.tform.Matrix = h_transform.M.Matrix;
%     trackbox.updateConnectionLines();
elseif process == 2  % RESIZE
    % set position to transform matrix of the selected rectangle
    trackbox.tform.Matrix = h_transform.M.Matrix ;
    % set size to selected rectangle
    trackbox.setPosition(h_transform.ghost_box.Position);
    % store the current centroid
    trackbox.updateCentroid();
%     trackbox.updateConnectionLines();
    handles = updateResizeHandlePositions(handles);
elseif process == 3  % ROTATE
    % apply rotation on the original box
    trackbox.tform.Matrix = trackbox.tform.Matrix * h_transform.M.Matrix;
    % store angle of the current rotation
    trackbox.updateAngle();
%     trackbox.updateConnectionLines();
elseif process == 4  % CONNECT
    % connect the nodes
    rect_to_connect = handles.transform.current_candidate;
    if isgraphics(rect_to_connect, 'rectangle')
        box_to_connect = rect_to_connect.UserData.h_trackbox;
        %setSelectedRect(rect_to_connect, handles);
        %save the parent-to-child connection in da_graph
        handles.tracker.da_graph.setEdge(trackbox.getId(), box_to_connect.getId(), box_to_connect.getId());
    end
end
% end process and hide markups
h_transform.in_progress = 0;
h_transform.M.Visible = 'off';
h_transform.line.Visible = 'off';
guidata(hObject, handles);
          


% --- Interpret the
function [rect_pos] = resolveResizedRect(orig_pos, mouse_change, click_idx)
% Resolves Position parameter of the resized box
rect_pos = orig_pos;
if click_idx == 1
    rect_pos = orig_pos + [mouse_change, -mouse_change];
elseif click_idx == 2
    rect_pos(2) = orig_pos(2) + mouse_change(2);
    rect_pos(4) = orig_pos(4) - mouse_change(2);
elseif click_idx == 3
    rect_pos(2) = orig_pos(2) + mouse_change(2);
    rect_pos(3) = orig_pos(3) + mouse_change(1);
    rect_pos(4) = orig_pos(4) - mouse_change(2);
elseif click_idx == 4
    rect_pos(1) = orig_pos(1) + mouse_change(1);
    rect_pos(3) = orig_pos(3) - mouse_change(1);
elseif click_idx == 5
    rect_pos(3) = orig_pos(3) + mouse_change(1);
elseif click_idx == 6
    rect_pos(1) = orig_pos(1) + mouse_change(1);
    rect_pos(3) = orig_pos(3) - mouse_change(1);
    rect_pos(4) = orig_pos(4) + mouse_change(2);
elseif click_idx == 7
    rect_pos(4) = orig_pos(4) + mouse_change(2);
elseif click_idx == 8
    rect_pos(3:4) = orig_pos(3:4) + mouse_change;
end
rect_pos(3:4) = abs(rect_pos(3:4));


% --- Sets up graphics handles needed for producing rectangles 
function [handles] = setupRectGraphics(handles)

% create figure-to-axes-coordinates transform matrix
handles.fig2axes = eye(4);
axes_offset = plotboxpos(handles.img_axes);
handles.fig2axes(1:2,4) = -axes_offset(1:2);
handles.fig2axes_M = hgtransform('Parent', handles.img_axes, ...
                                 'Matrix', handles.fig2axes);

                             
% create transformation graphics
handles.transform.M = hgtransform('Parent', handles.fig2axes_M, ...
                                 'Visible', 'off');
handles.transform.M.UserData.angle = 0;
handles.transform.ghost_box = rectangle('Parent', handles.transform.M, ...
                                       'EdgeColor', [0.5, 0.5, 0.5], ...
                                       'LineStyle', '--', ...
                                       'Tag', 'ghost');
handles.transform.line = plot([0,0,0], ...
                             [0,0,0], ...
                             'Color', [0.68, 0.21, 0.12], ...
                             'Parent', handles.fig2axes_M, ...
                             'Visible', 'off');
handles.transform.resize_handles = hggroup('Parent', handles.img_axes, ...
                                           'Visible', 'off');
for i = 1 : 8
    % create resize handles
    rectangle('Parent', handles.transform.resize_handles, ...
              'Position', [0, 0, 0, i], ...
              'ButtonDownFcn', @(hObject,eventdata)tracker('resize_handle_ButtonDownFcn',hObject,eventdata,guidata(hObject)), ...
              'Tag', 'resize');
end
% enum with the following values:
% NO_PROGRESS = 0,
% MOVE        = 1,
% RESIZE      = 2,
% ROTATE      = 3,
% CONNECT     = 4,
handles.transform.in_progress = 0;


% --- Move resize handles to their correct positions
function [handles] = updateResizeHandlePositions(handles)
trackbox = handles.trackbox;
p_idx = [0 : 3, 5 : 8];
rect_size = trackbox.rect.Position(3:4);
resize_handle_offset = 3;
resize_handle_size = 2 * resize_handle_offset;
% set resize handles
for i = 1 : 8
    handles.transform.resize_handles.Children(i).Position = ...
        [rect_size(1) * mod(p_idx(i), 3) / 2 - resize_handle_offset, ...
         rect_size(2) * floor(p_idx(i) / 3) / 2 - resize_handle_offset, ... 
         resize_handle_size, ...
         resize_handle_size];
end


% --- Create new Trackbox object according to user input
function [handles] = createBox(box_pos, ~, handles)
new_trackbox = Trackbox(box_pos, handles.fig2axes_M);
handles.tracker.da_graph.addNode(new_trackbox.getId());


% --- Set the given rectangle as selected
function [handles] = setSelectedRect(rect, handles)
if (Trackbox.exists(handles.trackbox) && handles.trackbox.rect ~= rect)
    % unselect previous selection
    handles.trackbox.select('off');
end
% select current box
handles.trackbox = rect.UserData.h_trackbox;
trackbox = handles.trackbox;
% set selection appearance
if handles.tool_selection_menu.Value == 3  % RESIZE
    handles.transform.resize_handles.Parent = trackbox.tform;
    % set handles to their correct positions
    handles = updateResizeHandlePositions(handles);
    % replace selection markups with resize handles
    trackbox.select('off');
    handles.transform.resize_handles.Visible = 'on';
else
    trackbox.select('on');
    handles.transform.resize_handles.Visible = 'off';
end
% Update box information
% (currently the only information is the measurement checkbox)
handles.measurement_node_checkbox.Value = trackbox.is_measurement_node;


% --- Unselect the selected rectangle
function [handles] = unselectRect(handles)
if Trackbox.exists(handles.trackbox)
    % unselect rectangle
    handles.trackbox.select('off');
    handles.transform.resize_handles.Visible = 'off';
    handles.trackbox = Trackbox();
end


% --- Normalize vector
function n_vec = normalized(vec)
n_vec = vec / norm(vec);


% --- Executes on button press in draw_polygon.
function draw_polygon_Callback(hObject, eventdata, handles)
% hObject    handle to draw_polygon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[BW, xi, yi] = roipoly;
