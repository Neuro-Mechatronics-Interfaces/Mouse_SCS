%NRN_PLOT_EPSP_CURVES  Related to simulation in `epsp_rate_current_clamp_sweep.hoc`

E = load_epsp_sweeps(); 
R = readtable("NEURON/MotorNeuron/out_epsp/results.tsv",'FileType','text','Delimiter','tab');

fig = plot_epsp_results(E); 
utils.save_figure(fig,"G:\Shared drives\NML_MetaWB_sandbox\Results\Simulations\PBR", ...
    "EPSP-Rate_and_Current-Clamp_CoV_ISI",'ExportAs',{'.png','.svg'},'SaveFigure',true); 