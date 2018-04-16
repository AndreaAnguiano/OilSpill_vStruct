function varargout = graphical_interface(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @graphical_interface_OpeningFcn, ...
                   'gui_OutputFcn',  @graphical_interface_OutputFcn, ...
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
% --- Executes just before graphical_interface is made visible.
function graphical_interface_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% --- Outputs from this function are returned to the command line.
function varargout = graphical_interface_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
function Start_Callback(hObject, eventdata, handles)
%------------------------ Read input parameters --------------------------%
%----------------------- Spill timing (yyyy,mm,dd) -----------------------%
spillTiming.startDay_date     = str2num(get(handles.initialSpillDay,'string'));
spillTiming.lastSpillDay_date = str2num(get(handles.finalSpillDay,'string'));
spillTiming.endSimDay_date    = str2num(get(handles.finalSimDay,'string'));
%---------------------------- Spill location -----------------------------%
sitio_derrame = str2num(get(handles.spill_location,'string'));
spillLocation.Lat      = sitio_derrame(1);
spillLocation.Lon      = sitio_derrame(2);
spillLocation.Depths   = str2num(get(handles.depths,'string'));
spillLocation.Radius_m = str2num(get(handles.spil_radius,'string'));
%------------------------- Local Paths filename --------------------------%
Params.LocalPaths = get(handles.input_folder,'string');
%--------------------------- Output directorie ---------------------------%
Params.OutputDir = get(handles.output_folder,'string');
%----------------------- Runge-Kutta method: 2 | 4 -----------------------%
RK_VF_type = str2num(get(handles.RK_VF_type,'string'));
Params.RungeKutta = RK_VF_type(1);
%------------- Velocity Fields Type: 1 (BP) | 2 (Usumacinta) -------------%
Params.velocityFieldsType = RK_VF_type(2);
%----------------------------- Model domain ------------------------------%
model_domain = str2num(get(handles.domain,'string'));
Params.domainLimits = model_domain(1:4);
%------------- Number of particles representing one barrel ---------------%
Params.particlesPerBarrel  = str2double(get(handles.barrels_per_particle,'string'));
%--------------- Turbulent-diffusion parameter per depth -----------------%
Params.TurbDiff_b          = str2num(get(handles.turb_diff,'string'));
%------ Wind fraction used to advect particles (only for 0 m depth) ------%
Params.windcontrib         = str2double(get(handles.wind_contribution,'string'));
%--------- Distribution of oil per subsurface depth (> 0 m depth)---------%
%---------- Assume the same subsurface oil amount at each layer ----------%
Params.subsurfaceFractions = zeros(1,sum(spillLocation.Depths>0))+1/sum(spillLocation.Depths>0);
%------------Oil components (component proportions per depth) ------------%
%----------------- Assume the same proportions per depth ------------------%
classes_prop = str2num(get(handles.classes_prop,'string'));
Params.components_proportions = repmat(classes_prop,[length(spillLocation.Depths),1]);
%--------------- Ocean and Wind files (time step in hours) ---------------%
time_steps = str2num(get(handles.TimeStep,'string'));
OceanFile.timeStep_hrs = time_steps(2);
WindFile.timeStep_hrs  = time_steps(3);
%----------------------- Lagrangian time step (h) ------------------------%
LagrTimeStep.InHrs = time_steps(1);
%------------------------------ Oil decay --------------------------------%
% Burning
decay.burn                  = get(handles.burning,'value');
decay.burn_radius_m         = str2double(get(handles.burning_radius,'string'));
% Collection
decay.collect               = get(handles.collection,'value');
% Evaporation
decay.evaporate             = get(handles.evaporation,'value');
% Natural dispersion
decay.surfNatrDispr         = get(handles.natural,'value');
% Chemical dispersion
decay.surfChemDispr         = get(handles.chemical,'value');
% Exponential degradation
decay.expDegrade            = get(handles.exp_degradation,'value');
decay.expDegrade_Percentage = str2double(get(handles.percentage_decay,'string'));
decay.expDegrade_Days       = str2num(get(handles.degradation_times,'string'));
%----------------------- Get daily spill quantities ----------------------%
% 'filename.csv' | '0'. Set DS.csv_file == '0' if you DONOT have a csv file
DS.csv_file = get(handles.csv_file,'string');
% Next DS block is required if you DONOT have a csv file (DS.csv_file = 0)
% Indicate mean daily spill quantities (oil barrels)
DS.Net                = str2double(get(handles.barrels_spilled,'string'));
DS.Burned             = str2double(get(handles.barrels_burned,'string'));
DS.OilyWater          = str2double(get(handles.barrels_collected,'string'));
chem_dispersants = str2num(get(handles.chem_dispersants,'string'));
DS.SurfaceDispersants = chem_dispersants(1);
DS.SubsurfDispersants = chem_dispersants(2);
%-------------- Visualization (mapping particles positions) --------------%
% 'on' | 'off'. Set 'on' for visualizing maps as the model runs
vis_maps.visible         = 'on';
vis_maps.visible_step_hr = nan; % nan
% Bathymetry file name. 'BAT_FUS_GLOBAL_PIXEDIT_V4.mat' | 'gebco_1min_-98_18_-78_31.nc'
vis_maps.bathymetry      = get(handles.bathymetry,'string');
% Visualization Type (2D and/or 3D)
vis_maps.twoDim          = true;
vis_maps.threeDim        = true;
vis_maps.threeDim_angles = [-6, 55];% [0, 90] [-6, 55]
% Visualization region [minLon, maxLon, minLat, maxLat, minDepth, maxDepth]
vis_maps.boundaries      = model_domain;
% Isobaths to plot
vis_maps.isobaths        = [-0, -200];
% Colormap to use
vis_maps.cmap            = 'copper'; % e.g.: [1 1 1], 'copper', 'gray', 'jet',...
vis_maps.fontSize        = 16;
vis_maps.markerSize      = 5;
vis_maps.axesPosition    = [2,2,10,8];
vis_maps.figPosition     = [2,2,2*vis_maps.axesPosition(1)+vis_maps.axesPosition(3)+2.5,...
  2*vis_maps.axesPosition(2)+vis_maps.axesPosition(4)-.5];
% Create the colors for the oil
vis_maps.colors_SpillLocation = 'w';
vis_maps.colors_InLand        = 'w';
vis_maps.colors_ByDepth       = ['g';'r';'b';'c';'y'];
vis_maps.colors_ByComponent   = {...
  'r';...                          % red
  [0.9290    0.6940    0.1250];... % orange
  'y';...                          % yellow
  [0.4660    0.7740    0.1880];... % green
  'c';...                          % cyan
  'b';...                          % blue
  'm';...                          % magenta
  [0.4940    0.1840    0.5560]};   % purple
%------------------ Visualization (plotting statistics) ------------------%
% 'on' | 'off'. Set 'on' for visualizing statistics as the model runs
vis_stat.visible         = 'on'; % 'on' | 'off'
vis_stat.visible_step_hr = nan;
vis_stat.axesLimits      = 'auto';
vis_stat.fontSize        = 16;
vis_stat.markerSize      = 5;
vis_stat.lineColors      = {...
  [0.0357    0.8491    0.9340];... % cyan
  [0.1419    0.4218    0.9157];... % blue
  [0.6160    0.4733    0.3517];... % brown
  [0.7149    0.7173    0.7187];... % gray
  [1.0000    0.0000    0.0000];... % red
  [0.0000    0.0000    0.0000];... % black
  [0.5499    0.1450    0.8530];... % purple
  [0.5407    0.8699    0.2648];... % green
  [0.9649    0.1576    0.9706];... % magenta
  [0.8611    0.4849    0.3935]};   % orange
vis_stat.axesPosition    = [2,2,10,8];
vis_stat.figPosition     = [2,2,2*vis_stat.axesPosition(1)+vis_stat.axesPosition(3)+4,...
  2*vis_stat.axesPosition(2)+vis_stat.axesPosition(4)-.5];
%---------------------------- Saving options -----------------------------%
% Data
saving.Data_on                   = true;
saving.Data_step_hr              = time_steps(4);
% maps_videos
saving.MapsVideo_on              = true;
saving.MapsVideo_quality         = 100; % 0 (worst) --> 100 (best)
saving.MapsVideo_framesPerSecond = 3;
saving.MapsVideo_step_hr         = time_steps(4);
% maps_images
saving.MapsImage_on              = false;
saving.MapsImage_quality         = '-r100'; % Resolution in dpi
saving.MapsImage_step_hr         = time_steps(4);
% stat_videos
saving.StatVideo_on              = true;
saving.StatVideo_quality         = 100; % 0 (worst) --> 100 (best)
saving.StatVideo_framesPerSecond = 3;
saving.StatVideo_step_hr         = time_steps(4);
% stat_images
saving.StatImage_on              = false;
saving.StatImage_quality         = '-r100'; % Resolution in dpi
saving.StatImage_step_hr         = time_steps(4);
%---------------------------- Add local paths ----------------------------%
run(Params.LocalPaths);
%------------------------ Call main program ------------------------------%
oilSpillModel(spillTiming,spillLocation,Params,OceanFile,WindFile,...
  LagrTimeStep,decay,DS,vis_maps,vis_stat,saving);
%-------------------------------------------------------------------------%
