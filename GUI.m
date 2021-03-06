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

% Last Modified by GUIDE v2.5 12-Jan-2015 02:13:28

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

% AR
handles.ar_ordre = 22;

% Capon
handles.capon_pas = 100;

% Spectrogramme
handles.nb_colonne = 400;
handles.nb_ligne = 200;
handles.image = zeros(handles.nb_ligne, handles.nb_colonne);
handles.position = 1;
handles.fentre1 = 0; % en nb de points
handles.recouvrement = 0.5;

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
axes(handles.axes_ar);
cla(handles.axes_ar);

if(~isempty(handles.signal))
    poles = AR_detection(handles.signal, handles.ar_ordre);
else
    poles = [];
end

module = abs(poles);
freq = phase(poles)*handles.signal_fech/2/pi;

module = [module; module];
freq = [freq; -freq];

stem(freq,module,'MarkerFaceColor','red');
xlim([-handles.signal_fech/2 handles.signal_fech/2]);
title('P�les d�tect�s');
xlabel('Frequence (Hz)');
ylabel('Module');
end

function update_capon(handles)
axes(handles.axes_capon);
cla(handles.axes_capon);

if(length(handles.signal) < 8000)
    if(~isempty(handles.signal))
        puissances = Capon_process(handles.signal, handles.signal_fech, handles.capon_pas);
    else
        puissances = [];
    end

    N = length(puissances);
    plot(((0:(N-1))/N-0.5)*handles.signal_fech, puissances);
    title('Puissances');
    xlabel('Frequence (Hz)');
    ylabel('Amplitude');
    xlim([-handles.signal_fech/2 handles.signal_fech/2]);
else
    plot([]);
    title('Trop de points');
    xlabel('Trop de points');
end
end
function open_signal_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to open_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, filepath] = uigetfile('*.mat');
set(handles.panel_gen, 'Visible', 'off');
set(handles.panel_signal, 'Visible', 'on');
if ~isequal(filename, 0)
    signal_struct = load([filepath filename]);
    
    nom = strsplit(filename, '.');
    
    raw = signal_struct.(nom{1});
    fech = 8000;
    len = length(raw);
    
    handles.signal_raw = raw;
    handles.signal_fech = fech;
    
    handles.fenetre1 = fix(length(raw)/handles.nb_colonne);
    handles.position = 1;
    axes(handles.axes_spectrogramme);
    cla(handles.axes_spectrogramme);
    
    handles.offset = 0;
    handles.N_window = min(fech * 5, len);
    
    handles.signal = raw((1+handles.offset):(handles.offset+handles.N_window));

    guidata(hObject, handles);
    
    update_signal(handles);
    update_fft(handles);
    update_ar(handles);
    update_capon(handles);
    
    set(handles.panel_signal,'Title',sprintf('Visualisation temporelle du signal - %s', filename));
    guidata(hObject, handles);
end
end

function spectrogramme(handles)
    axes(handles.axes_spectrogramme);
    %cla(handles.axes_spectrogramme);
    N=length(handles.signal_raw);
    if(~isempty(handles.signal_raw))
        while(get(findobj('Tag', 'checkbox_activer'),'Value') == 1 && (handles.position) < N)
            d = max([1 handles.position-handles.fenetre1]);
            f = min([N handles.position+handles.fenetre1]);
            signal = handles.signal_raw(d:f);
            f1 = abs(fft(signal, 2*handles.nb_ligne));
            f2 = f1(1:handles.nb_ligne);
            f3 = f2/max(f2);
            
            handles.image(:,fix(handles.position/handles.fenetre1)+1) = flipud(f3);
            
            imshow(handles.image), colormap('Jet');
            handles.position = handles.position + handles.fenetre1;
            pause(0.001);
        end
        %fprintf(1, 'sortie\n');
        set(handles.checkbox_activer, 'Value', 0);
        guidata(findobj('Tag', 'figure1'), handles);
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
update_ar(handles);
update_capon(handles);
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
    set(handles.slider_offset, 'Value', 0);
    handles.offset = 0;
