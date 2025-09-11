%NRN_PLOT_FI_CURVES Script showing how to plot F-I curves and associated time-voltage/time-concentration plots.
%
% To run/re-run associated simulations (assuming NEURON is installed at
%   "C:/nrn/bin", the default on Windows):
%   
% ```(bat)
%   cd NEURON/MotorNeuron
%   call C:/nrn/bin/nrniv.exe -nobanner -nogui main_m2_amplitude_sweep.hoc
% ```
%
% Note that you can also set the `show_traces_plot` and other flags to `1`
% inside the `.hoc` file if you want to see the traces as the simulation
% runs, but this makes it take longer and I couldn't figure out exactly how
% to make the window layout nice with the arcane hoc syntax.

clear;
close all force;
clc;

simresults_folder = fullfile(pwd,"NEURON", "MotorNeuron","out_m2qa");
export_folder = "G:\Shared drives\NML_MetaWB_sandbox\Results\Simulations\PBR";

[fig,T] = plot_fi_curves(simresults_folder);
utils.save_figure(fig(1),export_folder, ...
    'NEURON F-I Sweeps - Diameter M2 tau_ca', ...
    'ExportAs', {'.png', '.svg'}, 'SaveFigure', true);
utils.save_figure(fig(2),export_folder, ...
    'NEURON F-I Sweeps - Diameter M2 tau_ca - MaxFR Time-Voltage and Time-Concentration Ca', ...
    'ExportAs', {'.png', '.svg'}, 'SaveFigure', true);
writetable(T, fullfile(export_folder,"FI_Sweep_Data.csv"));

utils.print_windows_folder_link(export_folder,"Saved figures and table here.");