function [fig, TID] = plot_simulations(simdata, options)
%PLOT_SIMULATIONS  Plots simulations from NEURON MOTONEURON_M2 model.

arguments
    simdata
    options.FigureOptions cell = {};
    options.InitialOffset (1,1) double = 50;    % ms
    options.SimulationDuration (1,1) double = 1000; % ms
    options.XLim (1,2) double = [25, 350];      % ms
    options.YLim (1,2) double = [-100, 60];
    options.BaseGKRectValue (1,1) double = 0.3;
    options.APThreshold (1,1) double = -10;     % mV
    options.PulseType = {'r--', 'r--', 'r--'};  % per-synapse line styles
    options.XUnits {mustBeTextScalar} = 'ms';
    options.YUnits {mustBeTextScalar} = 'mV';
end

% Group by M2, Leak, and the human-readable sweep label (e.g., "Constant
% (20% blending)") | SweepBase is simply more general grouping level than
% SweepName. 
[G, TID] = findgroups(simdata(:, ["M2_Level", "Leak", "SweepBase", "SweepName"]));

% We'll fill these per-group
TID.Sweep = cell(size(TID,1),1);
TID.Blending_Level = zeros(size(TID,1),1);  % derived per group for titles/UserData

fig = gobjects(size(TID,1),1);

for ik = 1:size(TID,1)
    s = simdata(G == ik, :);

    % Derive the blending level for this group (should be unique if SweepName encodes blend)
    uBlend = unique(s.Blending_Level);
    if numel(uBlend) > 1
        % Mixed blends inside one SweepName shouldn't happen, but be graceful.
        % Take the first so titles/UserData are still populated.
        blend_this = uBlend(1);
    else
        blend_this = uBlend;
    end
    TID.Blending_Level(ik) = blend_this;
    TID.Sweep{ik} = s(:, ["Frequency", "PreSynapticRate", "PostSynapticRate"]);

    % Figure for this group
    fig(ik) = figure('Name', 'Simulation Data', ...
        'Color', 'w', ...
        'Units', 'inches', ...
        'Position', [1 1 9 6.5], ...
        'UserData', struct('M2_Level', TID.M2_Level(ik), ...
                           'Leak', TID.Leak(ik), ...
                           'Blending_Level', TID.Blending_Level(ik), ...
                           'SweepName', TID.SweepName(ik)), ...
        options.FigureOptions{:});
    L = tiledlayout(fig(ik), 'flow');

    for ii = 1:size(s,1)
        ax = nexttile(L);
        set(ax, 'NextPlot','add', 'FontName','Tahoma', 'XColor','none', 'YColor','none');

        % Stim marks (same logic you had)
        tPeriod = 1000 / s.Frequency(ii);
        tStim = sort([ ...
            options.InitialOffset : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration), ...
            options.InitialOffset + (tPeriod)   : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration), ...
            options.InitialOffset + (2*tPeriod) : (tPeriod*9) : (options.InitialOffset + options.SimulationDuration) ...
        ], 'ascend');

        % Pulse markers by synapse
        xline(ax, tStim(1:3:min(s.Frequency(ii), numel(tStim))), options.PulseType{1});
        t2 = tStim(2:3:min(s.Frequency(ii), numel(tStim)));
        if ~isempty(t2)
            xline(ax, t2, options.PulseType{2});
        end
        t3 = tStim(3:3:min(s.Frequency(ii), numel(tStim)));
        if ~isempty(t3)
            xline(ax, t3, options.PulseType{3});
        end

        % Trace
        plot(ax, s.Time{ii}, s.Voltage{ii}, 'Color','k');

        % Small title per tile
        smolTitle = sprintf('%.1f-Hz → %.1f-Hz', round(s.PreSynapticRate(ii),1), round(s.PostSynapticRate(ii),1));
        title(ax, smolTitle, 'FontName','Tahoma', 'Color','k');

        xlim(ax, options.XLim);
        ylim(ax, options.YLim);
        plot.add_scale_bar(ax, 25, -100, 75, -70, 'XUnits', options.XUnits, 'YUnits', options.YUnits);
    end

    % Big title per group; use your human-readable sweep label directly
    title(L, sprintf("%s | leak: %g ℧/cm^2 | m2: %gx | blending: %g", ...
            TID.SweepName(ik), TID.Leak(ik), TID.M2_Level(ik), TID.Blending_Level(ik)), ...
        'FontName','Tahoma', 'Color','k', 'FontWeight','bold');

    subtitle(L, sprintf('(g_{k,rect} = %g ℧/cm^2)', TID.M2_Level(ik) * options.BaseGKRectValue), ...
        'FontName','Tahoma', 'Color', [0.65 0.65 0.65]);
end

end
