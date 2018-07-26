function [Stat,vStat,Stat_fig] = plotStats(Particles,Stat,ts,day_abs,first_time,...
  final_time,vis_stat,saving,outputFolder,Stat_fig,dateHour_str,vStat,...
  stat_count,last_ID,LagrTimeStep,Params)
%--- Plot the base graph if it is the first day and the firs time step ---%
if first_time
  set(0,'DefaultFigureVisible',vis_stat.visible);
  Stat_fig = figure;
  axis(vis_stat.axesLimits)
  view([0,90])
  xlabel('Dias')
  ylabel('Barriles')
  set(Stat_fig,'color','w','resize','off')
  set(gca,'FontSize',vis_stat.fontSize)
  if saving.StatVideo_on
    vStat = VideoWriter([outputFolder.StatVideo,'Statistics.avi']);
    vStat.FrameRate = saving.StatVideo_framesPerSecond;
    vStat.Quality   = saving.StatVideo_quality;
    open(vStat);
  end
end
%---------------------------- Plot line graph ----------------------------%
stat_count = stat_count + 1;
set(0,'currentfigure',Stat_fig);
img_name = dateHour_str;
title(img_name)
X = (day_abs-1) + (ts-1)*LagrTimeStep.InDays;
hold on
Stat.Pwater(stat_count) = sum(Particles.Status(1:last_ID) == 1);
% Particles on surface
Stat.Psurfa(stat_count) = sum(Particles.Status(1:last_ID) == 1 & Particles.Depth(1:last_ID) == 0);
plot(X,Stat.Psurfa/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{1})
% Particles in subsurface
Stat.Psubsu(stat_count) = sum(Particles.Status(1:last_ID) == 1 & Particles.Depth(1:last_ID) > 0);
plot(X,Stat.Psubsu/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{2})
% Particles in land
Stat.Pland(stat_count)  = sum(Particles.Status(1:last_ID) == 2);
plot(X,Stat.Pland/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{3})
% Particles outside the domain
Stat.PoutDomain(stat_count)    = sum(Particles.Status(1:last_ID) == 3);
plot(X,Stat.PoutDomain/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{4})
% Particles burned
Stat.Pburned(stat_count)       = sum(Particles.Status(1:last_ID) == 4);
plot(X,Stat.Pburned/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{5})
% Particles collected
Stat.Pcollected(stat_count)    = sum(Particles.Status(1:last_ID) == 5);
plot(X,Stat.Pcollected/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{6})
% Particles evaporated
Stat.Pevaporated(stat_count)   = sum(Particles.Status(1:last_ID) == 6);
plot(X,Stat.Pevaporated/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{7})
% Particles naturally dispersed
Stat.PnatrDispr(stat_count)    = sum(Particles.Status(1:last_ID) == 7);
plot(X,Stat.PnatrDispr/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{8})
% Particles chemically dispersed
Stat.PchemDispr(stat_count)    = sum(Particles.Status(1:last_ID) == 8);
plot(X,Stat.PchemDispr/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{9})
% Particles exponentially degraded
Stat.Pexp_degraded(stat_count) = sum(Particles.Status(1:last_ID) == 9);
plot(X,Stat.Pexp_degraded/Params.particlesPerBarrel,'o','MarkerSize',vis_stat.markerSize,...
  'MarkerEdgeColor',vis_stat.lineColors{10})
% Set figure legend
if first_time
  legend_labels = {'Surface','Subsurface','Landed','OutDom','Burned','Collected',...
    'Evaporated','NatrDispr','ChemDispr','ExpDegr'};
  legend(legend_labels,'location','NorthEastOutside')
  set(Stat_fig,'units','centimeters','Position',vis_stat.figPosition)
  set(gca,'units','centimeters','Position',vis_stat.axesPosition)
end
% Visualize
if strcmp(vis_stat.visible,'on') && (rem(ts,vis_stat.visible_step_ts) == 0 || first_time)
  pause(0.5)
end
% Save image
if saving.StatImage_on && (rem(ts,saving.StatImage_step_ts) == 0 || first_time || final_time)
  img_name = strrep(img_name,' ','_');
  export_fig(Stat_fig,[outputFolder.StatImage,img_name],...
    '-png','-nocrop',saving.StatImage_quality)
end
% Save video
if saving.StatVideo_on && (rem(ts,saving.StatVideo_step_ts) == 0 || first_time || final_time)
  drawnow;
  frame = getframe(Stat_fig);
  writeVideo(vStat,frame);
  if final_time
    close(vStat);
  end
end
end