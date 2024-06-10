function [fig, cdata] = plotResponseSnippets(t, snips, channel, T, options)
%PLOTRESPONSESNIPPETS  Plot snippet response squiggles
%
% Syntax:
%   fig = plotResponseSnippets(t, snips, channel, T, 'Name', Value, ...);
arguments
    t (1,:) double
    snips
    channel (1,:) {mustBePositive, mustBeInteger}
    T table % Table as returned by loadData
    options.Subject {mustBeTextScalar} = "Unknown";
    options.Year (1,1) double = year(today);
    options.Month (1,1) double = month(today);
    options.Day (1,1) double = day(today);
    options.Sweep (1,1) double {mustBeInteger} = 0;
    options.Title {mustBeTextScalar} = "";
    options.Subtitle {mustBeTextScalar} = "";
    options.XLabel {mustBeTextScalar} = "";
    options.YLabel {mustBeTextScalar} = "";
    options.YOffset (1,1) double = 2500;
    options.CMapData = [];
    options.Muscle (:,1) string = ""
end
if isempty(options.CMapData)
    cdata = copper(numel(channel));
else
    cdata = options.CMapData;
end
[~,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
fig = gobjects(size(TID,1),1);
for iT = 1:size(TID,1)
    fig(iT) = figure('Color', 'w', 'Name', 'Response Snippet Examples', ...
        'Units', 'inches', ...
        'Position', [0.5 0.5 10 5.75], ...
        'UserData', struct('Title', "", 'Subtitle', "", 'Frequency', []));
    L = tiledlayout(fig(iT), 'flow');
    Tsub = sortrows(T(T.frequency == TID.frequency(iT),:),'intensity','ascend');
    index = Tsub.block+1;
%     index = Tsub.block;
    snip_data = cat(3,snips{index});
    n_snips = cellfun(@(C)size(C,3),snips(index));
    nResponses = size(snip_data,3);
    yOffset = 0:options.YOffset:(options.YOffset*(nResponses-1));
    

    for iCh = 1:numel(channel)
        ax = nexttile(L);
        [G_intensity,uG] = findgroups(Tsub.intensity);
        G_intensity = repelem(G_intensity,n_snips,1);
        if rem(numel(uG),2)==1
            nCol = numel(uG)+8;
        else
            nCol = numel(uG)+9; 
        end
        cdata_cur = flipud(cm.umap(cdata(iCh,:),nCol));
        cdata_cur([1,2,(end-3):end],:) = [];
        cdata_cur = double(cdata_cur(G_intensity,:))./255.0;
        set(ax,'NextPlot','add',...
            'XLim',[t(1), t(end)], ...
            'YLim',[-options.YOffset, options.YOffset*(nResponses+2)], ...
            'ColorOrder', cdata_cur, ...
            'FontName','Tahoma','XColor','k','YColor','none');
        plot(ax, t, squeeze(snip_data(:,channel(iCh),:))+yOffset);
        if numel(options.Muscle) == numel(channel)
            title(ax, options.Muscle(iCh), 'FontName','Consolas','Color',cdata(iCh,:));
        else
            title(ax, sprintf('CH-%03d', channel(iCh)), 'FontName','Consolas','Color',cdata(iCh,:));
        end
    end

    if strlength(options.Title) > 0
        title(L, options.Title, ...
            'FontName','Tahoma','Color','k');
        fig(iT).UserData.Title = options.Title;
    else

        txt = sprintf('%s: %04d-%02d-%02d | Sweep-%d', ...
            full_subj_name_2_short_name(options.Subject), options.Year, options.Month, options.Day, options.Sweep);
        title(L, txt, ...
            'FontName','Tahoma','Color','k');
        fig(iT).UserData.Title = txt;
    end
    if strlength(options.Subtitle) > 0
        subtitle(L, options.Subtitle, ...
            'FontName','Tahoma','Color',[0.65 0.65 0.65]);
        fig(iT).UserData.Subtitle = options.Subtitle;
    else
        subtxt = sprintf('%d-Hz (%d\\muA - %d\\muA)',TID.frequency(iT),Tsub.intensity(1),Tsub.intensity(end));
        subtitle(L,subtxt, ...
            'FontName','Tahoma','Color',[0.65 0.65 0.65]);
        fig(iT).UserData.Subtitle = subtxt;
    end
    if strlength(options.XLabel) > 0
        xlabel(L, options.XLabel, 'FontName','Tahoma','Color','k');
    end
    if strlength(options.YLabel) > 0
        ylabel(L, options.YLabel, 'FontName','Tahoma','Color','k');
    end
    fig(iT).UserData.Frequency = TID.frequency(iT);
end

end