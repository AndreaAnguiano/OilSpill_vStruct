function [last_ID,Particles,PartsPerTS] =...
  releaseParticles(day_abs,ts,spillTiming,spillLocation,DailySpill,first_time,...
  PartsPerTS,Particles,last_ID,Params,LagrTimeStep)
if first_time
  firstSpillDay_Idx = find(DailySpill.SerialDates == spillTiming.startDay_serial);
  finalSpillDay_Idx = find(DailySpill.SerialDates == spillTiming.lastSpillDay_serial);
  surf_Idx = find(spillLocation.Heights == 0);
  if isempty(surf_Idx)
    PartsPerTS.dailySurface = 0;
  else
    PartsPerTS.dailySurface = DailySpill.Surface(firstSpillDay_Idx:finalSpillDay_Idx)/LagrTimeStep.PerDay;
  end
  subs_Idx = find(spillLocation.Heights > 0);
  if isempty(subs_Idx)
    PartsPerTS.dailySubsurf = 0;
  else
    tot_fraction = sum(Params.subsurfaceFractions(1:numel(subs_Idx)));
    PartsPerTS.dailySubsurf = DailySpill.Subsurf(firstSpillDay_Idx:finalSpillDay_Idx)*tot_fraction/LagrTimeStep.PerDay;
  end
  PartsPerTS.dailyTotal = PartsPerTS.dailySurface + PartsPerTS.dailySubsurf;
  PartsPerTS.dailySurfaceBTWtotal = PartsPerTS.dailySurface./PartsPerTS.dailyTotal;
  PartsPerTS.dailySubsurfBTWtotal = PartsPerTS.dailySubsurf./PartsPerTS.dailyTotal;
  PartsPerTS.dailyDepthThresholds = nan(spillTiming.spillDays,spillLocation.n_Heights);
  PartsPerTS.dailyDepthThresholds(:,surf_Idx) = PartsPerTS.dailySurfaceBTWtotal;
  count_cicle = 0;
  for subsurf_cicle = subs_Idx
    count_cicle = count_cicle + 1;
    PartsPerTS.dailyDepthThresholds(:,subsurf_cicle) = PartsPerTS.dailySubsurfBTWtotal*Params.subsurfaceFractions(count_cicle);
  end
  PartsPerTS.dailyDepthThresholds = cumsum(PartsPerTS.dailyDepthThresholds,2);
  
  PartsPerTS.real = nan(LagrTimeStep.PerDay,spillTiming.spillDays);
  for day_cicle = 1 : spillTiming.spillDays
    for TS_cicle = 1 : LagrTimeStep.PerDay
      PartsPerTS.real(TS_cicle,day_cicle) = roundStat(PartsPerTS.dailyTotal(day_cicle));
    end
  end
  PartsPerTS.realSum = sum(sum(PartsPerTS.real));
  
  Particles.Age_days      = nan(1,PartsPerTS.realSum);
  Particles.Status        = nan(1,PartsPerTS.realSum);
  Particles.Depth         = nan(1,PartsPerTS.realSum);
  Particles.Comp          = nan(1,PartsPerTS.realSum);
  Particles.Lat           = nan(1,PartsPerTS.realSum);
  Particles.Lon           = nan(1,PartsPerTS.realSum);
end

PartsPerDepth_threshold = PartsPerTS.dailyDepthThresholds(day_abs,:);

PartsPerTimeStep = PartsPerTS.real(ts,day_abs);

NewAges     = zeros(1,PartsPerTimeStep);
NewStatus   = ones(1,PartsPerTimeStep);
NewHeights   = nan(1,PartsPerTimeStep);
NewComps    = NewHeights;
NewLats     = NewHeights;
NewLons     = NewHeights;
first_ID    = last_ID + 1;
last_ID     = last_ID + PartsPerTimeStep;
rand_Heights = rand(1,PartsPerTimeStep);
for depth_cicle = 1 : spillLocation.n_Heights
  NewHeights_Idx = find(rand_Heights <= PartsPerDepth_threshold(depth_cicle));
  NewHeights(NewHeights_Idx) = spillLocation.Heights(depth_cicle);
  numel_NewHeights_Idx = numel(NewHeights_Idx);
  NewLats(NewHeights_Idx) = spillLocation.Lat + randn(1,numel_NewHeights_Idx) .*...
    spillLocation.Radius_degLat(depth_cicle);
  NewLons(NewHeights_Idx) = spillLocation.Lon + randn(1,numel_NewHeights_Idx) .*...
    spillLocation.Radius_degLon(depth_cicle);
  rand_Comps = rand(1,numel_NewHeights_Idx);
  for comp_cicle = 1 : Params.components_number
    comps_threshold = max(cumsum(Params.components_proportions(depth_cicle,1:comp_cicle)));
    NewComps(NewHeights_Idx(rand_Comps <= comps_threshold)) = comp_cicle;
    rand_Comps(rand_Comps <= comps_threshold) = nan;
  end
  rand_Heights(rand_Heights <= PartsPerDepth_threshold(depth_cicle)) = nan;
end
Particles.Age_days(first_ID:last_ID) = NewAges;
Particles.Status(first_ID:last_ID)   = NewStatus;
Particles.Depth(first_ID:last_ID)    = NewHeights;
Particles.Comp(first_ID:last_ID)     = NewComps;
Particles.Lat(first_ID:last_ID)      = NewLats;
Particles.Lon(first_ID:last_ID)      = NewLons;
% Status:
% 1 = In water
% 2 = In land
% 3 = Out of domain
% 4 = Burned
% 5 = Collected
% 6 = Evaporated
% 7 = Naturally dispersed
% 8 = Chemically dispersed
% 9 = Exponentially degraded
end