end
if(~isempty(handles.signal_raw ~= 0))
    t = handles.offset+handles.N_window;
    if(t > length(handles.signal_raw))
        handles.offset = handles.offset - (t - length(handles.signal_raw));
    end
    handles.signal = handles.signal_raw((1+handles.offset):(handles.offset+handles.N_window));
end

if((length(handles.signal_raw) - handles.N_window) ~= 0)
    set(handles.slider_offset, 'Value', handles.offset / (length(handles.signal_raw) - handles.N_window));
end

cla(handles.axes_signal, 'reset');
guidata(hObject, handles);
update_signal(handles);
update_fft(handles);
update_ar(handles);
update_capon(handles);
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
reset_axes_signal(hObject, handles, 5);
end

function reset_axes_signal(hObject, handles, time)
cla(handles.axes_signal, 'reset');

handles.offset = 0;
set(handles.slider_offset, 'Value', 0);

set(handles.edit_temps, 'String', time);
handles.N_window = min(handles.signal_fech * time, length(handles.signal_raw));
handles.signal = handles.signal_raw((1+handles.offset):(handles.offset+handles.N_window));

update_signal(handles);
update_fft(handles);
update_ar(handles);
update_capon(handles);
guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function axes_signal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_signal
end

% --- Executes during object creation, after setting all properties.
function axes_fft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_fft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes_fft
end

% --- Executes during object creation, after setting all properties.
function panel_signal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panel_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end

% --------------------------------------------------------------------
function gen_sig_button_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to gen_sig_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panel_gen, 'Visible', 'on');
set(handles.panel_signal, 'Visible', 'off');
end

function edit_duree_Callback(hObject, eventdata, handles)
% hObject    handle to edit_duree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_duree as text
%        str2double(get(hObject,'String')) returns contents of edit_duree as a double
end

% --- Executes during object creation, after setting all properties.
function edit_duree_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_duree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit_fe_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fe as text
%        str2double(get(hObject,'String')) returns contents of edit_fe as a double
end

% --- Executes during object creation, after setting all properties.
function edit_fe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit_f1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_f1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_f1 as text
%        str2double(get(hObject,'String')) returns contents of edit_f1 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_f1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_f1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit_f2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_f2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_f2 as text
%        str2double(get(hObject,'String')) returns contents of edit_f2 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_f2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_f2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in button_gen_sinu.
function button_gen_sinu_Callback(hObject, eventdata, handles)
% hObject    handle to button_gen_sinu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
d = str2double(get(handles.edit_duree,'String'));
fe = str2double(get(handles.edit_fe,'String'));
f1 = str2double(get(handles.edit_f1,'String'));
f2 = str2double(get(handles.edit_f2,'String'));
i = 0:1/fe:d;

signal_raw = cos(2*pi*f1*i) + cos(2*pi*f2*i);
    
handles.signal_raw = signal_raw;
handles.signal_fech = fe;    

set(handles.panel_signal,'Title', 'Visualisation temporelle du signal - Signal sinuso�dal');

set(handles.panel_gen, 'Visible', 'off');
set(handles.panel_signal, 'Visible', 'on');
guidata(hObject, handles);

reset_axes_signal(hObject, handles, min([d 50*1/(max([f1 f2]))]));
end


% --- Executes on button press in button_ar_gen.
function button_ar_gen_Callback(hObject, eventdata, handles)
% hObject    handle to button_ar_gen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
d = str2double(get(handles.edit_ar_duree,'String'));
fe = str2double(get(handles.edit_ar_fe,'String'));
mp1 = str2double(get(handles.edit_mp1,'String'));
mp2 = str2double(get(handles.edit_mp2,'String'));
fp1 = str2double(get(handles.edit_fp1,'String'));
fp2 = str2double(get(handles.edit_fp2,'String'));

