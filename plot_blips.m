function fig = plot_blips(muscle, blip, T, muscle_index, options)
%PLOT_BLIPS  Plots blips from de-trended stimulus responses
%
% Syntax:
%   fig = plot_blips(muscle, blip, T, muscle_index, 'Name', value, ...);
%
% Inputs:
%   muscle - Array of strings corresponding to muscle mapping
%   blip   - Cell array of responses, indexed by T (for intensity/freq).
%               Each element contains a cell array of channel-wise
%               responses, where rows are times and columns are pulse
%               iterations.
%   T      - Indexing table
%   muscle_index - The index of muscle we want to plot blip of. Empty to
%                   plot blip figure for each muscle.
%   
% Options:
%   'SampleRate' (1,1) double = 20000

arguments
    muscle
    blip
    T
    muscle_index = [];
    options.SampleRate (1,1) double = 20000;
    options.FigureOptions cell = {};
    options.CalibrationFile {mustBeTextScalar} = "Muscle_Response_Times.xlsx";
    options.YOffset (1,1) double = 1000;
    options.Title = "";
    options.WaterfallOptions cell = {};
    options.MaxBlips (1,1) {mustBePositive, mustBeInteger} = 25;
end

if isempty(muscle_index)
    muscle_index = 1:numel(muscle);
end

if ~isscalar(muscle_index)
    % fig = gobjects(numel(muscle_index),1);
    fig = cell(numel(muscle_index),1);
    for ii = 1:numel(muscle_index)
        fig{ii} = plot_blips(muscle,blip,T,muscle_index(ii),...
            'CalibrationFile',options.CalibrationFile,...
            'FigureOptions',options.FigureOptions,...
            'YOffset',options.YOffset,...
            'Title',options.Title,...
            'WaterfallOptions',options.WaterfallOptions,...
            'SampleRate',options.SampleRate, ...
            'MaxBlips',options.MaxBlips);
    end
    fig = vertcat(fig{:});
    return;
end

[T, sort_index] = sortrows(T,'intensity','ascend');
blip = blip(sort_index);

B = load_muscle_response_times(muscle,'CalibrationFile',options.CalibrationFile);
t = B(muscle_index,1):(1/options.SampleRate):(B(muscle_index,2)-(1/options.SampleRate));
t = t.*1e3; % milliseconds
muscle = muscle(muscle_index);

[G,TID] = findgroups(T(:,["frequency","pulse_width","channel"]));
fig = gobjects(size(TID,1),1);
for iT = 1:size(TID,1)
    blipdata = cellfun(@(C)C(muscle_index),blip(G==iT));
    blipdata = horzcat(blipdata{:});
    if size(blipdata,2) > options.MaxBlips
        iSel = randsample(1:size(blipdata,2),options.MaxBlips,false);
        iSel = sort(iSel,'ascend');
        blipdata = blipdata(:,iSel);
        randsample_flag = true;
    else
        randsample_flag = false;
    end
    
    fig(iT) = figure(...
        'Name',sprintf('%s Artifact-Rejected Blips',muscle),...
        'Color','w',...
        'Units','inches',...
        'Position',[2 1.5 9 5.25], ...
        options.FigureOptions{:});
    ax = axes(fig(iT),...
            'NextPlot','add',...
            'FontName','Tahoma', ...
            'FontSize', 14, ...
            'YColor','none',...
            'Box','off',...
            'XColor','none');
    plot.waterfall(t,blipdata,...
        'Parent',ax,...
        'YOffset',options.YOffset, ...
        'AddZeroMarker', false, ...
        'XLabelRoundingLevel', 1, ...
        options.WaterfallOptions{:});
    xline(ax,B(muscle_index,1).*1e3,'k--', ...
        'Label',sprintf('t=%5.2fms',round(B(muscle_index,1).*1e3,2)), ...
        'LabelHorizontalAlignment','right',...
        'LabelOrientation','horizontal',...
        'FontName','Tahoma',...
        'FontSize',14);
    xline(ax,B(muscle_index,2).*1e3,'k--',...
        'Label',sprintf('t=%5.2fms',round(B(muscle_index,2).*1e3,2)), ...
        'LabelHorizontalAlignment','left', ...
        'LabelOrientation','horizontal',...
        'FontName','Tahoma',...
        'FontSize',14);
    
    if strlength(options.Title) < 1
        txt = sprintf('%d-Hz (%dμA - %dμA)',TID.frequency(iT),T.intensity(1),T.intensity(end));
        if randsample_flag
            txt = sprintf('%s | Random Subset (N = %d)', txt, options.MaxBlips);
        end
        title(ax,txt, 'FontName','Tahoma','Color','k','FontSize',16,'FontWeight','bold');
    end
    fig(iT).UserData = struct;
    fig(iT).UserData.Title = txt;
    
    subtxt = sprintf("Detrended Blips: %s", muscle);
    subtitle(ax,subtxt, ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65],'FontSize',13);
    
    fig(iT).UserData.Subtitle = subtxt;
    fig(iT).UserData.Frequency = TID.frequency(iT);
    fig(iT).UserData.Channel = TID.channel(iT);
    fig(iT).UserData.PulseWidth = TID.pulse_width(iT);
end
end