function [velocities,WindFile,OceanFile] = velocityFields_1(first_time,SerialDay,ts,LagrTimeStep,spillLocation,OceanFile,WindFile,Params)
    % first_time    --> Bool variable that indicates if its the first time we enter in this function
    % SerialDay     --> Indicates which day are we computing
    % ts            --> Current time step 
    % LagrTimeStep  --> Structure with information about the lagrantian time steps (in hours, in seconds, etc.)
    % spillLocation --> Structure with the location and depth information (depths, lat, lon, etc.)
    % OceanFile     --> Indicates the time step for the currents
    % WindFile      --> Indicates the time step for the winds
    % Params        --> Structure with main parameters of the model (RK, domainLimits, particlesPerBarrel, etc.)
date_time = datetime(SerialDay,'ConvertFrom','datenum');
day_DoY = day(date_time,'dayofyear');
year_str = datestr(date_time,'yyyy_');
%-------------------------Get ocean VectorFields--------------------------%
if first_time
    % Ocean file names and variable names
    OceanFile.Prefix        = 'hycom_gomu_501_';
    OceanFile.Sufix         = '_t000.nc';
    OceanFile.Uname         = 'water_u';
    OceanFile.Vname         = 'water_v';
    OceanFile.LatName       = 'lat';
    OceanFile.LonName       = 'lon';
    OceanFile.DepthName     = 'depth';
    % Define variables
    firstFileName = [OceanFile.Prefix,year_str,num2str(day_DoY),OceanFile.Sufix];
    % Reads Lat and Lon
    lat_O         = double(ncread(firstFileName,OceanFile.LatName));
    lon_O         = double(ncread(firstFileName,OceanFile.LonName));
    % Obtains the indexes inside the netCDF that corresponds to the BBOX of our run
    OceanFile.Lat_min = find(lat_O <= Params.domainLimits(3),1,'last');
    OceanFile.Lat_max = find(lat_O >= Params.domainLimits(4),1,'first');
    OceanFile.Lon_min = find(lon_O <= Params.domainLimits(1),1,'last');
    OceanFile.Lon_max = find(lon_O >= Params.domainLimits(2),1,'first');
    % Reduces the size of the lat and lon arrays with the limits of the BBOX
    lat_O = lat_O(OceanFile.Lat_min:OceanFile.Lat_max);
    lon_O = lon_O(OceanFile.Lon_min:OceanFile.Lon_max);
    OceanFile.Lat_numel = numel(lat_O);
    OceanFile.Lon_numel = numel(lon_O);
    [OceanFile.Lon,OceanFile.Lat] = meshgrid(lon_O,lat_O);
    % Reads depth
    OceanFile.depths        = double(ncread(firstFileName,OceanFile.DepthName));
    % Obtains the indexes inside the netCDF that corresponds to the limits of the depth
    OceanFile.minDepth_Idx  = find(OceanFile.depths <= min(spillLocation.Depths),1,'last');
    OceanFile.maxDepth_Idx  = find(OceanFile.depths >= max(spillLocation.Depths),1,'first');
    OceanFile.tempDepths    = OceanFile.depths(OceanFile.minDepth_Idx:OceanFile.maxDepth_Idx);
    OceanFile.n_tempDepths  = numel(OceanFile.tempDepths);
    OceanFile.toInterpolate = ismember(spillLocation.Depths,OceanFile.tempDepths);
    OceanFile.auxArray      = nan([size(OceanFile.Lat),spillLocation.n_Depths]);
    % Read ocean VectorFields for the current and next day
    readOceanFileT1 = [OceanFile.Prefix,year_str,num2str(day_DoY),OceanFile.Sufix];
    readOceanFileT2 = [OceanFile.Prefix,year_str,num2str(day_DoY+1),OceanFile.Sufix];
    OceanFile.U_T1 = ncread(readOceanFileT1,OceanFile.Uname,...
        [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
        [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
    OceanFile.V_T1 = ncread(readOceanFileT1,OceanFile.Vname,...
        [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
        [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
    OceanFile.U_T2 = ncread(readOceanFileT2,OceanFile.Uname,...
        [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
        [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
    OceanFile.V_T2 = ncread(readOceanFileT2,OceanFile.Vname,...
        [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
        [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
    OceanFile.U_T1 = permute(OceanFile.U_T1,[2 1 3]);
    OceanFile.V_T1 = permute(OceanFile.V_T1,[2 1 3]);
    OceanFile.U_T2 = permute(OceanFile.U_T2,[2 1 3]);
    OceanFile.V_T2 = permute(OceanFile.V_T2,[2 1 3]);
    % Get ocean VectorFields layers acording to the user depths
    ocean_U_T1_temp = OceanFile.auxArray;
    ocean_V_T1_temp = OceanFile.auxArray;
    ocean_U_T2_temp = OceanFile.auxArray;
    ocean_V_T2_temp = OceanFile.auxArray;
    if spillLocation.n_Depths ~= OceanFile.n_tempDepths || any(~OceanFile.toInterpolate)
        for layer = 1 : spillLocation.n_Depths
            if ~OceanFile.toInterpolate(layer)
                % Interpolate depth
                lower_layer                = find(OceanFile.tempDepths < spillLocation.Depths(layer),1,'last');
                upper_layer                = find(OceanFile.tempDepths > spillLocation.Depths(layer),1,'first');
                layers_mtr_diff            = OceanFile.tempDepths(upper_layer) - OceanFile.tempDepths(lower_layer);
                Depth_mtr_diff             = spillLocation.Depths(layer) - OceanFile.tempDepths(lower_layer);
                DepthDiff_BTW_layersDiff   = Depth_mtr_diff./layers_mtr_diff;
                layers_U_diff_T1           = OceanFile.U_T1(:,:,upper_layer) - OceanFile.U_T1(:,:,lower_layer);
                layers_V_diff_T1           = OceanFile.V_T1(:,:,upper_layer) - OceanFile.V_T1(:,:,lower_layer);
                ocean_U_T1_temp(:,:,layer) = OceanFile.U_T1(:,:,lower_layer) + layers_U_diff_T1.* DepthDiff_BTW_layersDiff;
                ocean_V_T1_temp(:,:,layer) = OceanFile.V_T1(:,:,lower_layer) + layers_V_diff_T1.* DepthDiff_BTW_layersDiff;
                layers_U_diff_T2           = OceanFile.U_T2(:,:,upper_layer) - OceanFile.U_T2(:,:,lower_layer);
                layers_V_diff_T2           = OceanFile.V_T2(:,:,upper_layer) - OceanFile.V_T2(:,:,lower_layer);
                ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,lower_layer) + layers_U_diff_T2.* DepthDiff_BTW_layersDiff;
                ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,lower_layer) + layers_V_diff_T2.* DepthDiff_BTW_layersDiff;
            else
                % Allocate layer
                correct_layer = find(OceanFile.depths(layer) == OceanFile.tempDepths);
                ocean_U_T1_temp(:,:,layer) = OceanFile.U_T1(:,:,correct_layer);
                ocean_V_T1_temp(:,:,layer) = OceanFile.V_T1(:,:,correct_layer);
                ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,correct_layer);
                ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,correct_layer);
            end
        end
        OceanFile.U_T1 = ocean_U_T1_temp;
        OceanFile.V_T1 = ocean_V_T1_temp;
        OceanFile.U_T2 = ocean_U_T2_temp;
        OceanFile.V_T2 = ocean_V_T2_temp;
    else
        misplaced = OceanFile.tempDepths ~= spillLocation.Depths';
        if any(misplaced)
            for layer = 1 : spillLocation.n_Depths
                if misplaced(layer)
                    correct_layer = find(OceanFile.tempDepths==spillLocation.Depths(layer));
                    ocean_U_T1_temp(:,:,layer) = OceanFile.U_T1(:,:,correct_layer);
                    ocean_V_T1_temp(:,:,layer) = OceanFile.V_T1(:,:,correct_layer);
                    ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,correct_layer);
                    ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,correct_layer);
                else
                    ocean_U_T1_temp(:,:,layer) = OceanFile.U_T1(:,:,layer);
                    ocean_V_T1_temp(:,:,layer) = OceanFile.V_T1(:,:,layer);
                    ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,layer);
                    ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,layer);
                end
            end
            OceanFile.U_T1 = ocean_U_T1_temp;
            OceanFile.V_T1 = ocean_V_T1_temp;
            OceanFile.U_T2 = ocean_U_T2_temp;
            OceanFile.V_T2 = ocean_V_T2_temp;
        end
    end
else
    flag_one = floor((ts-2)*LagrTimeStep.BTW_oceanTS);
    flag_two = floor((ts-1)*LagrTimeStep.BTW_oceanTS);
    if flag_one ~= flag_two
        % Rename and read ocean VectorFields for the next day
        readOceanFile = [OceanFile.Prefix,year_str,num2str(day_DoY+1),OceanFile.Sufix];
        OceanFile.U_T1 = OceanFile.U_T2;
        OceanFile.V_T1 = OceanFile.V_T2;
        OceanFile.U_T2 = ncread(readOceanFile,OceanFile.Uname,...
            [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
            [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
        OceanFile.V_T2 = ncread(readOceanFile,OceanFile.Vname,...
            [OceanFile.Lon_min,OceanFile.Lat_min,OceanFile.minDepth_Idx,1],...
            [OceanFile.Lon_numel,OceanFile.Lat_numel,OceanFile.n_tempDepths,1]);
        OceanFile.U_T2 = permute(OceanFile.U_T2,[2 1 3]);
        OceanFile.V_T2 = permute(OceanFile.V_T2,[2 1 3]);
        % Get ocean VectorFields layers acording to the user depths
        ocean_U_T2_temp = OceanFile.auxArray;
        ocean_V_T2_temp = OceanFile.auxArray;
        if spillLocation.n_Depths ~= OceanFile.n_tempDepths || any(~OceanFile.toInterpolate)
            for layer = 1 : spillLocation.n_Depths
                if ~OceanFile.toInterpolate(layer)
                    % Interpolate
                    lower_layer                = find(OceanFile.tempDepths < spillLocation.Depths(layer),1,'last');
                    upper_layer                = find(OceanFile.tempDepths > spillLocation.Depths(layer),1,'first');
                    layers_mtr_diff            = OceanFile.tempDepths(upper_layer) - OceanFile.tempDepths(lower_layer);
                    Depth_mtr_diff             = spillLocation.Depths(layer) - OceanFile.tempDepths(lower_layer);
                    DepthDiff_BTW_layersDiff   = Depth_mtr_diff./layers_mtr_diff;
                    layers_U_diff_T2           = OceanFile.U_T2(:,:,upper_layer) - OceanFile.U_T2(:,:,lower_layer);
                    layers_V_diff_T2           = OceanFile.V_T2(:,:,upper_layer) - OceanFile.V_T2(:,:,lower_layer);
                    ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,lower_layer) + layers_U_diff_T2 .* DepthDiff_BTW_layersDiff;
                    ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,lower_layer) + layers_V_diff_T2 .* DepthDiff_BTW_layersDiff;
                else
                    % Rearrange
                    correct_layer = find(OceanFile.tempDepths == spillLocation.Depths(layer));
                    ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,correct_layer);
                    ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,correct_layer);
                end
            end
            OceanFile.U_T2 = ocean_U_T2_temp;
            OceanFile.V_T2 = ocean_V_T2_temp;
        else
            misplaced = OceanFile.tempDepths ~= spillLocation.Depths';
            if any(misplaced)
                for layer = 1 : spillLocation.n_Depths
                    if misplaced(layer)
                        correct_layer = find(OceanFile.tempDepths==spillLocation.Depths(layer));
                        ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,correct_layer);
                        ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,correct_layer);
                    else
                        ocean_U_T2_temp(:,:,layer) = OceanFile.U_T2(:,:,layer);
                        ocean_V_T2_temp(:,:,layer) = OceanFile.V_T2(:,:,layer);
                    end
                end
                OceanFile.U_T2 = ocean_U_T2_temp;
                OceanFile.V_T2 = ocean_V_T2_temp;
            end
        end
    end
end
%--------------------------Get wind VectorFields--------------------------%
surface_simulation = ismember(0,spillLocation.Depths);
if surface_simulation
    if first_time
        % Wind file names and varible names
        WindFile.Prefix       = 'WRF_';
        WindFile.Sufix        = '.nc';
        WindFile.Uname        = 'U_Viento';
        WindFile.Vname        = 'V_Viento';
        WindFile.LatName      = 'Latitud';
        WindFile.LonName      = 'Longitud';
        % Define variables
        firstFileName = [WindFile.Prefix,year_str,num2str(day_DoY),'_1',WindFile.Sufix];
        lat_W = double(ncread(firstFileName,WindFile.LatName));
        lon_W = double(ncread(firstFileName,WindFile.LonName));
        WindFile.Lat_min = find(lat_W <= min(lat_O),1,'last');
        WindFile.Lat_max = find(lat_W >= max(lat_O),1,'first');
        WindFile.Lon_min = find(lon_W <= min(lon_O),1,'last');
        WindFile.Lon_max = find(lon_W >= max(lon_O),1,'first');
        lat_W = lat_W(WindFile.Lat_min:WindFile.Lat_max);
        lon_W = lon_W(WindFile.Lon_min:WindFile.Lon_max);
        WindFile.Lat_numel = numel(lat_W);
        WindFile.Lon_numel = numel(lon_W);
        [WindFile.Lon,WindFile.Lat] = meshgrid(lon_W,lat_W);
        % Read wind VectorFields from the current and next file
        readWindFileT1 = [WindFile.Prefix,year_str,num2str(day_DoY),'_1',WindFile.Sufix];
        readWindFileT2 = [WindFile.Prefix,year_str,num2str(day_DoY),'_2',WindFile.Sufix];
        WindFile.U_T1 = ncread(readWindFileT1,WindFile.Uname,...
            [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
        WindFile.V_T1 = ncread(readWindFileT1,WindFile.Vname,...
            [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
        WindFile.U_T2 = ncread(readWindFileT2,WindFile.Uname,...
            [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
        WindFile.V_T2 = ncread(readWindFileT2,WindFile.Vname,...
            [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
        % Interp wind grid to ocean grid
        WindFile.U_T1   = interp2(WindFile.Lon,WindFile.Lat,WindFile.U_T1,OceanFile.Lon,OceanFile.Lat);
        WindFile.V_T1   = interp2(WindFile.Lon,WindFile.Lat,WindFile.V_T1,OceanFile.Lon,OceanFile.Lat);
        WindFile.U_T2   = interp2(WindFile.Lon,WindFile.Lat,WindFile.U_T2,OceanFile.Lon,OceanFile.Lat);
        WindFile.V_T2   = interp2(WindFile.Lon,WindFile.Lat,WindFile.V_T2,OceanFile.Lon,OceanFile.Lat);
        % Rotate wind grid
        [WindFile.U_T1, WindFile.V_T1] = rotangle(WindFile.U_T1, WindFile.V_T1);
        [WindFile.U_T2, WindFile.V_T2] = rotangle(WindFile.U_T2, WindFile.V_T2);
    else
        % Rename and read wind VectorFields from the next file
        flag_one = floor((ts-2)*LagrTimeStep.BTW_windsTS);
        flag_two = floor((ts-1)*LagrTimeStep.BTW_windsTS);
        if flag_one ~= flag_two
            aux_num = floor(2 + (ts-1) * LagrTimeStep.BTW_windsTS);
            if aux_num == 5
                readWindFileT2 = [WindFile.Prefix,year_str,num2str(day_DoY+1),'_1',WindFile.Sufix];
            else
                readWindFileT2 = [WindFile.Prefix,year_str,num2str(day_DoY),'_',num2str(aux_num),WindFile.Sufix];
            end
            WindFile.U_T1 = WindFile.U_T2;
            WindFile.V_T1 = WindFile.V_T2;
            WindFile.U_T2 = ncread(readWindFileT2,WindFile.Uname,...
                [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
            WindFile.V_T2 = ncread(readWindFileT2,WindFile.Vname,...
                [WindFile.Lat_min,WindFile.Lon_min],[WindFile.Lat_numel,WindFile.Lon_numel]);
            % Interp wind grid T2 to ocean grid
            WindFile.U_T2   = interp2(WindFile.Lon,WindFile.Lat,WindFile.U_T2,OceanFile.Lon,OceanFile.Lat);
            WindFile.V_T2   = interp2(WindFile.Lon,WindFile.Lat,WindFile.V_T2,OceanFile.Lon,OceanFile.Lat);
            % Rotate wind grid T2
            [WindFile.U_T2, WindFile.V_T2] = rotangle(WindFile.U_T2, WindFile.V_T2);
        end
    end
end
%--------------Interp VectorFields (temporal interpolation)---------------%
time_dif = (ts-1) * LagrTimeStep.InHrs;
% Ocean
% Velocities for current time-step
ocean_U_factor = (OceanFile.U_T2 - OceanFile.U_T1) ./ OceanFile.timeStep_hrs;
ocean_V_factor = (OceanFile.V_T2 - OceanFile.V_T1) ./ OceanFile.timeStep_hrs;
velocities.Uts1 = OceanFile.U_T1 + time_dif .* ocean_U_factor;
velocities.Vts1 = OceanFile.V_T1 + time_dif .* ocean_V_factor;
% Velocities for next time-step
TimeDiff_plus_TS = time_dif + LagrTimeStep.InHrs;
velocities.Uts2 = OceanFile.U_T1 + TimeDiff_plus_TS .* ocean_U_factor;
velocities.Vts2 = OceanFile.V_T1 + TimeDiff_plus_TS .* ocean_V_factor;
if surface_simulation
    % Wind
    % Velocities for current time-step
    wind_U_factor = (WindFile.U_T2 - WindFile.U_T1) ./ WindFile.timeStep_hrs;
    wind_V_factor = (WindFile.V_T2 - WindFile.V_T1) ./ WindFile.timeStep_hrs;
    wind_Uts1     = WindFile.U_T1 + time_dif .* wind_U_factor;
    wind_Vts1     = WindFile.V_T1 + time_dif .* wind_V_factor;
    % Velocities for next time-step
    wind_Uts2 = WindFile.U_T1 + TimeDiff_plus_TS .* wind_U_factor;
    wind_Vts2 = WindFile.V_T1 + TimeDiff_plus_TS .* wind_V_factor;
    %-------------------------Add wind to 0 m layer-------------------------%
    layer_0m = find(spillLocation.Depths == 0);
    velocities.Uts1(:,:,layer_0m) = velocities.Uts1(:,:,layer_0m) + wind_Uts1 * Params.windcontrib;
    velocities.Vts1(:,:,layer_0m) = velocities.Vts1(:,:,layer_0m) + wind_Vts1 * Params.windcontrib;
    velocities.Uts2(:,:,layer_0m) = velocities.Uts2(:,:,layer_0m) + wind_Uts2 * Params.windcontrib;
    velocities.Vts2(:,:,layer_0m) = velocities.Vts2(:,:,layer_0m) + wind_Vts2 * Params.windcontrib;
end
end
