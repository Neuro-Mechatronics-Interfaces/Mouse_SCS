function fig = plot_saga_recruitment_raw(T, saga, channel, options)

arguments
    T
    saga
    channel
    options.SampleRate = 4000;
    options.Tag {mustBeTextScalar} = "SAGA";
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
    data = zscore(saga(ii).samples(channel,:));
    t = (0:(numel(data)-1)) / options.SampleRate;
    plot(ax, t, data);
    
end
title(L, sprintf('Sweep %d | %s | Channel-%d', T.sweep(1), options.Tag, channel), ...
    'FontName', 'Tahoma', 'Color', 'k');
end