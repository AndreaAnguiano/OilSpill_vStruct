function  Particles = oilDecay(Particles,decay,spillLocation,day_Idx,...
  DailySpill,LagrTimeStep,Params)
%------------------- Prepare particles for elimination -------------------%
% Burned
if decay.burn
  burnedPerTimeStep = DailySpill.Burned(day_Idx)/LagrTimeStep.PerDay;
  burnedPerTimeStep = roundStat(burnedPerTimeStep);
  if burnedPerTimeStep > 0
    burn_Idx = find(Particles.Depth == 0 & Particles.Status == 1 &...
      Particles.Lat <= spillLocation.Lat + decay.burn_radiusDegLat &...
      Particles.Lat >= spillLocation.Lat - decay.burn_radiusDegLat &...
      Particles.Lon <= spillLocation.Lon + decay.burn_radiusDegLon &...
      Particles.Lon >= spillLocation.Lon - decay.burn_radiusDegLon);
    if burnedPerTimeStep <= numel(burn_Idx)
      burn_Idx = burn_Idx(randperm(numel(burn_Idx)));
      Particles.Status(burn_Idx(1:burnedPerTimeStep)) = 4;
    else
      warning('More particles to burn than possible')
      Particles.Status(burn_Idx) = 4;
    end
  end
end
% Collected
if decay.collect
  collectedPerTimeStep = DailySpill.Collected(day_Idx)/LagrTimeStep.PerDay;
  collectedPerTimeStep = roundStat(collectedPerTimeStep);
  if collectedPerTimeStep > 0
    collect_Idx = find(Particles.Depth == 0 & Particles.Status == 1);
    if collectedPerTimeStep <= numel(collect_Idx)
      collect_Idx = collect_Idx(randperm(numel(collect_Idx)));
      Particles.Status(collect_Idx(1:collectedPerTimeStep)) = 5;
    else
      warning('More particles to collect than possible')
      Particles.Status(collect_Idx) = 5;
    end
  end
end
% Evaporated
if decay.evaporate
  evaporatedPerTimeStep = DailySpill.Evaporated(day_Idx)/LagrTimeStep.PerDay;
  evaporatedPerTimeStep = roundStat(evaporatedPerTimeStep);
  if evaporatedPerTimeStep > 0
    evaporate_Idx = find(Particles.Depth == 0 & Particles.Status == 1);
    if evaporatedPerTimeStep <= numel(evaporate_Idx)
      evaporate_Idx = evaporate_Idx(randperm(numel(evaporate_Idx)));
      Particles.Status(evaporate_Idx(1:evaporatedPerTimeStep)) = 6;
    else
      warning('More particles to evaporate than possible')
      Particles.Status(evaporate_Idx) = 6;
    end
  end
end
% Naturally dispersed
if decay.surfNatrDispr
  natrDisprPerTimeStep = DailySpill.SurfaceNatrDispr(day_Idx)/LagrTimeStep.PerDay;
  natrDisprPerTimeStep = roundStat(natrDisprPerTimeStep);
  if natrDisprPerTimeStep > 0
    natrDisprPer_Idx = find(Particles.Depth == 0 & Particles.Status == 1);
    if natrDisprPerTimeStep <= numel(natrDisprPer_Idx)
      natrDisprPer_Idx = natrDisprPer_Idx(randperm(numel(natrDisprPer_Idx)));
      Particles.Status(natrDisprPer_Idx(1:natrDisprPerTimeStep)) = 7;
    else
      warning('More particles to naturally disperse than possible')
      Particles.Status(natrDisprPer_Idx) = 7;
    end
  end
end
% Chemically dispersed
if decay.surfChemDispr
  chemDisprPerTimeStep = DailySpill.SurfaceChemDispr(day_Idx)/LagrTimeStep.PerDay;
  chemDisprPerTimeStep = roundStat(chemDisprPerTimeStep);
  if chemDisprPerTimeStep > 0
    chemDisprPer_Idx = find(Particles.Depth == 0 & Particles.Status == 1);
    if chemDisprPerTimeStep <= numel(chemDisprPer_Idx)
      chemDisprPer_Idx = chemDisprPer_Idx(randperm(numel(chemDisprPer_Idx)));
      Particles.Status(chemDisprPer_Idx(1:chemDisprPerTimeStep)) = 8;
    else
      warning('More particles to chemically disperse than possible')
      Particles.Status(chemDisprPer_Idx) = 8;
    end
  end
end
% Exponentially degraded
if decay.expDegrade
  for comp_cicle = 1 : Params.components_number
    exp_deg_Idx = find(Particles.Comp == comp_cicle & Particles.Status == 1);
    rand_num = rand(1,numel(exp_deg_Idx));
    Particles.Status(exp_deg_Idx(rand_num > decay.expDegrade_thresholds(comp_cicle))) = 9;
  end
end
end