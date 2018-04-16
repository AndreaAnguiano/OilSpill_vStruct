%----------------------------- OilSpillModel -----------------------------%
function oilSpillModel(spillTiming,spillLocation,Params,OceanFile,WindFile,...
  LagrTimeStep,decay,DS,vis_maps,vis_stat,saving)
%------------------------- Create output folders -------------------------%
outputFolder = mkOutputDir(Params,saving);
%-------------------- Verify the Lagrangian Time Step --------------------%
LagrTimeStep.InHrs = correct_LagrTimeStepHrs(LagrTimeStep.InHrs,...
                       OceanFile.timeStep_hrs,WindFile.timeStep_hrs);
%----------------- Save main configuration in text file ------------------%
if ~isempty(outputFolder)
  diary([outputFolder.Main,'main_config.txt'])
  my_variables = who;
  for my_variable = 1:numel(my_variables)
    eval(my_variables{my_variable})
  end
  diary off
end
%---------------------- Get daily spill quantities -----------------------%
DailySpill = dailyOilParticles(Params.particlesPerBarrel,DS,spillTiming);
% Distances are computed considering a mean Earth radius = 6371000 m (Gill)
Dcomp.meanEarthRadius = 6371000;
Dcomp.cst = 180/(Dcomp.meanEarthRadius*pi);
%----------------------------- Spill timing ------------------------------%
spillTiming.startDay_serial     = datenum(spillTiming.startDay_date);
spillTiming.lastSpillDay_serial = datenum(spillTiming.lastSpillDay_date);
spillTiming.endSimDay_serial    = datenum(spillTiming.endSimDay_date);
spillTiming.simulationDays      = 1 + spillTiming.endSimDay_serial - spillTiming.startDay_serial;
spillTiming.spillDays           = 1 + spillTiming.lastSpillDay_serial - spillTiming.startDay_serial;
%---------------------------- Spill location -----------------------------%
spillLocation.n_Depths      = numel(spillLocation.Depths);
spillLocation.Radius_degLat = mtr2deg(spillLocation.Radius_m, spillLocation.Lat, 'lat_deg', Dcomp);
spillLocation.Radius_degLon = mtr2deg(spillLocation.Radius_m, spillLocation.Lat, 'lon_deg', Dcomp);
%------------------------- Lagrangian time step --------------------------%
LagrTimeStep.InSec       = LagrTimeStep.InHrs*3600;
LagrTimeStep.InSec_half  = LagrTimeStep.InSec/2;
LagrTimeStep.InHrs_half  = LagrTimeStep.InHrs/2;
LagrTimeStep.InDays      = LagrTimeStep.InHrs/24;
LagrTimeStep.PerDay      = 24/LagrTimeStep.InHrs;
LagrTimeStep.TOTAL       = LagrTimeStep.PerDay*spillTiming.simulationDays;
LagrTimeStep.BTW_oceanTS = LagrTimeStep.InHrs/OceanFile.timeStep_hrs;
LagrTimeStep.BTW_windsTS = LagrTimeStep.InHrs/WindFile.timeStep_hrs;
%-------------------------------- Params ---------------------------------%
Params.TurbDiff_a        = Params.TurbDiff_b./sqrt(LagrTimeStep.InHrs);
Params.components_number = size(Params.components_proportions,2);
%------------------------------ Oil decay --------------------------------%
decay_true = decay.expDegrade || decay.evaporate || decay.collect ||...
  decay.burn || decay.surfNatrDispr || decay.surfChemDispr;
% Burning
decay.burn_radiusDegLat  = mtr2deg(decay.burn_radius_m,spillLocation.Lat,'lat_deg',Dcomp);
decay.burn_radiusDegLon  = mtr2deg(decay.burn_radius_m,spillLocation.Lat,'lon_deg',Dcomp);
% Exponential degradation
[decay.expDegrade_thresholds,~] = ...
  threshold_expDegr(decay.expDegrade_Percentage,decay.expDegrade_Days,LagrTimeStep.InHrs);
%----------------------------- Visualization -----------------------------%
vis_maps.visible_step_ts = vis_maps.visible_step_hr/LagrTimeStep.InHrs;
vis_stat.visible_step_ts = vis_stat.visible_step_hr/LagrTimeStep.InHrs;
if strcmp(vis_stat.axesLimits,'auto')
  vis_stat.axesLimits = [0,spillTiming.simulationDays,1,sum(DailySpill.Net)/Params.particlesPerBarrel];
end
%---------------------------- Saving options -----------------------------%
saving.Data_step_ts = saving.Data_step_hr/LagrTimeStep.InHrs;
saving.MapsVideo_step_ts = saving.MapsVideo_step_hr/LagrTimeStep.InHrs;
saving.MapsImage_step_ts = saving.MapsImage_step_hr/LagrTimeStep.InHrs;
saving.StatVideo_step_ts = saving.StatVideo_step_hr/LagrTimeStep.InHrs;
saving.StatImage_step_ts = saving.StatImage_step_hr/LagrTimeStep.InHrs;
%----------- Initializing auxiliar "first time" input arguments ----------%
% Used by releaseParticles
Particles  = [];
PartsPerTS = [];
last_ID    = 0;
% Used by map_particles
if saving.MapsVideo_on
  step_mapVideo = saving.MapsVideo_step_ts;
