function fig = plot_simulation_sweeps(simdata, options)
%PLOT_SIMULATION_SWEEPS  Frequency–Recruitment sweeps by Leak × M2.
%
%   fig = plot_simulation_sweeps(simdata)
%   fig = plot_simulation_sweeps(simdata, options)
%
% Inputs:
%   simdata : table with columns [M2_Level, Leak, SeqAbbr, SweepBase,
%                                 SweepName, Blending_Level, Sweep]
%   cm      : colormap object with method umap(baseColor, N)
%   options : struct (optional)
%       .SeqColors   containers.Map (SeqAbbr -> RGB row)
%       .MarkerMap   containers.Map (SweepBase -> marker symbol)
%       .LineWidth   scalar (default 1.5)
%
% Example:
%   seqColors = containers.Map({'E3','IIE'}, {[0.77 0.07 0.19],[0.02 0.21 0.45]});
%   markerMap = containers.Map({'Constant','Increasing','Decreasing','Custom'}, {'o','+','s','x'});
%   plot_simulation_sweeps(simdata, cm, struct('SeqColors',seqColors,'MarkerMap',markerMap));

arguments
    simdata table
    options.SeqColors = containers.Map({'E3','IIE','IEI'}, {[0.77 0.07 0.19],[0.02 0.21 0.45],[0 0.59 0.28]})
    options.MarkerMap = containers.Map({'Constant','Increasing','Decreasing','Custom'}, {'o','+','s','x'})
    options.LineWidth (1,1) double = 1.5
end

uM2   = unique(simdata.M2_Level);
uLeak = unique(simdata.Leak);

fig = figure('Name','Sweep Frequency–Recruitment Curves', ...
    'Color','w','Units','inches','Position',[2 2 10 5]);
L = tiledlayout(fig, numel(uLeak), numel(uM2), ...
    'TileSpacing','compact','Padding','compact');

axAll = gobjects(0);
h = [];
for iLeak = 1:numel(uLeak)
  for iM2 = 1:numel(uM2)
    mask = (simdata.M2_Level == uM2(iM2)) & (simdata.Leak == uLeak(iLeak));
    S = simdata(mask,:);
    ax = nexttile(L); ax.NextPlot = 'add'; ax.FontName = 'Arial';
    xlabel(ax,'Pre-Synaptic AP Arrival Rate (Hz)','FontName','Arial','FontSize',8);
    ylabel(ax,'Post-Synaptic MUAP Rate (Hz)','FontName','Arial','FontSize',8);

    % Stable order of sequences
    uSeq = unique(S.SeqAbbr,'stable');
    for s = 1:numel(uSeq)
        seq = uSeq(s);
        baseColor = options.SeqColors(seq);
        % Colors split by blending level
        uBlend = unique(S.Blending_Level);
        cmapSeq = cm.umap(baseColor, numel(uBlend)+4);
        cmapSeq = cmapSeq(3:(end-1),:);
        for b = 1:numel(uBlend)
            Sblend = S(S.SeqAbbr==seq & S.Blending_Level==uBlend(b),:);
            base = string(Sblend.SweepBase(1));
            if isKey(options.MarkerMap, base)
                mk = options.MarkerMap(base);
            else
                mk = 'o';
            end
            [freq,idx] = sort(Sblend.Frequency,'ascend');
            rate = Sblend.PostSynapticRate(idx);
            if iLeak==1 && iM2==1
                legName = sprintf("%s: %s", Sblend.SeqAbbr(1), Sblend.SweepName{1});
                h = [h; plot(ax, freq, rate, ...
                    'Color', cmapSeq(b,:), ...
                    'LineWidth', options.LineWidth, ...
                    'Marker', mk, ...
                    'DisplayName', legName)]; %#ok<AGROW>
            else
                g = plot(ax, freq, rate, ...
                    'Color', cmapSeq(b,:), ...
                    'LineWidth', options.LineWidth, ...
                    'Marker', mk, ...
                    'DisplayName', Sblend.SweepName{1});
                g.Annotation.LegendInformation.IconDisplayStyle = 'off';
            end
        end
    end

    % title(ax, sprintf('Leak = %g | M2 = %g', uLeak(iLeak), uM2(iM2)));
    axAll(end+1) = ax; %#ok<AGROW>
  end
end

xlabel(L, sprintf("M2 (%s)", strjoin(string(sort(uM2,'ascend'))," | ")),'FontName','Arial','FontWeight','bold');
ylabel(L, sprintf("Leak (%s)", strjoin(string(sort(uLeak,'descend'))," | ")),'FontName','Arial','FontWeight','bold');
% Legend once, outside
lgd = legend(h, 'Location','northoutside','Interpreter','none','Orientation','horizontal');
lgd.Layout.Tile = 'north';

% Link XY axes across all tiles
linkaxes(axAll,'xy');

end
