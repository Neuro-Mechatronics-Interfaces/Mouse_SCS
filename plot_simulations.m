function fig = plot_simulations(simdata,options)
%PLOT_SIMULATIONS  Plots simulations from NEURON MOTONEURON_M2 model.
arguments
    simdata
    options.FigureOptions cell = {};
    options.InitialOffset (1,1) double = 50; % ms
    options.SimulationDuration (1,1) double = 1000; % ms
    options.XLim (1,2) double = [25, 300]; % ms
    options.BaseGKRectValue (1,1) double = 0.3;
    options.APThreshold (1,1) double = -10; % mV
    options.XUnits {mustBeTextScalar} = 'ms';
    options.YUnits {mustBeTextScalar} = 'mV';
end
[G,TID] = findgroups(simdata(:,["M2_Level", "Leak"]));
fig = gobjects(size(TID,1),1);
effective_period = options.SimulationDuration*1e-3; % seconds
for ik = 1:size(TID,1)
    s = simdata(G == ik,:);
    fig(ik) = figure('Name','Simulation Data', ...
        'Color','w', ...
        'Units','inches',...
        'Position',[1 1 9 6.5], ...
        'UserData', struct('M2_Level', TID.M2_Level(ik), 'Leak', TID.Leak(ik)), ...
        options.FigureOptions{:});
    L = tiledlayout(fig(ik),'flow');
    for ii = 1:size(s,1)
        ax = nexttile(L);
        set(ax,'NextPlot','add','FontName','Tahoma');
        tPeriod = 1000/s.Frequency(ii);
        tStim = options.InitialOffset:tPeriod:(options.InitialOffset+options.SimulationDuration);
        pks = findpeaks(s.Voltage{ii},'MinPeakHeight',options.APThreshold);
        n = numel(pks);
        rate = round(n / effective_period);
        xline(ax,tStim(1:min(s.Frequency(ii),numel(tStim))),'r:');
        plot(ax, s.Time{ii}, s.Voltage{ii},'Color','k');
        title(ax, sprintf('%d-Hz → %d-Hz',s.Frequency(ii),rate), 'FontName','Tahoma','Color','k');
        xlim(ax,options.XLim);
    end
    xlabel(L,sprintf('Time (%s)',options.XUnits),'FontName','Tahoma','Color','k');
    ylabel(L,sprintf('Amplitude (%s)',options.YUnits),'FontName','Tahoma','Color','k');
    title(L,sprintf("leak conductance: %g ℧/cm^2 | m2 modulation: %gx", TID.Leak(ik), TID.M2_Level(ik)), 'FontName','Tahoma','Color','k','FontWeight','bold');
    subtitle(L, sprintf('(g_{k,rect} = %g ℧/cm^2)', m2_level(ik)*options.BaseGKRectValue), ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end

end