else
  step_mapVideo = nan;
end
if saving.MapsImage_on
  step_mapImage = saving.MapsImage_step_ts;
else
  step_mapImage = nan;
end
if strcmp(vis_maps.visible,'on')
  step_mapVisib = vis_maps.visible_step_ts;
else
  step_mapVisib = nan;
end
step_map      = [step_mapVideo;step_mapImage;step_mapVisib];
Map_fig3D     = [];
Map_fig2D     = [];
vMap3D        = [];
vMap2D        = VideoWriter('X');
ensemble_grid = [];
% Used by plotStats
if saving.StatVideo_on
  step_staVideo = saving.StatVideo_step_ts;
else
  step_staVideo = nan;
end
if saving.StatImage_on
  step_staImage = saving.StatImage_step_ts;
else
  step_staImage = nan;
end
if strcmp(vis_stat.visible,'on')
  step_staVisib = vis_stat.visible_step_ts;
else
  step_staVisib = nan;
end
step_sta   = [step_staVideo;step_staImage;step_staVisib];
stat_count = 0;
Stat       = [];
vStat      = [];
Stat_fig   = [];
%-------------------------------------------------------------------------%
% Cicle for days
for SerialDay = spillTiming.startDay_serial:spillTiming.endSimDay_serial
  % Transform the SerialDay into a strig date
  day_str = datestr(SerialDay,'yyyy-mm-dd');
  disp([day_str,' ...'])
  day_Idx = find(DailySpill.SerialDates == SerialDay);
  day_abs = SerialDay - (spillTiming.startDay_serial-1);
  % Cicle for Lagrangian time step
  for ts = 1:LagrTimeStep.PerDay
    first_time = SerialDay == spillTiming.startDay_serial && ts == 1;
    final_time = SerialDay == spillTiming.endSimDay_serial && ts == LagrTimeStep.PerDay;
    %----------------- Get the current string date-hour ------------------%
    hour_str = num2str((ts-1)*LagrTimeStep.InHrs);
    if numel(hour_str) == 1
      hour_str = strcat('0',hour_str);
    end
    dateHour_str = [day_str,' h ',hour_str];
    %----------------------- Release new particles -----------------------%
    if SerialDay <= spillTiming.lastSpillDay_serial && DailySpill.Net(day_Idx) > 0
      [last_ID,Particles,PartsPerTS] =...
        releaseParticles(day_abs,ts,spillTiming,spillLocation,DailySpill,first_time,...
        PartsPerTS,Particles,last_ID,Params,LagrTimeStep);
    end
    %---------------------- Map particles position -----------------------%
    if any(step_map) && (ismember(0,rem(ts,step_map)) || first_time || final_time)
      [vMap3D,vMap2D,Map_fig3D,Map_fig2D,ensemble_grid] = map_particles(outputFolder,...
        ts,first_time,final_time,spillLocation,Particles,vis_maps,Dcomp,saving,...
        ensemble_grid,vMap3D,vMap2D,Map_fig3D,Map_fig2D,dateHour_str,Params);
    end
    %------------------------ Get velocity fields ------------------------%
    if Params.velocityFieldsType == 1
      [velocities,WindFile,OceanFile] = velocityFields_1(...
        first_time,SerialDay,ts,LagrTimeStep,spillLocation,OceanFile,WindFile,Params);
    elseif Params.velocityFieldsType == 2
      [velocities,WindFile,OceanFile] = velocityFields_2(...
        first_time,SerialDay,ts,LagrTimeStep,spillLocation,OceanFile,WindFile,Params);
    else
      error('Unknown velocity fields type')
    end
    %-------------------------- Move particles ---------------------------%
    if Params.RungeKutta == 4
      Particles = movePartsRK4(OceanFile,velocities,Particles,Params,...
        spillLocation,LagrTimeStep,Dcomp,ts);
    elseif Params.RungeKutta == 2
      Particles = movePartsRK2(OceanFile,velocities,Particles,Params,...
        spillLocation,LagrTimeStep,Dcomp,ts);
    else
      error('Unknown Runge-Kutta method')
    end
    %----------------------------- Oil decay -----------------------------%
    if decay_true
      Particles = oilDecay(Particles,decay,spillLocation,day_Idx,...
        DailySpill,LagrTimeStep,Params);
    end
    %------------------------- Plot statistics ---------------------------%
    if any(step_sta) && (ismember(0,rem(ts,step_sta)) || first_time || final_time)
      [Stat,vStat,Stat_fig] = plotStats(Particles, Stat, ts, day_abs,...
        first_time, final_time, vis_stat, saving, outputFolder, Stat_fig,...
        dateHour_str,vStat,stat_count,last_ID,LagrTimeStep,Params);
    end
    %------------------------ Save particles data ------------------------%
    if saving.Data_on && rem(ts,saving.Data_step_ts) == 0
      file_name = strrep(dateHour_str,' ','_');
      save([outputFolder.Data,file_name],'Particles','-v6')
    end
    %---------------------------------------------------------------------%
  end
end
end
