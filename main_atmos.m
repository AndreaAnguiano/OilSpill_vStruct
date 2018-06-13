% Oil spill v.Struct
% Lagrangian algorithm to simulate oil spills in the Gulf of Mexico
close all; clear; clc; format compact; clc

%----------------------- Spill timing (yyyy,mm,dd) -----------------------%
spillTiming.startDay_date     = [2010,04,22]; % [2010,04,22]
spillTiming.lastSpillDay_date = [2010,07,24]; % [2010,07,14]
spillTiming.endSimDay_date    = [2010,04,30]; % [2010,07,30]

%---------------------------- Spill location -----------------------------%
spillLocation.Lat      =  28.738; %  28.738
spillLocation.Lon      = -88.366; % -88.366
spillLocation.Heights   = [ 1500, 1000, 500, 100, 10];
spillLocation.Radius_m = [ 250, 500, 1000]; % 2 STD for random initialization of particles

%------------------------- Local Paths filename --------------------------%
Params.LocalPaths = 'local_paths_atm.m';

%--------------------------- Output directorie ---------------------------%
Params.OutputDir = '/home/andrea/matlabcode/outputsAtm/';

%----------------------- Runge-Kutta method: 2 | 4 -----------------------%
Params.RungeKutta = 4;

%------------- Velocity Fields Type: 1 (BP) | 2 (Usumacinta)| 3 (Atmosphere) -------------%
Params.velocityFieldsType = 3;

%----------------------------- Model domain ------------------------------%
Params.domainLimits = [-92,-80, 25, 31]; % [-88.6, -88.2, 28.71, 28.765]

%------------- Number of particles representing one barrel ---------------%
Params.particlesPerBarrel  = 1/2;

%--------------- Turbulent-diffusion parameter per height -----------------%
Params.TurbDiff_b          = [0.1, 0.1, 0.1, 0.1, 0.1];

%------------------atmospheric model -------------------------------------%
Params.atmos = 1

%----------- Wind files (time step in hours) -----------------------------%
WindFile.timeStep_hrs  = 3;

%----------------------- Lagrangian time step (h) ------------------------%
LagrTimeStep.InHrs = 1;
if visualization 
    %-------------- Visualization (mapping particles positions) --------------%
    % 'on' | 'off'. Set 'on' for visualizing maps as the model runs
    vis_maps.visible         = 'off';
    vis_maps.visible_step_hr = nan; % nan
    % Bathymetry file name. 'BAT_FUS_GLOBAL_PIXEDIT_V4.mat' | 'gebco_1min_-98_18_-78_31.nc'
    vis_maps.bathymetry      = 'BATI100_s10_fixLC.mat';
    % Visualization Type (2D and/or 3D)
    vis_maps.twoDim          = true;
    vis_maps.threeDim        = true;
    vis_maps.threeDim_angles = [-6, 55];% [0, 90] [-6, 55]
    % Visualization region [minLon, maxLon, minLat, maxLat, minDepth, maxDepth]
    vis_maps.boundaries      = [-92, -80, 25, 31, -2500, 0];
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
    %------------------ Visualization (plotting statistics) ------------------%
    % 'on' | 'off'. Set 'on' for visualizing statistics as the model runs
    vis_stat.visible         = 'off'; % 'on' | 'off'
    vis_stat.visible_step_hr = nan;
    vis_stat.axesLimits      = 'auto'; % 'auto' | [xmin xmax ymin ymax]
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
    saving.Data_on                   = 0;
    saving.Data_step_hr              = 24;
    % maps_videos
    saving.MapsVideo_on              = 0;
    saving.MapsVideo_quality         = 100; % 0 (worst) --> 100 (best)
    saving.MapsVideo_framesPerSecond = 3;
    saving.MapsVideo_step_hr         = 24;
    % maps_images
    saving.MapsImage_on              = 0;
    saving.MapsImage_quality         = '-r100'; % Resolution in dpi
    saving.MapsImage_step_hr         = 24;
    % stat_videos
    saving.StatVideo_on              = 0;
    saving.StatVideo_quality         = 100; % 0 (worst) --> 100 (best)
    saving.StatVideo_framesPerSecond = 3;
    saving.StatVideo_step_hr         = 24;
    % stat_images
    saving.StatImage_on              = 0;
    saving.StatImage_quality         = '-r100'; % Resolution in dpi
    saving.StatImage_step_hr         = 24;

 
%---------------------------- Add local paths ----------------------------%
run(Params.LocalPaths);
%-------------------------- Call model routine ---------------------------%
tic
oilSpillModel_atm(spillTiming,spillLocation,Params,WindFile,...
  LagrTimeStep);
toc
