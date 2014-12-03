function varargout = GUI(varargin)
%GUI M-file for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('Property','Value',...) creates a new GUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to GUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      GUI('CALLBACK') and GUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in GUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 03-Dec-2014 23:47:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for GUI
handles.output = hObject;

% Initialisation of some variables
handles.signal_raw = [];
handles.signal = [];
handles.signal_fech = 0;
handles.offset = 0;
handles.N_window = 1440;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function update_signal(handles)
axes(handles.axes_signal);
N = length(handles.signal); % N = seconds * Fs
cla(handles.axes_signal);
of = handles.offset;

plot((of:(of+N-1))/handles.signal_fech, handles.signal);
hold on;
xlabel('Time (s)'); ylabel('Amplitude');
title('Representation temporelle du signal');
if(N > 1)
    xlim([(of/handles.signal_fech) ((of+N-1)/handles.signal_fech)]);
end
guidata(findobj('Tag', 'figure1'), handles);
end

function update_fft(handles)
axes(handles.axes_fft);
cla(handles.axes_fft);

if(~isempty(handles.signal))
    dsp_signal = abs(fft(handles.signal)).^2;
else
    dsp_signal = [];
end
N = length(dsp_signal);
plot(((0:(N-1))/N-0.5)*handles.signal_fech, fftshift(dsp_signal));
title('Spectre de puissance du signal');
xlabel('Frequence (Hz)');
ylabel('Amplitude');
xlim([-handles.signal_fech/2 handles.signal_fech/2]);
end

function update_ar(handles)
end

function update_capon(handles) 
end

function open_signal_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to open_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, filepath] = uigetfile('*.mat');
if ~isequal(filename, 0)
    signal_struct = load([filepath filename]);
   
    raw = signal_struct.ecg;
    fech = signal_struct.Fs;
    len = length(raw);
    
    handles.signal_raw = raw;
    handles.signal_fech = fech;
    
    handles.offset = 0;
    handles.N_window = min(fech * 5, len);
    
    handles.signal = signal_struct.ecg((1+handles.offset):(handles.offset+handles.N_window));

    guidata(hObject, handles);
    
    update_signal(handles);
    update_fft(handles);
    
    set(handles.panel_signal,'Title',sprintf('Visualisation temporelle du signal - %s', filename));
end
end


% --- Executes on slider movement.
function slider_offset_Callback(hObject, eventdata, handles)
% hObject    handle to slider_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.offset = floor(get(hObject, 'Value') * (length(handles.signal_raw)-handles.N_window));
if(~isempty(handles.signal_raw))
    handles.signal = handles.signal_raw((1+handles.offset):(handles.N_window+handles.offset));
end
guidata(hObject, handles);
update_signal(handles);
update_fft(handles);
end

% --- Executes during object creation, after setting all properties.
function slider_offset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

function edit_temps_Callback(hObject, eventdata, handles)
% hObject    handle to edit_temps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_temps as text
%        str2double(get(hObject,'String')) returns contents of edit_temps as a double

handles.N_window = fix(str2double(get(hObject,'String')) * handles.signal_fech);
if(handles.N_window == 0)
	handles.N_window = 10;
elseif(handles.N_window > length(handles.signal_raw))
    handles.N_window = length(handles.signal_raw);
    set(handles.edit_temps, 'String', sprintf('%s', handles.N_window));
end
if(~isempty(handles.signal_raw ~= 0))
    t = handles.offset+handles.N_window;
    if(t > length(handles.signal_raw))
        handles.offset = handles.offset - (t - length(handles.signal_raw));
    end
    handles.signal = handles.signal_raw((1+handles.offset):(handles.offset+handles.N_window));
end

set(handles.slider_offset, 'Value', handles.offset / (length(handles.signal_raw) - handles.N_window));

cla(handles.axes_signal, 'reset');
guidata(hObject, handles);
update_signal(handles);
update_fft(handles);
end

% --- Executes during object creation, after setting all properties.
function edit_temps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_temps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in button_reset.
function button_reset_Callback(hObject, eventdata, handles)
% hObject    handle to button_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla(handles.axes_signal, 'reset');
update_signal(handles);
update_fft(handles);
end
