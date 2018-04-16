% Oil spill v.Struct
% Lagrangian algorithm to simulate oil spills in the Gulf of Mexico
close all; clear; clc; format compact; clc
%----------------------- Spill timing (yyyy,mm,dd) -----------------------%
spillTiming.startDay_date     = [2007,10,23]; % 2007,10,23
spillTiming.lastSpillDay_date = [2007,11,23]; % 2007,11,23
spillTiming.endSimDay_date    = [2007,12,10]; % 2007,12,10
%---------------------------- Spill location -----------------------------%
spillLocation.Lat      =  18.811389; %  18.811389
spillLocation.Lon      = -92.707222; % -92.707222
spillLocation.Depths   = [  10,   5,   0];
spillLocation.Radius_m = [ 100, 200, 300]; % 2 STD for random initialization of particles
%------------------------- Local Paths filename --------------------------%
Params.LocalPaths = 'local_paths_Usumacinta.m';
%--------------------------- Output directorie ---------------------------%
Params.OutputDir = '/DATA/corridasjulio/OilSpill_vStruct/ResultsRK4_Usu_20p1/';
%----------------------- Runge-Kutta method: 2 | 4 -----------------------%
Params.RungeKutta = 4;
%------------- Velocity Fields Type: 1 (BP) | 2 (Usumacinta) -------------%
Params.velocityFieldsType = 2;
%----------------------------- Model domain ------------------------------%
%Params.domainLimits = [-96, -92, 18.1, 21]; % Larger domain
Params.domainLimits = [-93.2, -92.2, 18.1, 19.6]; % Miriam smalll domain
%------------- Number of particles representing one barrel ---------------%
Params.particlesPerBarrel  = 1000;
%--------------- Turbulent-diffusion parameter per depth -----------------%
Params.TurbDiff_b          = [0.1, 0.2, 0.4];
%------ Wind fraction used to advect particles (only for 0 m depth) ------%
Params.windcontrib         = 0.035;
%--------- Distribution of oil per subsurface depth (> 0 m depth)---------%
Params.subsurfaceFractions = [1/2, 1/2];
%------------Oil components (component proportions per depth) ------------%
Params.components_proportions = [...
  [0.05 0.05 0.05 0.05 0.10 0.20 0.20 0.30];
  [0.05 0.05 0.10 0.10 0.10 0.20 0.20 0.20];
  [0.10 0.30 0.30 0.10 0.05 0.05 0.05 0.05]];
%--------------- Ocean and Wind files (time step in hours) ---------------%
OceanFile.timeStep_hrs = 24;
WindFile.timeStep_hrs  = 1;
%----------------------- Lagrangian time step (h) ------------------------%
LagrTimeStep.InHrs = .5;
%------------------------------ Oil decay --------------------------------%
% Burning
decay.burn                  = 0;
decay.burn_radius_m         = 300000;
% Collection
decay.collect               = 0;
% Evaporation
decay.evaporate             = 0;
% Natural dispersion
decay.surfNatrDispr         = 0;
% Chemical dispersion
decay.surfChemDispr         = 0;
% Exponential degradation
decay.expDegrade            = true;
decay.expDegrade_Percentage = 99.9;
decay.expDegrade_Days       = [1, 4, 7, 10, 13, 16, 19, 22]*.7;
%----------------------- Get daily spill quantities ----------------------%
% 'filename.csv' | '0'. Set DS.csv_file == '0' if you DONOT have a csv file
DS.csv_file = '0';
% Next DS block is required if you DONOT have a csv file (DS.csv_file = 0)
% Indicate mean daily spill quantities (oil barrels)
DS.Net                = 23;
DS.Burned             = 0;
DS.OilyWater          = 0;
DS.SurfaceDispersants = 0;
DS.SubsurfDispersants = 0;
%-------------- Visualization (mapping particles positions) --------------%
% 'on' | 'off'. Set 'on' for visualizing maps as the model runs
vis_maps.visible         = 'on';
vis_maps.visible_step_hr = nan; % nan
% Bathymetry file name. 'BAT_FUS_GLOBAL_PIXEDIT_V4.mat' | 'gebco_1min_-98_18_-78_31.nc'
vis_maps.bathymetry      = 'BATI100_s10_fixLC.mat';
% Visualization Type (2D and/or 3D)
vis_maps.twoDim          = true;
vis_maps.threeDim        = true;
vis_maps.threeDim_angles = [-6, 55];% [0, 90] [-6, 55]
% Visualization region [minLon, maxLon, minLat, maxLat, minDepth, maxDepth]
% vis_maps.boundaries      = [-96, -92, 18.1, 21, -4000, 0]; % Large Dom
vis_maps.boundaries      = [-93.2, -92.2, 18.1, 19.6, -4000, 0]; % Miriam smalll domai
% Isobaths to plot
vis_maps.isobaths        = [-0, -200];
% Colormap to use
vis_maps.cmap            = 'gray'; % e.g.: [1 1 1], 'copper', 'gray', 'jet',...
vis_maps.fontSize        = 16;
vis_maps.markerSize      = 5;
vis_maps.axesPosition    = [2.7,2,13,10];
vis_maps.figPosition     = [2,2,2*vis_maps.axesPosition(1)+vis_maps.axesPosition(3)+2.5,...
  2*vis_maps.axesPosition(2)+vis_maps.axesPosition(4)-.5];
% Create the colors for the oil
vis_maps.colors_SpillLocation = 'g';
vis_maps.colors_InLand        = 'g';
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
saving.MapsVideo_on              = 1;
saving.MapsVideo_quality         = 100; % 0 (worst) --> 100 (best)
saving.MapsVideo_framesPerSecond = 3;
saving.MapsVideo_step_hr         = 6;
% maps_images
saving.MapsImage_on              = 0;
saving.MapsImage_quality         = '-r100'; % Resolution in dpi
saving.MapsImage_step_hr         = 6;
% stat_videos
saving.StatVideo_on              = 0;
saving.StatVideo_quality         = 100; % 0 (worst) --> 100 (best)
saving.StatVideo_framesPerSecond = 3;
saving.StatVideo_step_hr         = 6;
% stat_images
saving.StatImage_on              = 0;
saving.StatImage_quality         = '-r100'; % Resolution in dpi
saving.StatImage_step_hr         = 24;
%---------------------------- Add local paths ----------------------------%
run(Params.LocalPaths);
%-------------------------- Call model routine ---------------------------%
tic
oilSpillModel(spillTiming,spillLocation,Params,OceanFile,WindFile,...
  LagrTimeStep,decay,DS,vis_maps,vis_stat,saving);
toc
