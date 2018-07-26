function [vMap3D,vMap2D,Map_fig3D,Map_fig2D,ensemble_grid] = map_particles(...
    outputFolder,ts,first_time,final_time,spillLocation,Particles,vis_maps,Dcomp,...
    saving,ensemble_grid,vMap3D,vMap2D,Map_fig3D,Map_fig2D,dateHour_str,Params)
    % This function is in charge of plotting everthing

%---- Plot the base map if it is the first day and the firs time step ----%
if first_time
    set(0,'DefaultFigureVisible',vis_maps.visible);
    % Get the bathymetry
    [lon_bathy,lat_bathy,depth_bathy] = get_bathymetry(vis_maps);
    % Plot 3D base map
    if vis_maps.threeDim
        Map_fig3D = figure;
        surf(lon_bathy,lat_bathy,depth_bathy);shading flat
        axis(vis_maps.boundaries)
        view(vis_maps.threeDim_angles)
        min_bathy = min(min(min(depth_bathy)));
        min_lim_bathy = max([vis_maps.boundaries(5);min_bathy]);
        caxis([min_lim_bathy, vis_maps.boundaries(6)])
        set(gca,'ZTickLabel',[]);
        box('on')
        set(gca,'BoxStyle','full')
        YTL = get(gca,'YTickLabel');
        for element = 1:numel(YTL)
            YTL{element} = [YTL{element},' °N'];
        end
        set(gca,'YTickLabel',YTL)
        XTL = get(gca,'XTickLabel');
        for element = 1:numel(XTL)
            XTL{element} = [XTL{element}(2:end),' °O'];
        end
        set(gca,'XTickLabel',XTL)
        hold on
        contour3(lon_bathy,lat_bathy,depth_bathy,vis_maps.isobaths,'k','linewidth',2)
        colormap(vis_maps.cmap)
        hcb = colorbar;
        ylabel(hcb,'Profundidad (m)')
        set(Map_fig3D,'color','w','resize','off')
        set(gca,'FontSize',vis_maps.fontSize)
        set(Map_fig3D,'units','centimeters','Position',vis_maps.figPosition)
        set(gca,'units','centimeters','Position',vis_maps.axesPosition)
        if saving.MapsVideo_on
            vMap3D = VideoWriter([outputFolder.MapsVideo,'3D.avi']);
            vMap3D.FrameRate = saving.MapsVideo_framesPerSecond;
            vMap3D.Quality   = saving.MapsVideo_quality;
            open(vMap3D);
        end
    end
    % Plot 2D base maps
    if vis_maps.twoDim
        Map_fig2D = figure;
        pcolor(lon_bathy,lat_bathy,depth_bathy);shading flat
        axis(vis_maps.boundaries(1:4))
        view([0,90])
        xlabel('Longitud')
        ylabel('Latitud')
        hold on
        contour(lon_bathy,lat_bathy,depth_bathy,vis_maps.isobaths,'k','linewidth',2)
        colormap(vis_maps.cmap)
        hcb = colorbar;
        min_lim_bathy = min(min(min(depth_bathy)));
        caxis([min_lim_bathy, vis_maps.boundaries(6)])
        ylabel(hcb,'Profundidad (m)')
        set(Map_fig2D,'color','w','resize','off')
        set(gca,'FontSize',vis_maps.fontSize)
        set(Map_fig2D,'units','centimeters','Position',vis_maps.figPosition)
        set(gca,'units','centimeters','Position',vis_maps.axesPosition)
        if saving.MapsVideo_on
            for depth_cicle = 1:spillLocation.n_Depths
                vMap2D(depth_cicle) = VideoWriter([outputFolder.MapsVideo,...
                    num2str(spillLocation.Depths(depth_cicle)),'m.avi']);
                vMap2D(depth_cicle).FrameRate = saving.MapsVideo_framesPerSecond;
                vMap2D(depth_cicle).Quality   = saving.MapsVideo_quality;
                open(vMap2D(depth_cicle));
            end
            vMap2D(spillLocation.n_Depths+1) = VideoWriter([outputFolder.MapsVideo,...
                'Ensembles.avi']);
            vMap2D(spillLocation.n_Depths+1).FrameRate = saving.MapsVideo_framesPerSecond;
            vMap2D(spillLocation.n_Depths+1).Quality   = saving.MapsVideo_quality;
            open(vMap2D(spillLocation.n_Depths+1));
            vMap2D(spillLocation.n_Depths+2) = VideoWriter([outputFolder.MapsVideo,...
                'Coast.avi']);
            vMap2D(spillLocation.n_Depths+2).FrameRate = saving.MapsVideo_framesPerSecond;
            vMap2D(spillLocation.n_Depths+2).Quality   = saving.MapsVideo_quality;
            open(vMap2D(spillLocation.n_Depths+2));
        end
        % Used by ensemble maps
        ensemble_grid.lat = vis_maps.boundaries(4):-km2deg(5):vis_maps.boundaries(3);
        ensemble_grid.lon = vis_maps.boundaries(1):km2deg(5):vis_maps.boundaries(2);
        ensemble_grid.count = nan(numel(ensemble_grid.lat),numel(ensemble_grid.lon),...
            spillLocation.n_Depths,Params.components_number);
    end
