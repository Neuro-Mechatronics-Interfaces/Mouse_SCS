function fig = plot_simulations(simdata,options)
%PLOT_SIMULATIONS  Plots simulations from NEURON MOTONEURON_M2 model.
arguments
    simdata
    options.FigureOptions cell = {};
    options.InitialOffset (1,1) double = 50; % ms
    options.SimulationDuration (1,1) double = 1000; % ms
    options.XLim (1,2) double = [25, 250]; % ms
    options.BaseGKRectValue (1,1) double = 0.3;
end
[G,m2_level] = findgroups(simdata.M2_Level);
fig = gobjects(numel(m2_level),1);
for ik = 1:numel(m2_level)
    s = simdata(G == ik,:);
    fig(ik) = figure('Name','Simulation Data', ...
        'Color','w', ...
        'Units','inches',...
        'Position',[1 1 9 6.5], ...
        'UserData', struct('M2_Level', m2_level(ik)), ...
        options.FigureOptions{:});
    L = tiledlayout(fig(ik),'flow');
    for ii = 1:size(s,1)
        ax = nexttile(L);
        set(ax,'NextPlot','add','FontName','Tahoma');
        tPeriod = 1000/s.Frequency(ii);
        tStim = options.InitialOffset:tPeriod:(options.InitialOffset+options.SimulationDuration);
        xline(ax,tStim(1:min(s.Frequency(ii),numel(tStim))),'r:');
        plot(ax, s.Time{ii}, s.Voltage{ii},'Color','k');
        title(ax, sprintf('%d-Hz',s.Frequency(ii)), 'FontName','Tahoma','Color','k');
        xlim(ax,options.XLim);
    end
    xlabel(L,'Time (ms)','FontName','Tahoma','Color','k');
    ylabel(L,'Amplitude (mV)','FontName','Tahoma','Color','k');
    title(L,sprintf("m2 modulation: %0.2f", m2_level(ik)), 'FontName','Tahoma','Color','k','FontWeight','bold');
    subtitle(L, sprintf('(g_{k,rect} = %5.3f mho/cm^2)', m2_level(ik)*options.BaseGKRectValue), ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end

end