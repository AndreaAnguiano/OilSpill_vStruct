% Function to make sure that the Lagrangian_time_step is correct
function LagrTimeStepInHrs = correct_LagrTimeStepHrs(LagrTimeStepInHrs,OceanFileTimeStep,WindFileTimeStep)
% Check Lagrangian_time_step <= VectorFields_time_step
min_timestep = min([OceanFileTimeStep;WindFileTimeStep]);
if LagrTimeStepInHrs > min_timestep
  LagrTimeStepInHrs = min_timestep;
  warning(['The Lagrangian time step was changed to ',num2str(LagrTimeStepInHrs),' h'])
end
% Verify that the Lagrangian time step is a divisor of 24 h
if rem(24,LagrTimeStepInHrs) ~= 0
  serie = 0:.01:LagrTimeStepInHrs; % 0.01 h = 0.6 min = 36 s
  possible_timesteps = serie(rem(24,serie)==0);
  LagrTimeStepInHrs = possible_timesteps(end);
  warning(['The Lagrangian time step was changed to ',num2str(LagrTimeStepInHrs),' h'])
end
end