end
%------------------------ Plot particles position ------------------------%
% 3D plot
if vis_maps.threeDim
    set(0,'currentfigure',Map_fig3D);
    h_del = findobj(Map_fig3D,'type','line');
    delete(h_del)
    % Title
    img_name = ['(3D) ',dateHour_str];
    title(img_name)
    % plot particles in land
    InLand = find(Particles.Status == 2);
    InLand_H = plot3(Particles.Lon(InLand),Particles.Lat(InLand),-Particles.Depth(InLand),...
        '.','color',vis_maps.colors_InLand,'MarkerSize',vis_maps.markerSize+0);
    uistack(InLand_H,'down',1)
    % Plot particles in water
    for depth_cicle = 1 : spillLocation.n_Depths
        depth_ind = find(Particles.Status == 1 & ...
            Particles.Depth == spillLocation.Depths(depth_cicle));
        plot3(Particles.Lon(depth_ind),Particles.Lat(depth_ind),...
            -Particles.Depth(depth_ind),'.','color',...
            vis_maps.colors_ByDepth(depth_cicle),'MarkerSize',vis_maps.markerSize)
    end
    % Plot spill location
    plot3(zeros(1,spillLocation.n_Depths)+spillLocation.Lon,...
        zeros(1,spillLocation.n_Depths)+spillLocation.Lat,-spillLocation.Depths,...
        's','color',vis_maps.colors_SpillLocation,'MarkerSize',vis_maps.markerSize)
    % Visualize
    if strcmp(vis_maps.visible,'on') && ...
            (rem(ts,vis_maps.visible_step_ts) == 0 || first_time)
        pause(0.5)
    end
    % Save image
    if saving.MapsImage_on && (rem(ts,saving.MapsImage_step_ts) == 0 || ...
            first_time || final_time)
        img_name = strrep(img_name,' ','_');
        img_name = regexprep(img_name,'[()]','');
        export_fig(Map_fig3D,[outputFolder.MapsImage,img_name],'-png','-nocrop',...
            saving.MapsImage_quality)
    end
    % Save video
    if saving.MapsVideo_on && (rem(ts,saving.MapsVideo_step_ts) == 0 || ...
            first_time || final_time)
        drawnow
        frame = getframe(Map_fig3D);
        writeVideo(vMap3D, frame);
        if final_time
            close(vMap3D);
        end
    end
