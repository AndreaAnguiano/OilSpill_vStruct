<<<< El documento se lee mejor con la ventana maximizada >>>>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Este software se desarrolló por el Grupo de Interación Océano-Atmósfera del CCA, UNAM. %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% http://grupo-ioa.atmosfera.unam.mx/ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Contenido:

- graphical_interface.m ==> Rutina principal para ejecutar el modelo en modo gráfico.

- graphical_interface.fig ==> Archivo binario con la figura de la interfáz gráfica.

- main_BP_50p1.m ==> Rutina principal para ejecutar la simulación del derrame BP en modo programático.

- main_Usumacinta.m ==> Rutina principal para ejecutar la simulación del derrame Usumacinta en modo programático.

- local_paths_BP_50p1.m ==> Indica los directorios de entrada para ejecutar la simulación del derrame BP.

- local_paths_Usumacinta.m ==> Indica los directorios de entrada para ejecutar la simulación del derrame Usumacinta.

- docs ==> Contiene la guia de usuario y una presentacion relacionada al modelo.

- data ==> Contiene dos batimetrias (.mat y .nc) y un archivo CSV con datos del derrame BP.

- lib ==> Contiene las rutinas (.m) para ejecutar el modelo
    - external ==> Rutinas ajenas para guardar figuras (export_fig).
    - model ==> Rutinas principales del modelo.
    - plotting ==> Rutinas para leer batimetrias (get_bathymetry) y graficar mapas (map_particles) y estadisticas (plotStats)
    - tools ==> Rutinas mas pequeñas (secundarias) utilizadas por las rutinas principales.
