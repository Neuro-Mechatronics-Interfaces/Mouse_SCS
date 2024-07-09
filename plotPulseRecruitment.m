function fig = plotPulseRecruitment(intensity, frequency, channel, T, response, options)
%PLOTPULSERECRUITMENT  Plot recruitment curve by fixed intensity/frequency, as function of pulse index.
arguments
    intensity (1,1) double
    frequency (1,1) double
    channel (1,1) {mustBePositive, mustBeInteger}
    T
    response
    options.ChannelName {mustBeTextScalar} = "";
    options.CData (1,3) {mustBeInRange(options.CData,0,1)} = [0 0 0];
    options.Marker {mustBeMember(options.Marker, {'o','.','s','h','*'})} = 'o';
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.75;
end
iMatch = find(T.intensity==intensity & T.frequency==frequency,1,'first');
if isempty(iMatch)
    warning('No %d-μA & %d-Hz experiment in this sweep.', intensity, frequency);
    fig = [];
    return;
end

fig = figure('Color','w','Name',sprintf('Recruitment by Pulse Index: %dμA at %d-Hz', intensity, frequency));
ax = axes(fig,'NextPlot','add','FontName','Tahoma','FontSize',14');
data = response{iMatch}(:,channel);
maxPulse = T.n_pulses(iMatch);
for ii = 1:maxPulse
    scatter(ax, ii, data(ii:maxPulse:end), ...
        'Marker', options.Marker, ...
        'MarkerFaceAlpha', options.Alpha, ...
        'MarkerEdgeAlpha', options.Alpha, ...
        'MarkerEdgeColor',options.CData,...
        'MarkerFaceColor',options.CData);
end
xlabel(ax,'Pulse Index', 'FontName','Tahoma','Color','k');
ylabel(ax,'Peak-to-Peak Amplitude (μV)','FontName','Tahoma','Color','k');
if strlength(options.ChannelName) > 0
    title(ax, sprintf('%s Recruitment by Pulse:', options.ChannelName), ...
        sprintf('%dμA at %d-Hz', intensity, frequency), ...
        'FontName','Tahoma','Color','k','FontSize',16,'FontWeight','bold');
else
    title(ax, 'Recruitment by Pulse:', ...
        sprintf('%dμA at %d-Hz', intensity, frequency), ...
        'FontName','Tahoma','Color','k','FontSize',16,'FontWeight','bold');
end

end