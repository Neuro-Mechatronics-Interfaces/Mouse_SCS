function fig = plot_simulation_sweeps(sweep_data, options)
%PLOT_SIMULATION_SWEEPS  Plots simulation sweep data from NEURON M2 simulations.
arguments
    sweep_data table % See example_load_plot_export_m2_simulations.m
    options.SubSweepOrder (1,:) string = ["Constant", "Increasing", "Up-Down", "Decreasing"];
end
uM2 = unique(sweep_data.M2_Level);
nM2 = numel(uM2);
uLeak = unique(sweep_data.Leak);
nLeak = numel(uLeak);
fig = figure(...
    'Name', 'M2 All Sweep Frequency-Recruitment Curves', ...
    'Color', 'w', ...
    'Units', 'inches', ...
    'Position', [2 2 10 6]);
L = tiledlayout(fig, nLeak, nM2);
nSubSweep = numel(options.SubSweepOrder);

for iLeak = 1:nLeak
    for iM2 = 1:nM2
        s = sweep_data((sweep_data.M2_Level == uM2(iM2)) & (sweep_data.Leak==uLeak(iLeak)),:);
        if size(s,1)~=nSubSweep
            error("Number of sub-sweep table rows should equal the qualitative labels in SubSweepOrder option.");
        end
        ax = nexttile(L);
        set(ax,'NextPlot','add','FontName','Tahoma');
        for ii = 1:size(s,1)
            plot(ax,s.Sweep{ii}.Frequency,s.Sweep{ii}.Rate,...
                'DisplayName', options.SubSweepOrder{ii});
        end
        ylabel(ax,'PostSynaptic AP Rate (Hz)', 'FontName','Tahoma','Color','k');
        xlabel(ax,'PreSynaptic AP Rate (Hz)', 'FontName','Tahoma','Color','k');
        if (iLeak == 1) && (iM2 == 1)
            legend(ax,'Location','best');
        end
    end
end
sM2 = strjoin(string(num2str(uM2))," | ");
sLeak = strjoin(string(num2str(flipud(reshape(uLeak,[],1)))), " | ");
xlabel(L,sprintf('M2 Modulation Level (%s)',sM2), 'FontName','Tahoma','FontWeight','bold','Color','k');
ylabel(L,sprintf('Leak Level (%s) ℧/cm^2', sLeak), 'FontName','Tahoma','FontWeight','bold','Color','k');
end