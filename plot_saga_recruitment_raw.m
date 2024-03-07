function fig = plot_saga_recruitment_raw(T, saga, channel, options)

arguments
    T
    saga
    channel
    options.SampleRate = 4000;
    options.Tag {mustBeTextScalar} = "SAGA";
    options.TriggerChannel (1,1) double {mustBePositive, mustBeInteger} = 73;
    options.SyncBit (1,1) double {mustBeInteger} = 12;
    options.Fc (1,:) double = 5;
    options.YLim (1,2) double = [-40 40]; % microamps
end

if numel(options.Fc) == 1
    [b,a] = butter(2,options.Fc/(options.SampleRate/2),'high');
    applyFilter = true;
elseif numel(options.Fc) == 2
    [b,a] = butter(2,options.Fc./(options.SampleRate/2), 'bandpass');
    applyFilter = true;
else
    applyFilter = false;

end

[~,idx] = sort(abs(T.intensity), 'ascend');
saga = saga(idx);
T = T(idx,:);

N = numel(saga);

fig = figure('Color', 'w', 'Name', 'Recruitment Curve');
L = tiledlayout(fig, ceil(N/2), 2);

for ii = 1:N
    ax = nexttile(L, ii, [1 1]);
    set(ax, 'NextPlot', 'add', 'FontName', 'Tahoma');
    if applyFilter
        data = filter(b,a,saga(ii).samples(channel,:));
    else
        data = saga(ii).samples(channel,:);
    end
    t = (0:(numel(data)-1)) / options.SampleRate;
    yyaxis(ax, 'left');
    plot(ax, t, data);
    title(ax, sprintf('%d \\muA', abs(T.intensity(ii))), 'FontName', 'Tahoma', 'Color', 'k');
    ylim(ax, options.YLim);
    yyaxis(ax, 'right');
    plot(ax, t, bitand(saga(ii).samples(options.TriggerChannel,:),2^options.SyncBit)==0);
end
title(L, sprintf('Sweep %d | %s | Channel-%d', T.sweep(1), options.Tag, channel), ...
    'FontName', 'Tahoma', 'Color', 'k');
linkaxes(findobj(L.Children,'Type','axes'),'xy');
end