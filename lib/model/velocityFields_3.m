function [velocities,WindFile,OceanFile] = velocityFields_3(...
  first_time,SerialDay,ts,LagrTimeStep,spillLocation,OceanFile,WindFile,Params)
date_time = datetime(SerialDay,'ConvertFrom','datenum');
day_DoY = day(date_time,'dayofyear');
year_str = datestr(date_time,'yyyy');
month_MoY = month(date_time, 'monthofyear');
%--------------------------Get wind VectorFields--------------------------%
  if first_time
    % Wind file names and varible names
    WindFile.Prefix       = 'wrfout_c3h_d01_';
    WindFile.Sufix        = strcat('_00_00_00_',yeart_str, '.nc');
    WindFile.Uname        = 'U';
    WindFile.Vname        = 'V';
    WindFile.Wname        = 'W';
    WindFile.CoorPrefix   = 'wrfout_c15d_d01_';
    WindFile.HeigthName      = 'ZNU'
    % Define variables
    firstFileName = [WindFile.Prefix,year_str,'-',num2str(month_MoY, '%02d'),'-',num2str(day_DoM,'%02d'),WindFileSufix];
    coordFileName = [WindFile.CoordPrefix,year_str,'-',num2str(month_MoY, '%02d'),'-',num2str(day_DoM,'%02d'),WindFileSufix];
    Ulat_W = double(ncread(coordFileName, 'XLAT_U'));
    Vlat_W = double(ncread(coordFileName, 'XLAT_V'));
    Ulon_W =double(ncread(coordFileName, 'XLONG_U'));
    Vlon_W = double(ncread(coordFileName, 'XLONG_V'));
    WindFile.ULat_min = find(lat_W <= Params.domainLimits(3),1,'last');
    WindFile.VLat_min = find(lat_W <= Params.domainLimits(3),1,'last');
    WindFile.ULat_max = find(lat_W >= Params.domainLimits(4),1,'first');
    WindFile.VLat_max = find(lat_W >= Params.domainLimits(4),1,'first');
    WindFile.ULon_min = find(lat_W <= Params.domainLimits(3),1,'last');
    WindFile.VLon_min = find(lat_W <= Params.domainLimits(3),1,'last');
    WindFile.ULon_max = find(lat_W >= Params.domainLimits(4),1,'first');
    WindFile.VLon_max = find(lat_W >= Params.domainLimits(4),1,'first');
    Ulat_W = Ulat_W(WindFile.ULat_min:WindFile.ULat_max);
    Ulon_W = Ulon_W(WindFile.ULon_min:WindFile.ULon_max);
    Vlat_W = Vlat_W(WindFile.VLat_min:WindFile.VLat_max);
    Vlon_W = Vlon_W(WindFile.VLon_min:WindFile.VLon_max);

    WindFile.ULat_numel = numel(Ulat_W);
    WindFile.ULon_numel = numel(Ulon_W);
    
    WindFile.VLat_numel = numel(Vlat_W);
    WindFile.VLon_numel = numel(Vlon_W);
    
    [WindFile.ULon,WindFile.ULat] = meshgrid(Ulon_W,Ulat_W);
    [WindFile.VLon,WindFile.VLat] = meshgrid(Vlon_W,Vlat_W);
    
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