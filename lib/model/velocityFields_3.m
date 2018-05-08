function [velocities,WindFile,OceanFile] = velocityFields_1(...
  first_time,SerialDay,ts,LagrTimeStep,spillLocation,OceanFile,WindFile,Params)
date_time = datetime(SerialDay,'ConvertFrom','datenum');
day_DoY = day(date_time,'dayofyear');
year_str = datestr(date_time,'yyyy_');
%--------------------------Get wind VectorFields--------------------------%
  if first_time
    % Wind file names and varible names
    WindFile.Prefix       = 'WRF_';
    WindFile.Sufix        = '.mat';
    WindFile.Uname        = 'U_';
    WindFile.Vname        = 'V_';
    WindFile.Coord        = 'cordenadasHycom.mat' 
    
    % Define variables
    coordFile = load(WindFile.Coord, '-mat')
    lat_W = coordFile.Latitude;
    lon_W = coordFile.Longitude;
    WindFile.Lat_min = find(lat_W <= Params.domainLimits(3),1,'last');
    WindFile.Lat_max = find(lat_W >= Params.domainLimits(4),1,'first');
    WindFile.Lon_min = find(lon_W <= Params.domainLimits(1),1,'last');
    WindFile.Lon_max = find(lon_W >= Params.domainLimits(2),1,'first');
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
    end
  end
end
%--------------Interp VectorFields (temporal interpolation)---------------%
time_dif = (ts-1) * LagrTimeStep.InHrs;

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