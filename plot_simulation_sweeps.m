function fig = plot_simulation_sweeps(simdata, options)
%PLOT_SIMULATION_SWEEPS  Frequency–Recruitment sweeps by Diam × M2 (fallback: Leak × M2).
%
% Inputs:
%   simdata : table with columns at least:
%             [SeqAbbr, SweepBase, SweepName, Blending_Level, Frequency, PostSynapticRate,
%              M2_Level, Diam (preferred) or Leak (legacy)]
%   options.SeqColors : containers.Map (SeqAbbr -> RGB row)
%   options.MarkerMap : containers.Map (SweepBase -> marker symbol)
%   options.LineWidth : scalar

arguments
    simdata table
    options.SeqColors = containers.Map({'E3','IIE','IEI'}, {[0.77 0.07 0.19],[0.02 0.21 0.45],[0 0.59 0.28]})
    options.MarkerMap = containers.Map({'Constant','Increasing','Decreasing','Custom'}, {'o','+','s','x'})
    options.LineWidth (1,1) double = 1.5
end

% ---- Choose sweep axis: prefer Diam, fall back to Leak ----
useDiam = ismember('Diam', simdata.Properties.VariableNames);
rowName = 'Diam';
if ~useDiam
    if ~ismember('Leak', simdata.Properties.VariableNames)
        error('simdata must have either a Diam or Leak column.');
    end
    rowName = 'Leak';
end

uM2   = unique(simdata.M2_Level);
uRow  = unique(simdata.(rowName));

fig = figure('Name','Sweep Frequency–Recruitment Curves', ...
    'Color','w','Units','inches','Position',[2 2 10 5]);
L = tiledlayout(fig, numel(uRow), numel(uM2), ...
    'TileSpacing','compact','Padding','compact');

axAll = gobjects(0);
h = [];

for iRow = 1:numel(uRow)
  for iM2 = 1:numel(uM2)
    mask = (simdata.M2_Level == uM2(iM2)) & (simdata.(rowName) == uRow(iRow));
    S = simdata(mask,:);
    ax = nexttile(L); ax.NextPlot = 'add'; ax.FontName = 'Arial';
    xlabel(ax,'Pre-Synaptic AP Arrival Rate (Hz)','FontName','Arial','FontSize',8);
    ylabel(ax,'Post-Synaptic MUAP Rate (Hz)','FontName','Arial','FontSize',8);

    if isempty(S); axAll(end+1) = ax; continue; end %#ok<AGROW>

    % Stable order of sequences
    uSeq = unique(S.SeqAbbr,'stable');
    for s = 1:numel(uSeq)
        seq = uSeq(s);
        baseColor = options.SeqColors(seq);
        % Colors split by blending level
        uBlend = unique(S.Blending_Level);
        % cm.umap should be provided by caller (same as your original)
        cmapSeq = cm.umap(baseColor, numel(uBlend)+4);
        cmapSeq = cmapSeq(3:(end-1),:);
        for b = 1:numel(uBlend)
            Sblend = S(S.SeqAbbr==seq & S.Blending_Level==uBlend(b),:);
            if isempty(Sblend); continue; end
            base = string(Sblend.SweepBase(1));
            if isKey(options.MarkerMap, base)
                mk = options.MarkerMap(base);
            else
                mk = 'o';
            end
            [freq,idx] = sort(Sblend.Frequency,'ascend');
            rate = Sblend.PostSynapticRate(idx);
            if iRow==1 && iM2==1
                legName = sprintf("%s: %s", Sblend.SeqAbbr(1), Sblend.SweepName{1});
                h = [h; plot(ax, freq ./ 3, rate, ...
                    'Color', cmapSeq(b,:), ...
                    'LineWidth', options.LineWidth, ...
                    'Marker', mk, ...
                    'DisplayName', legName)]; %#ok<AGROW>
            else
                g = plot(ax, freq ./ 3, rate, ...
                    'Color', cmapSeq(b,:), ...
                    'LineWidth', options.LineWidth, ...
                    'Marker', mk, ...
                    'DisplayName', Sblend.SweepName{1});
                g.Annotation.LegendInformation.IconDisplayStyle = 'off';
            end
        end
    end

    axAll(end+1) = ax; %#ok<AGROW>
  end
end

% Big labels summarizing the sweep values
xlabel(L, sprintf("M2 (%s)", strjoin(string(sort(uM2,'ascend'))," | ")), ...
    'FontName','Arial','FontWeight','bold');
ylabel(L, sprintf("%s (%s)", rowName, strjoin(string(sort(uRow,'descend'))," | ")), ...
    'FontName','Arial','FontWeight','bold');

% Legend once, outside
lgd = legend(h, 'Location','northoutside','Interpreter','none','Orientation','horizontal');
lgd.Layout.Tile = 'north';

% Link XY axes across all tiles
linkaxes(axAll,'xy');
end