end
% 2D plot
if vis_maps.twoDim
    set(0,'currentfigure',Map_fig2D);
    for depth_cicle = 1:spillLocation.n_Depths
        h_del = findobj(Map_fig2D,'type','line');
        delete(h_del)
        % Title
        currentDepth = spillLocation.Depths(depth_cicle);
        currentDepth_str = num2str(currentDepth);
        img_sufix = ['(',currentDepth_str,' m) '];
        img_name = [img_sufix,dateHour_str];
        title(img_name)
        % plot particles in land
        InLand = find(Particles.Status == 2 & Particles.Depth == currentDepth);
        InLand_H = plot(Particles.Lon(InLand),Particles.Lat(InLand),...
            '.','color',vis_maps.colors_InLand,'MarkerSize',vis_maps.markerSize+0);
        uistack(InLand_H,'down',1)
        % plot particles in water
        for comp_cicle = Params.components_number:-1:1
            depthComp_ind = find(Particles.Status == 1 & ...
                Particles.Depth == currentDepth & Particles.Comp == comp_cicle);
            plot(Particles.Lon(depthComp_ind),Particles.Lat(depthComp_ind),'.','color',...
                vis_maps.colors_ByComponent{comp_cicle},'MarkerSize',vis_maps.markerSize)
            % Counting for ensemble maps
            for parts_cicle = depthComp_ind
                lat_idx = find(ensemble_grid.lat <= Particles.Lat(parts_cicle),1,'first');
                lon_idx = find(ensemble_grid.lon <= Particles.Lon(parts_cicle),1,'last');
                ensemble_grid.count(lat_idx,lon_idx,depth_cicle,comp_cicle) = ...
                    nansum([ensemble_grid.count(lat_idx,lon_idx,depth_cicle,comp_cicle);1]);
            end
        end
        % Plot spill location
        plot(spillLocation.Lon,spillLocation.Lat,'s','color',vis_maps.colors_SpillLocation,...
            'MarkerSize',vis_maps.markerSize)
        % Visualize
        if strcmp(vis_maps.visible,'on') && ...
                (rem(ts,vis_maps.visible_step_ts) == 0 || first_time)
            pause(0.5)
        end
        % Save image
        if saving.MapsImage_on && ...
                (rem(ts,saving.MapsImage_step_ts) == 0 || first_time || final_time)
            img_name = strrep(img_name,' ','_');
            img_name = regexprep(img_name,'[()]','');
            export_fig(Map_fig2D,[outputFolder.MapsImage,img_name],...
                '-png','-nocrop',saving.MapsImage_quality)
        end
        % Save video
        if saving.MapsVideo_on && ...
                (rem(ts,saving.MapsVideo_step_ts) == 0 || first_time || final_time)
            drawnow;
            frame = getframe(Map_fig2D);
            writeVideo(vMap2D(depth_cicle), frame);
        end
    end
