function [fig, TID] = plot_simulations(simdata, options)
%PLOT_SIMULATIONS  Plots simulations from NEURON MOTONEURON_M2 model.

arguments
    simdata
    options.FigureOptions cell = {}
    options.InitialOffset (1,1) double = 50     % ms
    options.SimulationDuration (1,1) double = 1000 % ms
    options.XLim (1,2) double = [25, 700]       % ms
    options.YLim (1,2) double = [-100, 60]
    options.BaseGKRectValue (1,1) double = 0.3
    options.APThreshold (1,1) double = 10      % mV
    options.PulseType = {'r--', 'r--', 'r--'}   % per-synapse line styles
    options.XUnits {mustBeTextScalar} = 'ms'
    options.YUnits {mustBeTextScalar} = 'mV'
end

[G, TID] = findgroups(simdata(:, ["M2_Level", "Diam", "SweepBase", "SweepName"]));
TID.Sweep = cell(size(TID,1),1);
TID.Blending_Level = zeros(size(TID,1),1);

fig = gobjects(size(TID,1),1);

for ik = 1:size(TID,1)
    s = simdata(G == ik, :);

    uBlend = unique(s.Blending_Level);
    if numel(uBlend) > 1, blend_this = uBlend(1); else, blend_this = uBlend; end
    TID.Blending_Level(ik) = blend_this;
    TID.Sweep{ik} = s(:, ["Frequency", "PreSynapticRate", "PostSynapticRate"]);

    fig(ik) = figure('Name','Simulation Data','Color','w','Units','inches', ...
        'Position',[1 1 9 6.5], ...
        'UserData', struct('M2_Level', TID.M2_Level(ik), ...
                           'Diam', TID.Diam(ik), ...
                           'Blending_Level', TID.Blending_Level(ik), ...
                           'SweepName', TID.SweepName(ik)), ...
        options.FigureOptions{:});
    L = tiledlayout(fig(ik), 'flow');

    for ii = 1:size(s,1)
        ax = nexttile(L);
        set(ax, 'NextPlot','add', 'FontName','Tahoma', 'XColor','none', 'YColor','none');

        % Stim marks (3 interleaved)
        tPeriod = 1000 / s.Frequency(ii);
        tStim = sort([ ...
            options.InitialOffset : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration), ...
            options.InitialOffset + (tPeriod)   : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration), ...
            options.InitialOffset + (2*tPeriod) : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration) ...
        ], 'ascend');

        xline(ax, tStim(1:3:min(s.Frequency(ii), numel(tStim))), options.PulseType{1});
        t2 = tStim(2:3:min(s.Frequency(ii), numel(tStim)));
        if ~isempty(t2), xline(ax, t2, options.PulseType{2}); end
        t3 = tStim(3:3:min(s.Frequency(ii), numel(tStim)));
        if ~isempty(t3), xline(ax, t3, options.PulseType{3}); end

        % Trace
        plot(ax, s.Time{ii}, s.Voltage{ii}, 'Color','k');

        % Title per tile with CoV_ISI
        covStr = 'n/a';
        if ~isnan(s.CoV_ISI(ii))
            covStr = sprintf('%.2f', s.CoV_ISI(ii));
        end
        smolTitle = sprintf('%.1f-Hz → %.1f-Hz | CoV_{ISI}=%s', ...
            round(s.PreSynapticRate(ii),1), round(s.PostSynapticRate(ii),1), covStr);
        title(ax, smolTitle, 'FontName','Tahoma', 'Color','k');

        xlim(ax, options.XLim);
        ylim(ax, options.YLim);
        plot.add_scale_bar(ax, 25, -100, 75, -70, 'XUnits', options.XUnits, 'YUnits', options.YUnits);
    end

    title(L, sprintf("%s | diam: %g \\mum | m2: %gx | blending: %g", ...
            TID.SweepName(ik), TID.Diam(ik), TID.M2_Level(ik), TID.Blending_Level(ik)), ...
        'FontName','Tahoma', 'Color','k', 'FontWeight','bold');

    subtitle(L, sprintf('(g_{k,rect} = %g ℧/cm^2)', TID.M2_Level(ik) * options.BaseGKRectValue), ...
        'FontName','Tahoma', 'Color', [0.65 0.65 0.65]);
end

end
