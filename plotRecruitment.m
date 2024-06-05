function fig = plotRecruitment(T, response_data, channel, channel_name, options)
%PLOTRECRUITMENT Plot recruitment summary figure
%
% Syntax:
%   fig = plotRecruitment(T, response_data, channel, channel_name);
%
% Inputs:
%   T - Table of sweep metadata from loadData
%   response_data - Can be either the normalized or raw responses
%   channel - The channel index to plot
%   channel_name - The name (muscle) for the channel to be plotted. Should
%                       have same number of elements as `channel`.

arguments
    T table % Table with sweep metadata from loadData.
    response_data (:, 1) % Either: intan, saga.A, or saga.B (as returned by loadData)
    channel (1,1) {mustBeInteger}
    channel_name (1,1) {mustBeTextScalar}
    options.Color (1,3) double {mustBeInRange(options.Color,0,1)} = [0 0 0];
    options.LineWidth (1,1) double = 2;
end

if size(T,1) ~= size(response_data,1)
    error("Must have same number of table rows as data structure elements.");
end

[~,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
% r = groot;
% x0 = r.MonitorPositions(1,1);
% y0 = r.MonitorPositions(1,2)+round(0.25*r.MonitorPositions(1,4));
% h = round(r.MonitorPositions(1,4)/2);
% w = round(r.MonitorPositions(1,3)/size(TID,1))-20;
fig = gobjects(size(TID,1),1);
mu = cellfun(@(C)mean(C(:,channel)),response_data);
sigma = cellfun(@(C)std(C(:,channel)),response_data);
for iT = 1:size(TID,1)
    fig(iT) = figure('Name',sprintf('Channel-%02d (%s) Recruitment Curve: %d-Hz',channel,channel_name,TID.frequency(iT)), ...
        'Color','w',...
        ...'Units','pixels',...
        ...'Position',[x0+(iT-1)*(w+20), y0, w, h], ...
        'Units','inches', ...
        'Position', [0 0 9 6.5], ...
        'UserData', struct('Channel',""));
    ax = axes(fig(iT),'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
    Tsub = sortrows(T(T.frequency == TID.frequency(iT),:),'intensity','ascend');
    
    errorbar(ax, Tsub.intensity, mu(Tsub.block+1), sigma(Tsub.block+1), ...
        'LineWidth',options.LineWidth, ...
        'Color', options.Color);
    xlabel(ax,'Amplitude (\muA)','FontName','Tahoma','Color','k');
    ylabel(ax,'E[Response] (\muV)', 'FontName','Tahoma','Color','k');
    axTxt = sprintf('%s Recruitment Curve: %d-Hz',channel_name,TID.frequency(iT));
    title(ax,axTxt, 'FontName','Tahoma','Color','k');
    fig(iT).UserData.Channel = axTxt;
    fig(iT).UserData.Frequency = TID.frequency(iT);
end

end