end
if final_time && vis_maps.twoDim
    %---------------------------- Ensemble maps ----------------------------%
    % Plot base ensemble map
    ensembleMaps = figure;
    [lon_bathy,lat_bathy,depth_bathy] = get_bathymetry(vis_maps);
    contour(lon_bathy,lat_bathy,depth_bathy,vis_maps.isobaths,'k','linewidth',2)
    axis(vis_maps.boundaries(1:4))
    view([0,90])
    xlabel('Longitud')
    ylabel('Latitud')
    c_map = hsv(100);
    colormap(c_map(6:end,:))
    hcb = colorbar;
    ylabel(hcb,'Numero de posiciones')
    set(ensembleMaps,'color','w','resize','off')
    set(gca,'FontSize',vis_maps.fontSize)
    set(ensembleMaps,'units','centimeters','Position',vis_maps.figPosition)
    set(gca,'units','centimeters','Position',vis_maps.axesPosition)
    hold on
    for depth_cicle = 1:spillLocation.n_Depths
        max_val = max(max(max(ensemble_grid.count(:,:,depth_cicle,:),[],4)));
        caxis([1,max_val*.02])
        for comp_cicle = 1:Params.components_number
            img_name = [num2str(spillLocation.Depths(depth_cicle)),...
                ' m, Componente ',num2str(comp_cicle)];
            title(img_name)
            hpc = pcolor(ensemble_grid.lon,ensemble_grid.lat,...
                ensemble_grid.count(:,:,depth_cicle,comp_cicle)); shading flat;
            uistack(hpc,'bottom')
            % Save image
            if saving.MapsImage_on
                img_name = strrep(img_name,' ','_');
                img_name = strrep(img_name,',','');
                export_fig(ensembleMaps,[outputFolder.MapsImage,img_name],...
                    '-png','-nocrop',saving.MapsImage_quality)
            end
            % Save video
            if saving.MapsVideo_on
                drawnow;
                frame = getframe(ensembleMaps);
                if depth_cicle == 1 && comp_cicle == 1
                    [frame_height,frame_width,~] = size(frame.cdata);
                else
                    [frame_height_B,frame_width_B,~] = size(frame.cdata);
                    dif_height = frame_height - frame_height_B;
                    dif_width = frame_width - frame_width_B;
                    if dif_height < 0
                        frame.cdata(1:abs(dif_height),:,:) = [];
                    elseif dif_height > 0
                        frame.cdata = [frame.cdata;ones(abs(dif_height),frame_width_B,3)];
                    end
                    if dif_width < 0
                        frame.cdata(:,1:abs(dif_width),:) = [];
                    elseif dif_width > 0
                        frame.cdata = [frame.cdata,ones(size(frame.cdata,1),abs(dif_width),3)];
                    end
                end
                writeVideo(vMap2D(spillLocation.n_Depths+1),frame);
            end
            delete(hpc)
        end
        if saving.MapsVideo_on
            close(vMap2D(depth_cicle));
        end
    end
    if saving.MapsVideo_on
        close(vMap2D(spillLocation.n_Depths+1));
    end
    %----------------------------- Coast maps ------------------------------%
    coast_grid.lat = vis_maps.boundaries(4):-mtr2deg(8000,spillLocation.Lat,'lat_deg',Dcomp):vis_maps.boundaries(3);
    coast_grid.lon = vis_maps.boundaries(1):mtr2deg(8000,spillLocation.Lat,'lon_deg',Dcomp):vis_maps.boundaries(2);
    coast_grid.count = nan(numel(coast_grid.lat),numel(coast_grid.lon),spillLocation.n_Depths);
    ylabel(hcb,'Barriles')
    for depth_cicle = 1:spillLocation.n_Depths
        InCoast = find(Particles.Status == 2 & Particles.Depth == spillLocation.Depths(depth_cicle));
        for parts_cicle = InCoast
            lat_idx = find(coast_grid.lat <= Particles.Lat(parts_cicle),1,'first');
            lon_idx = find(coast_grid.lon <= Particles.Lon(parts_cicle),1,'last');
            coast_grid.count(lat_idx,lon_idx,depth_cicle) = ...
                nansum([coast_grid.count(lat_idx,lon_idx,depth_cicle);1]);
        end
        barrelsInCoast = coast_grid.count(:,:,depth_cicle)/Params.particlesPerBarrel;
        hpc = pcolor(coast_grid.lon,coast_grid.lat,barrelsInCoast); shading flat;
        c_min = min(min(barrelsInCoast));
        c_max = max(max(barrelsInCoast));
        if c_max > c_min
            caxis([c_min,c_max])
        else
            caxis('auto')
        end
        img_name = ['Costa ',num2str(spillLocation.Depths(depth_cicle)),' m'];
        title(img_name)
        % Save image
        if saving.MapsImage_on
            img_name = strrep(img_name,' ','_');
            export_fig(ensembleMaps,[outputFolder.MapsImage,img_name],...
                '-png','-nocrop',saving.MapsImage_quality)
        end
        % Save video
        if saving.MapsVideo_on
            drawnow;
            frame = getframe(ensembleMaps);
            writeVideo(vMap2D(spillLocation.n_Depths+2),frame);
        end
        if depth_cicle == spillLocation.n_Depths
            if saving.MapsVideo_on
                close(vMap2D(spillLocation.n_Depths+2))
            end
        else
            delete(hpc)
        end
    end
end
end
