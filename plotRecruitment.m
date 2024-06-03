function fig = plotRecruitment(T, response_normed, channel, channel_name)
%PLOTRECRUITMENT Plot recruitment summary figure

arguments
    T table % Table with sweep metadata from loadData.
    response_normed (:, 1) % Either: intan, saga.A, or saga.B (as returned by loadData)
    channel
    channel_name
end

if size(T,1) ~= size(response_normed,1)
    error("Must have same number of table rows as data structure elements.");
end

[~,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
r = groot;
x0 = r.MonitorPositions(1,1);
y0 = r.MonitorPositions(1,2)+round(0.25*r.MonitorPositions(1,4));
h = round(r.MonitorPositions(1,4)/2);
w = round(r.MonitorPositions(1,3)/size(TID,1))-20;
fig = gobjects(size(TID,1),1);
mu = cellfun(@(C)mean(C(:,channel)),response_normed);
sigma = cellfun(@(C)std(C(:,channel)),response_normed);
for iT = 1:size(TID,1)
    fig(iT) = figure('Name',sprintf('Channel-%02d (%s) Recruitment Curve: %d-Hz',channel,channel_name,TID.frequency(iT)), ...
        'Color','w','Units','pixels',...
        'Position',[x0+(iT-1)*(w+20), y0, w, h]);
    ax = axes(fig(iT),'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
    Tsub = sortrows(T(T.frequency == TID.frequency(iT),:),'intensity','ascend');
    
    
    errorbar(ax, Tsub.intensity, mu(Tsub.block+1), sigma(Tsub.block+1));
    xlabel(ax,'Amplitude (\muA)','FontName','Tahoma','Color','k');
    ylabel(ax,'E[Response] (\muV)', 'FontName','Tahoma','Color','k');
    title(ax,sprintf('%s Recruitment Curve: %d-Hz',channel_name,TID.frequency(iT)))
end

end