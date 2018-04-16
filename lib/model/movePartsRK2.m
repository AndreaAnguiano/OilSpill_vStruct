% Routine for computing trajectories of virtual particles in velocity fields.
% A 2nd order Runge-Kutta scheme is used.

function Particles = movePartsRK2(OceanFile,velocities,Particles,Params,...
  spillLocation,LagrTimeStep,Dcomp,ts)
% Compute velocities for the current time_step plus half time_step
U_half = velocities.Uts1 + (velocities.Uts2-velocities.Uts1)/2;
V_half = velocities.Vts1 + (velocities.Vts2-velocities.Vts1)/2;
for DepthLayer = 1 : spillLocation.n_Depths
  % Get position1 of particles to move
  depth_ind = find(Particles.Status == 1 & Particles.Depth == spillLocation.Depths(DepthLayer));
  position1lat = Particles.Lat(depth_ind);
  position1lon = Particles.Lon(depth_ind);
  
  % Interpolate U and V to position1
  Upart = interp2(OceanFile.Lon, OceanFile.Lat, velocities.Uts1(:,:,DepthLayer), position1lon, position1lat);
  Vpart = interp2(OceanFile.Lon, OceanFile.Lat, velocities.Vts1(:,:,DepthLayer), position1lon, position1lat);
  
  % Move particles from position1 to dt/2 * Vpart
  tempK2lat = position1lat + (LagrTimeStep.InSec_half*Vpart)*Dcomp.cst;
  tempK2lon = position1lon + ((LagrTimeStep.InSec_half*Upart)*Dcomp.cst).*cosd(position1lat);
  
  % Check for particles outside the domain
  outDom_Idx =...
    tempK2lon < Params.domainLimits(1) | tempK2lon > Params.domainLimits(2) |...
    tempK2lat < Params.domainLimits(3) | tempK2lat > Params.domainLimits(4);
  if any(outDom_Idx)
    Particles.Status(depth_ind(outDom_Idx)) = 3;
    tempK2lat(outDom_Idx) = [];
    tempK2lon(outDom_Idx) = [];
    position1lat(outDom_Idx) = [];
    position1lon(outDom_Idx) = [];
    depth_ind(outDom_Idx) = [];
  end
  
  % Interpolate U and V to positions tempK2l.. using velocities at DT + DT/2 (U_half, V_half)
  UintPart = interp2(OceanFile.Lon, OceanFile.Lat, U_half(:,:,DepthLayer), tempK2lon, tempK2lat);
  VintPart = interp2(OceanFile.Lon, OceanFile.Lat, V_half(:,:,DepthLayer), tempK2lon, tempK2lat);
  
  % Add turbulent-diffusion
  Uturb = UintPart .* (-Params.TurbDiff_a(DepthLayer) + (2*Params.TurbDiff_a(DepthLayer)) .* rand(1,length(UintPart)));
  Vturb = VintPart .* (-Params.TurbDiff_a(DepthLayer) + (2*Params.TurbDiff_a(DepthLayer)) .* rand(1,length(VintPart)));
  UintPart = UintPart + Uturb;
  VintPart = VintPart + Vturb;
  
  % Move particles from position1 to dt * VintPart
  newLatP = position1lat +  (LagrTimeStep.InSec*VintPart)*Dcomp.cst;
  newLonP = position1lon + ((LagrTimeStep.InSec*UintPart)*Dcomp.cst).*cosd(position1lat);
  
  % Check for particles outside the domain
  outDom_Idx =...
    newLonP < Params.domainLimits(1) | newLonP > Params.domainLimits(2) |...
    newLatP < Params.domainLimits(3) | newLatP > Params.domainLimits(4);
  if any(outDom_Idx)
    Particles.Status(depth_ind(outDom_Idx)) = 3;
    newLatP(outDom_Idx) = [];
    newLonP(outDom_Idx) = [];
    depth_ind(outDom_Idx) = [];
  end
  
  % Find particles in water
  inWater = ~(isnan(newLatP) | isnan(newLonP));
  
  % Update positions of particles in water
  Particles.Lat(depth_ind(inWater)) = newLatP(inWater);
  Particles.Lon(depth_ind(inWater)) = newLonP(inWater);
  
  % Update the status of particles in land
  Particles.Status(depth_ind(~inWater)) = 2;
end
% Update the age (in days) of particles in water
Particles.Age_days(Particles.Status == 1) = Particles.Age_days(Particles.Status == 1) + ts*LagrTimeStep.InDays;
end