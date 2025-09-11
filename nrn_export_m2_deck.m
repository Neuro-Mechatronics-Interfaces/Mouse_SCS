%NRN_EXPORT_M2_DECK To keep from forgetting how to run M2 stim-frequency sweeps.
close all force;
clear;
clc;

% run_neuron_simulation("m2"); % Uncomment to launch NEURON sim from
                               % MATLAB; BEWARE- it deletes the folder
                               % containing prior simulation export results
                               % before running to avoid using old study
                               % results.
[sweep_data, simdata] = load_plot_export_simulations('m2');