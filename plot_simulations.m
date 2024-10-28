function [fig, TID] = plot_simulations(simdata,options)
%PLOT_SIMULATIONS  Plots simulations from NEURON MOTONEURON_M2 model.
arguments
    simdata
    options.FigureOptions cell = {};
    options.InitialOffset (1,1) double = 50; % ms
    options.SimulationDuration (1,1) double = 1000; % ms
    options.XLim (1,2) double = [25, 350]; % ms
    options.YLim (1,2) double = [-100, 60]; 
    options.BaseGKRectValue (1,1) double = 0.3;
    options.APThreshold (1,1) double = -10; % mV
    options.PulseType = {'b-.', 'b-.', 'r--'};
    options.XUnits {mustBeTextScalar} = 'ms';
    options.YUnits {mustBeTextScalar} = 'mV';
end
[G,TID] = findgroups(simdata(:,["M2_Level", "Leak", "Blending_Level"]));
TID.Sweep = cell(size(TID,1),1);
fig = gobjects(size(TID,1),1);
effective_period = options.SimulationDuration*1e-3; % seconds
for ik = 1:size(TID,1)
    s = simdata(G == ik,:);
    s.Rate = nan(size(s,1),1);
    TID.Sweep{ik} = s(:,["Frequency", "Rate"]);
    fig(ik) = figure('Name','Simulation Data', ...
        'Color','w', ...
        'Units','inches',...
        'Position',[1 1 9 6.5], ...
        'UserData', struct('M2_Level', TID.M2_Level(ik), 'Leak', TID.Leak(ik), 'Blending_Level', TID.Blending_Level(ik)), ...
        options.FigureOptions{:});
    L = tiledlayout(fig(ik),'flow');
    for ii = 1:size(s,1)
        ax = nexttile(L);
        set(ax,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none');
        tPeriod = 1000/s.Frequency(ii);
        tStim = sort([...
            options.InitialOffset:(tPeriod*9):(options.InitialOffset+options.SimulationDuration), ...
            options.InitialOffset+(tPeriod):(tPeriod*9):(options.InitialOffset+options.SimulationDuration), ...
            options.InitialOffset+(2*tPeriod):(tPeriod*9):(options.InitialOffset+options.SimulationDuration)],'ascend');
        pks = findpeaks(s.Voltage{ii},'MinPeakHeight',options.APThreshold);
        n = numel(pks);
        TID.Sweep{ik}.Rate(ii) = round(n / effective_period);
        xline(ax,tStim(1:3:min(s.Frequency(ii),numel(tStim))),options.PulseType{1});
        t2 = tStim(2:3:min(s.Frequency(ii),numel(tStim)));
        if ~isempty(t2)
            xline(ax,t2,options.PulseType{2});
        end
        t3 = tStim(3:3:min(s.Frequency(ii),numel(tStim)));
        if ~isempty(t3)
            xline(ax,t3,options.PulseType{3});
        end
        plot(ax, s.Time{ii}, s.Voltage{ii},'Color','k');
        title(ax, sprintf('%d-Hz → %d-Hz',s.Frequency(ii),TID.Sweep{ik}.Rate(ii)), 'FontName','Tahoma','Color','k');
        xlim(ax,options.XLim);
        ylim(ax,options.YLim);
        plot.add_scale_bar(ax, 25, -100, 75, -70, 'XUnits', options.XUnits, 'YUnits', options.YUnits);
    end
    % xlabel(L,sprintf('Time (%s)',options.XUnits),'FontName','Tahoma','Color','k');
    % ylabel(L,sprintf('Amplitude (%s)',options.YUnits),'FontName','Tahoma','Color','k');
    title(L,sprintf("leak conductance: %g ℧/cm^2 | m2 modulation: %gx | blending: %g", TID.Leak(ik), TID.M2_Level(ik), TID.Blending_Level(ik)), 'FontName','Tahoma','Color','k','FontWeight','bold');
    subtitle(L, sprintf('(g_{k,rect} = %g ℧/cm^2)', TID.M2_Level(ik)*options.BaseGKRectValue), ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end

end