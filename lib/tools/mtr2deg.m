% [distance_in_degrees] = mtr2deg(distance_in_meters, lat, choice, R)
%
% Transform a distance_in_meters into degrees of latitude (lat_deg) or
% degrees of longitude (lon_deg) as a function of the latitude (lat).
% A circle radius (R) in meters is considered. 
% For instance, R = 6371000 m corresponds to the mean Earth radius.
%
% choice may be set to 'lat_deg' or 'lon_deg'
%    Set choice = 'lat_deg' to obtain degrees of latitude.
%    Set choice = 'lon_deg' to obtain degrees of longitude.
%
% Example:
%
%   distance_in_meters = 500;
%   lat = 28;
%   R = 6371000;
%
%   lat_deg = mtr2deg(distance_in_meters, lat,'lat_deg', R) = 0.0045
%   lon_deg = mtr2deg(distance_in_meters, lat,'lon_deg', R) = 0.0051
%
function [distance_in_degrees] = mtr2deg(distance_in_meters, Lat, choice, Dcomp)
    % Average Earth radius in meters
    if strcmp(choice,'lat_deg')
        % Transform distance in meters into degrees of latitude
        distance_in_degrees = Dcomp.cst .* distance_in_meters;
    elseif strcmp(choice,'lon_deg')
        % Transform distance in meters into degrees of longitude
        distance_in_degrees = Dcomp.cst .* distance_in_meters./cosd(Lat);
    end
end
