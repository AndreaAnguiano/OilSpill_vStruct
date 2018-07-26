function [last_ID,Particles,PartsPerTS] =...
    releaseParticles(day_abs,ts,spillTiming,spillLocation,DailySpill,first_time,...
    PartsPerTS,Particles,last_ID,Params,LagrTimeStep)
    % This function creates particles each time step 

    % day_abs       --> Current day in the simulation (integer value starting at 1 )
    % ts            --> Current time step 
    % spillTiming   --> Structure with the time information (start date, end date, spill date, etc. )
    % spillLocation --> Structure with the location and depth information (depths, lat, lon, etc.)
    % DailySpill    --> Structure with the oil information (particles per day, surface, subsurface, burned, evaporated, etc.)
    % first_time    --> Bool variable that indicates if its the first time we enter in this function
    % PartsPerTS    --> Number of particles per time step (TODO verify it is correct)
    % Particles     --> Structure of arrays with the information of ALL the particles
    % last_ID       --> Pointer to the last particle that was created
    % Params        --> Structure with main parameters of the model (RK, domainLimits, particlesPerBarrel, etc.)
    % LagrTimeStep  --> Structure with information about the lagratian time steps (in hours, in seconds, etc.)

% We initialize the fist and last dates and the particles array
if first_time
    firstSpillDay_Idx = find(DailySpill.SerialDates == spillTiming.startDay_serial);
    finalSpillDay_Idx = find(DailySpill.SerialDates == spillTiming.lastSpillDay_serial);
    surf_Idx = find(spillLocation.Depths == 0);
    % Obtain total particles per timestep in the surface for all the dates
    if isempty(surf_Idx)
        PartsPerTS.dailySurface = 0;
    else
        PartsPerTS.dailySurface = DailySpill.Surface(firstSpillDay_Idx:finalSpillDay_Idx)/LagrTimeStep.PerDay;
    end
    subs_Idx = find(spillLocation.Depths > 0);
    % Obtain total particles per timestep in the subsurface for all the dates
    if isempty(subs_Idx)
        PartsPerTS.dailySubsurf = 0;
    else
        tot_fraction = sum(Params.subsurfaceFractions(1:numel(subs_Idx)));
        PartsPerTS.dailySubsurf = DailySpill.Subsurf(firstSpillDay_Idx:finalSpillDay_Idx)*tot_fraction/LagrTimeStep.PerDay;
    end
    PartsPerTS.dailyTotal = PartsPerTS.dailySurface + PartsPerTS.dailySubsurf;
    % As percentages
    PartsPerTS.dailySurfaceBTWtotal = PartsPerTS.dailySurface./PartsPerTS.dailyTotal;
    PartsPerTS.dailySubsurfBTWtotal = PartsPerTS.dailySubsurf./PartsPerTS.dailyTotal;
    % Sets the thresholds (used to create particles statistically) by depth
    PartsPerTS.dailyDepthThresholds = nan(spillTiming.spillDays,spillLocation.n_Depths);
    PartsPerTS.dailyDepthThresholds(:,surf_Idx) = PartsPerTS.dailySurfaceBTWtotal;
    count_cicle = 0;
    % TODO review and comment this part
    for subsurf_cicle = subs_Idx
        count_cicle = count_cicle + 1;
        PartsPerTS.dailyDepthThresholds(:,subsurf_cicle) = PartsPerTS.dailySubsurfBTWtotal*Params.subsurfaceFractions(count_cicle);
    end
    PartsPerTS.dailyDepthThresholds = cumsum(PartsPerTS.dailyDepthThresholds,2);
    
    % Computes the final number of particles for each time step
    PartsPerTS.finalNumPart = nan(LagrTimeStep.PerDay,spillTiming.spillDays);
    for day_cicle = 1 : spillTiming.spillDays
        for TS_cicle = 1 : LagrTimeStep.PerDay
            PartsPerTS.finalNumPart(TS_cicle,day_cicle) = roundStat(PartsPerTS.dailyTotal(day_cicle));
        end
    end
    PartsPerTS.finalParticlesSum = sum(sum(PartsPerTS.finalNumPart));
    
    Particles.Age_days      = nan(1,PartsPerTS.finalParticlesSum);
    Particles.Status        = nan(1,PartsPerTS.finalParticlesSum);
    Particles.Depth         = nan(1,PartsPerTS.finalParticlesSum);
    Particles.Comp          = nan(1,PartsPerTS.finalParticlesSum);
    Particles.Lat           = nan(1,PartsPerTS.finalParticlesSum);
    Particles.Lon           = nan(1,PartsPerTS.finalParticlesSum);
end

PartsPerDepth_threshold = PartsPerTS.dailyDepthThresholds(day_abs,:);

PartsPerTimeStep = PartsPerTS.finalNumPart(ts,day_abs);

NewAges     = zeros(1,PartsPerTimeStep);
NewStatus   = ones(1,PartsPerTimeStep);
NewDepths   = nan(1,PartsPerTimeStep);
NewComps    = NewDepths;
NewLats     = NewDepths;
NewLons     = NewDepths;
first_ID    = last_ID + 1;
last_ID     = last_ID + PartsPerTimeStep;
rand_Depths = rand(1,PartsPerTimeStep);

for depth_cicle = 1 : spillLocation.n_Depths
    NewDepths_Idx = find(rand_Depths <= PartsPerDepth_threshold(depth_cicle));
    NewDepths(NewDepths_Idx) = spillLocation.Depths(depth_cicle);
    numel_NewDepths_Idx = numel(NewDepths_Idx);
    NewLats(NewDepths_Idx) = spillLocation.Lat + randn(1,numel_NewDepths_Idx) .*...
                                spillLocation.Radius_degLat(depth_cicle);
    NewLons(NewDepths_Idx) = spillLocation.Lon + randn(1,numel_NewDepths_Idx) .*...
                                spillLocation.Radius_degLon(depth_cicle);
    rand_Comps = rand(1,numel_NewDepths_Idx);
    for comp_cicle = 1 : Params.components_number
        comps_threshold = max(cumsum(Params.components_proportions(depth_cicle,1:comp_cicle)));
        NewComps(NewDepths_Idx(rand_Comps <= comps_threshold)) = comp_cicle;
        rand_Comps(rand_Comps <= comps_threshold) = nan;
    end
    rand_Depths(rand_Depths <= PartsPerDepth_threshold(depth_cicle)) = nan;
end
Particles.Age_days(first_ID:last_ID) = NewAges;
Particles.Status(first_ID:last_ID)   = NewStatus;
Particles.Depth(first_ID:last_ID)    = NewDepths;
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
