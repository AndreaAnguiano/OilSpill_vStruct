function DailySpill = dailyOilParticles(particlesPerBarrel,DS,spillTiming)
% This function obtains the number of particles that need to be created,
% burned, discharged, etc. for every day. It can do it from a file or
% from the initial configuration

% Ask if we obtain the date from a file or not
if strcmp(DS.csv_file,'0')
    serial_dates       = (datenum(spillTiming.startDay_date):datenum(spillTiming.endSimDay_date))';
    simulationDays     = numel(serial_dates);
    spillDays          = numel(datenum(spillTiming.startDay_date):datenum(spillTiming.lastSpillDay_date));
    RITT_TopHat        = 0;
    Discharge          = [zeros(spillDays,1) + DS.Net; zeros(simulationDays-spillDays,1)];
    Burned             = zeros(simulationDays,1) + DS.Burned;
    OilyWater          = zeros(simulationDays,1) + DS.OilyWater;
    SubsurfDispersants = zeros(simulationDays,1) + DS.SubsurfDispersants;
    SurfaceDispersants = zeros(simulationDays,1) + DS.SurfaceDispersants;
else
    spill_data         = importdata(DS.csv_file);
    YearMonthDay       = spill_data.data(:,[3,1,2]);
    serial_dates       = datenum(YearMonthDay);
    Discharge          = spill_data.data(:,4);
    InlandRecovery     = spill_data.data(:,5);
    Burned             = spill_data.data(:,6);
    RITT_TopHat        = spill_data.data(:,7);
    OilyWater          = spill_data.data(:,8);
    SubsurfDispersants = spill_data.data(:,9);
    SurfaceDispersants = spill_data.data(:,10);
end
DailySpill.csv_file = DS.csv_file;

% Constants
k1 = 0.20;  % Natural dispersion (subsurface)
k2 = 4/9;   % Chemical dispersion (subsurface)
k3 = 0.05;  % Chemical dispersion (surface)
k4 = 0.33;  % First day evaporation
k5 = 0.04;  % Second day evaporation
k6 = 0.20;  % Net oil fraction in skimmed oil
k7 = 0.075; % Dissolution of dispersed oil
k8 = 0.05;  % Natural dispesion (surface)
abarrels  = 42; % There are 42 gallons in one barrel
zeros_vec = zeros(numel(Discharge),1);

% Equations according to Oil Budget Calculator (2010)
% Effective discharge (VRE)
EffectiveDischarge = Discharge - RITT_TopHat;
EffectiveDischarge(EffectiveDischarge<0) = 0;
% Subsurface chemical dispersion (VDC)
VCB = SubsurfDispersants/abarrels;
X = 90*VCB;
SubsurfChemDispr = (1-k7)*min([X*k2,EffectiveDischarge],[],2);
% Subsurface natural dispersion (VDN)
Y = EffectiveDischarge - SubsurfChemDispr./(1-k7);
SubsurfNatrDispr = (1-k7)*max([zeros_vec,k1*Y],[],2);
% Subsurface total dispersion (VDB)
SubsurfTotlDispr = SubsurfChemDispr + SubsurfNatrDispr;
% Skimmed oil as a fraction of oily water (VNW)
SkimmedOil = OilyWater*k6;
% Surface Oil
SurfaceOil = EffectiveDischarge - SubsurfTotlDispr;
% Surface Oil Accumulated
SurfaceAccum = cumsum(SurfaceOil);
% Z(t)
Z = EffectiveDischarge - SubsurfTotlDispr/(1-k7);
% Z(t-1)
Zprev = [0;Z(1:end-1)];
% Burned(t-1)
BurnedPrev = [0;Burned(1:end-1)];
% W(t-1)
Wprev = (1-k4)*Zprev-BurnedPrev;
Wprev(Wprev<0) = 0;
% W(t)
W = max([zeros_vec,(1-k4)*Z-Burned],[],2);
% Oil evaporated or dissolved (VE)
Evaporated = k4*Z + k5*Wprev + k7*SubsurfTotlDispr/(1-k7);
% Surface natural dispersion (VNS)
SurfaceNatrDispr = max([zeros_vec,k8*W],[],2);
% Surface chemical dispersants at day t (VCS)
VCS = SurfaceDispersants/abarrels;
% Other oil (VSD)
otherOil = EffectiveDischarge-(Evaporated+SkimmedOil+Burned+SubsurfTotlDispr+SurfaceNatrDispr);
% otherOil(otherOil<0) = 0;
% VS(t)
VS = cumsum(otherOil);
VS(VS<0)=0;
% VS(t-1)
VSprev = [0;VS(1:end-1)];
% Surface chemical dispersion (VDS)
SurfaceChemDispr = min([20*k3*VCS,VSprev],[],2);
% Surface degradation
SurfDeg = Evaporated+SkimmedOil+Burned+SurfaceNatrDispr+SurfaceChemDispr;
% Surface degradation accumulated
SurfDegAccum = cumsum(SurfDeg);
% Oil in surface water
surfWater = SurfaceAccum - SurfDegAccum;

% Barrels to particles
DailySpill.SerialDates = serial_dates;
DailySpill.Net = EffectiveDischarge * particlesPerBarrel;
DailySpill.Surface = SurfaceOil * particlesPerBarrel;
DailySpill.Subsurf = SubsurfTotlDispr * particlesPerBarrel;
DailySpill.Burned = Burned * particlesPerBarrel;
DailySpill.Evaporated = Evaporated * particlesPerBarrel;
DailySpill.Collected = SkimmedOil * particlesPerBarrel;
DailySpill.SurfaceNatrDispr = SurfaceNatrDispr * particlesPerBarrel;
DailySpill.SurfaceChemDispr = SurfaceChemDispr * particlesPerBarrel;
end
