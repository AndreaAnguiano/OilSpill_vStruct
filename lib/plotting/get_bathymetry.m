% Read the bathymetry of the domain.
%
% [lon_bathy,lat_bathy,depth_bathy] = get_bathymetry(bathy_name)
%
% lon_bathy   = bathymetry longitudes.
% lat_bathy   = bathymetry latitudes.
% depth_bathy = bathymetry.
% bathy_name  = Name of the bathymetric set to use.
function [lon_bathy,lat_bathy,depth_bathy] = get_bathymetry(vis_maps)
% Read bathymetry
if strcmp(vis_maps.bathymetry,'gebco_1min_-98_18_-78_31.nc')
  x_range = ncread(vis_maps.bathymetry,'x_range');
  y_range = ncread(vis_maps.bathymetry,'y_range');
  spacing = ncread(vis_maps.bathymetry,'spacing');
  dimension = ncread(vis_maps.bathymetry,'dimension');
  z = ncread(vis_maps.bathymetry,'z');
  lat = y_range(2):-spacing(1):y_range(1);
  lon = x_range(1):spacing(1):x_range(2);
  [lat_bathy,lon_bathy]=meshgrid(lat,lon);
  lat_bathy = flip(lat_bathy');
  lon_bathy = flip(lon_bathy');
  depth_bathy = flip(reshape(z,[dimension(1),dimension(2)])');
  depth_bathy(depth_bathy > 0) = 0;
elseif strcmp(vis_maps.bathymetry,'BAT_FUS_GLOBAL_PIXEDIT_V4.mat')
  bathy_data = load(vis_maps.bathymetry);
  bathy_data.ZZ4b(isnan(bathy_data.ZZ4b)) = 0;
  depth_bathy = -bathy_data.ZZ4b;
  lon_bathy = bathy_data.LON25;
  lat_bathy = bathy_data.LAT25;
elseif strcmp(vis_maps.bathymetry,'BATI100_s10_fixLC.mat')
  bathy_data = load(vis_maps.bathymetry);
  bathy_data.ZZ_3(isnan(bathy_data.ZZ_3)) = 0;
  depth_bathy = bathy_data.ZZ_3;
  lon_bathy = bathy_data.LON100;
  lat_bathy = bathy_data.LAT100;
end
% Crop the specified region
lonMinLim = find(lon_bathy(1,:) < vis_maps.boundaries(1),1,'last');
depth_bathy(:,1:lonMinLim,:) = [];
lon_bathy(:,1:lonMinLim,:) = [];
lat_bathy(:,1:lonMinLim,:) = [];
lonMaxLim = find(lon_bathy(1,:) > vis_maps.boundaries(2),1,'first');
depth_bathy(:,lonMaxLim:end,:) = [];
lon_bathy(:,lonMaxLim:end,:) = [];
lat_bathy(:,lonMaxLim:end,:) = [];
latMinLim = find(lat_bathy(:,1) < vis_maps.boundaries(3),1,'last');
depth_bathy(1:latMinLim,:,:) = [];
lon_bathy(1:latMinLim,:,:) = [];
lat_bathy(1:latMinLim,:,:) = [];
latMaxLim = find(lat_bathy(:,1) > vis_maps.boundaries(4),1,'first');
depth_bathy(latMaxLim:end,:,:) = [];
lon_bathy(latMaxLim:end,:,:) = [];
lat_bathy(latMaxLim:end,:,:) = [];
end