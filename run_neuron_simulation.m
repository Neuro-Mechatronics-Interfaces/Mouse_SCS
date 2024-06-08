function run_neuron_simulation(sim_name, options)
%RUN_NEURON_SIMULATION  Run the NEURON simulation from MATLAB. 
%
% Syntax:
%   run_neuron_simulation();
%   run_neuron_simulation('sim_name.hoc');
%   run_neuron_simulation('sim_name.hoc','Name', value, ...);
%
% Options:
%   'SimulationFolder' = fullfile(pwd,"NEURON/MotorNeuron");
%   'TERMINAL_COMMAND' = "C:\Windows\System32\cmd.exe /c";
%   'NEURON_HOME' = "C:/nrn/bin"; 
%
% See also: example_load_plot_export_m2_simulations.m

arguments
    sim_name {mustBeTextScalar} = 'main_m2_freq_sweep.hoc';
    options.SimulationFolder = fullfile(pwd,"NEURON/MotorNeuron");
    options.TERMINAL_COMMAND = "C:\Windows\System32\cmd.exe /c";
    options.NEURON_HOME = "C:/nrn/bin";
end
nrn_home = strrep(options.NEURON_HOME,"\","/");
sim_folder = strrep(options.SimulationFolder,"\","/");
[root_folder,~,~] = fileparts(sim_folder);
str_to_execute = sprintf("%s/nrniv.bat %s %s %s", root_folder, sim_folder, sim_name, nrn_home);
str_for_terminal = sprintf('%s "%s"', options.TERMINAL_COMMAND, str_to_execute);
simulation_tic = tic;
system(str_for_terminal);
toc(simulation_tic);

end