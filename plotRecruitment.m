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
    options.SweepVariable {mustBeTextScalar} = "";
end

if size(T,1) ~= size(response_data,1)
    error("Must have same number of table rows as data structure elements.");
end

if strlength(options.SweepVariable) < 1
    uIntensity = unique(T.intensity);
    uFrequency = unique(T.frequency);
    if numel(uFrequency) > numel(uIntensity)
        [~,TID] = findgroups(T(:,["intensity","pulse_width","channel"]));
        sweepVar = 'frequency';
        groupVar = 'intensity';
    else
        [~,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
        sweepVar = 'intensity';
        groupVar = 'frequency';
    end
else
    sweepVar = options.SweepVariable;
    switch sweepVar
        case 'frequency'
            [~,TID] = findgroups(T(:,["intensity","pulse_width","channel"]));
            sweepVar = 'frequency';
            groupVar = 'intensity';
        case 'intensity'
            [~,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
            sweepVar = 'intensity';
            groupVar = 'frequency';
        otherwise
            error("Not configured to use %s as SweepVariable.", sweepVar);
    end
end
fig = gobjects(size(TID,1),1);
mu = cellfun(@(C)mean(C(:,channel)),response_data);
sigma = cellfun(@(C)std(C(:,channel)),response_data);
for iT = 1:size(TID,1)
    switch groupVar
        case 'intensity'
            gName = sprintf('%d-μA',TID.intensity(iT));
        case 'frequency'
            gName = sprintf('%d-Hz', TID.frequency(iT));
    end
    fig(iT) = figure('Name',sprintf('Channel-%02d (%s) Recruitment Curve: %s',channel,channel_name,gName), ...
        'Color','w',...
        'Units','inches', ...
        'Position', [0 0 9 6.5], ...
        'UserData', struct('Channel',""));
    ax = axes(fig(iT),'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
    Tsub = sortrows(T(T.(groupVar) == TID.(groupVar)(iT),:),'intensity','ascend');
    
    errorbar(ax, Tsub.(sweepVar), mu(Tsub.block+1), sigma(Tsub.block+1), ...
        'LineWidth',options.LineWidth, ...
        'Color', options.Color);
    switch sweepVar
        case 'intensity'
            xlabel(ax,'Amplitude (μA)','FontName','Tahoma','Color','k');
        case 'frequency'
            xlabel(ax, 'Frequency (Hz)', 'FontName','Tahoma','Color','k');
    end
    ylabel(ax,'E[Response] (μV)', 'FontName','Tahoma','Color','k');
    axTxt = sprintf('%s Recruitment Curve: %s',channel_name,gName);
    title(ax,axTxt, 'FontName','Tahoma','Color','k');
    fig(iT).UserData.Channel = axTxt;
    
    fig(iT).UserData.GroupData = gName;
end

end