poles = zeros(1, 4);

poles(1) = mp1 * exp(1i*2*pi*fp1/fe);
poles(2) = mp1 * exp(-1i*2*pi*fp1/fe);
poles(3) = mp2 * exp(1i*2*pi*fp2/fe);
poles(4) = mp2 * exp(-1i*2*pi*fp2/fe);

signal_raw = AR_gen(poles, d, fe);

handles.signal_raw = signal_raw;
handles.signal_fech = fe;    

guidata(hObject, handles);

set(handles.panel_signal,'Title', 'Visualisation temporelle du signal - Signal sinuso�dal');
set(handles.panel_gen, 'Visible', 'off');
set(handles.panel_signal, 'Visible', 'on');
guidata(hObject, handles);

reset_axes_signal(hObject, handles, d);
end

function edit_ar_fe_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ar_fe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ar_fe as text
%        str2double(get(hObject,'String')) returns contents of edit_ar_fe as a double
end

% --- Executes during object creation, after setting all properties.
function edit_ar_fe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ar_fe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_ar_duree_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ar_duree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ar_duree as text
%        str2double(get(hObject,'String')) returns contents of edit_ar_duree as a double
end

% --- Executes during object creation, after setting all properties.
function edit_ar_duree_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ar_duree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit_mp1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_mp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_mp1 as text
%        str2double(get(hObject,'String')) returns contents of edit_mp1 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_mp1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_mp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_fp1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fp1 as text
%        str2double(get(hObject,'String')) returns contents of edit_fp1 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_fp1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit_mp2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_mp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_mp2 as text
%        str2double(get(hObject,'String')) returns contents of edit_mp2 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_mp2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_mp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit_fp2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fp2 as text
%        str2double(get(hObject,'String')) returns contents of edit_fp2 as a double
end

% --- Executes during object creation, after setting all properties.
function edit_fp2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit_ar_ordre_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ar_ordre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ar_ordre as text
%        str2double(get(hObject,'String')) returns contents of edit_ar_ordre as a double
handles.ar_ordre = str2double(get(hObject,'String'));
guidata(hObject, handles);
update_ar(handles);
end

% --- Executes during object creation, after setting all properties.
function edit_ar_ordre_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ar_ordre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit_capon_pas_Callback(hObject, eventdata, handles)
% hObject    handle to edit_capon_pas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_capon_pas as text
%        str2double(get(hObject,'String')) returns contents of edit_capon_pas as a double
handles.capon_pas = str2double(get(hObject,'String'));
guidata(hObject, handles);
update_capon(handles);
end

% --- Executes during object creation, after setting all properties.
function edit_capon_pas_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_capon_pas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in button_spectrogramme.
function button_spectrogramme_Callback(hObject, eventdata, handles)
% hObject    handle to button_spectrogramme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panel_spectrogramme, 'Visible', 'on');
set(handles.panel_fft, 'Visible', 'off');
set(handles.panel_ar, 'Visible', 'off');
set(handles.panel_capon, 'Visible', 'off');
end

% --- Executes on button press in checkbox_activer.
function checkbox_activer_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_activer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_activer
spectrogramme(handles);
end


% --- Executes on button press in button_retour.
function button_retour_Callback(hObject, eventdata, handles)
% hObject    handle to button_retour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panel_spectrogramme, 'Visible', 'off');
set(handles.panel_fft, 'Visible', 'on');
set(handles.panel_ar, 'Visible', 'on');
set(handles.panel_capon, 'Visible', 'on');
end


% --- Executes on button press in button_reset_spectrogramme.
function button_reset_spectrogramme_Callback(hObject, eventdata, handles)
% hObject    handle to button_reset_spectrogramme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles a
 handles.position = 1;
 axes(handles.axes_spectrogramme);
 cla(handles.axes_spectrogramme);
 handles.image = zeros(handles.nb_ligne, handles.nb_colonne);
 guidata(hObject, handles);
end