function fig = plotResponseSnippets(t, snips, channel, options)
%PLOTRESPONSESNIPPETS  Plot snippet response squiggles
%
% Syntax:
%   fig = plotResponseSnippets(t, snips, channel, 'Name', Value, ...);
arguments
    t (1,:) double
    snips (:, :, :) double
    channel (1,:) {mustBePositive, mustBeInteger}
    options.Subject {mustBeTextScalar} = "Unknown";
    options.Year (1,1) double = year(today);
    options.Month (1,1) double = month(today);
    options.Day (1,1) double = day(today);
    options.Sweep (1,1) double {mustBeInteger} = 0;
    options.Block (1,1) double {mustBeInteger} = 0;
    options.Title {mustBeTextScalar} = "";
    options.Subtitle {mustBeTextScalar} = "";
    options.XLabel {mustBeTextScalar} = "";
    options.YLabel {mustBeTextScalar} = "";
    options.YOffset (1,1) double = 35;
    options.CMapData = [];
end

fig = figure('Color', 'w', 'Name', 'Response Snippet Examples');
L = tiledlayout(fig, 'flow');
nResponses = size(snips,3);
yOffset = 0:options.YOffset:(options.YOffset*(nResponses-1));
if isempty(options.CMapData)
    cdata = jet(numel(channel));
else
    cdata = options.CMapData;
end

for iCh = 1:numel(channel)
    ax = nexttile(L);
    set(ax,'NextPlot','add',...
        'XLim',[t(1), t(end)], ...
        'YLim',[-options.YOffset, options.YOffset*nResponses], ...
        'FontName','Tahoma','XColor','k','YColor','none');
    plot(ax, t, squeeze(snips(:,channel(iCh),:))+yOffset, 'Color', cdata(iCh,:));
    title(ax, sprintf('CH-%03d', channel(iCh)), 'FontName','Consolas','Color',cdata(iCh,:));
end

if strlength(options.Title) > 0
    title(L, options.Title, ...
        'FontName','Tahoma','Color','k');
else
    title(L, sprintf('%s: %04d-%02d-%02d | Sweep-%d | Block-%d', ...
        options.Subject, options.Year, options.Month, options.Day, options.Sweep, options.Block), ...
        'FontName','Tahoma','Color','k');
end
if strlength(options.Subtitle) > 0
    subtitle(L, options.Subtitle, ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end
if strlength(options.XLabel) > 0
    xlabel(L, options.XLabel, 'FontName','Tahoma','Color','k');
end
if strlength(options.YLabel) > 0
    ylabel(L, options.YLabel, 'FontName','Tahoma','Color','k');
end
end