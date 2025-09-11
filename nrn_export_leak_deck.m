%NRN_EXPORT_LEAK_DECK To keep from forgetting how to run LEAK stim-frequency sweeps.
close all force;
clear;
clc;

% run_neuron_simulation("leak"); % Uncomment to launch NEURON sim from
                                 % MATLAB; BEWARE- it deletes the folder
                                 % containing prior simulation export results
                                 % before running to avoid using old study
                                 % results.
[sweep_data, simdata] = load_plot_export_simulations('leak');