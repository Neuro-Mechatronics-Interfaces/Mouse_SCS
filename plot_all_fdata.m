function [fig,ax,y0] = plot_all_fdata(fdata, options)
%PLOT_ALL_FDATA Plot full-recording (Intan) fdata as waterfall stack
%
% Syntax:
%   [fig,ax,y0] = plot_all_fdata(fdata, "Name", value, ...);
%
% Inputs:
%   fdata - (double) nChannels x nTimesamples filtered data array
%           OR
%           (cell) Each cell contains array of nChannels x nTimesamples
%                   filtered data array, 1 per recording.
%   
% Options:
%   'SampleRate' (1,1) double = 20000  Samples/sec
%   'Muscle' string  -- Specify the string labels. Should have same number
%                           of elements as rows of `fdata`, if given.
%
% See also: Contents
arguments
    fdata
    options.CData = [];
    options.SampleRate (1,1) double = 20000; % Sample Rate (samples/sec)
    options.Muscle string = strings(0);
    options.YOffset (1,1) double = 100;
    options.YClipping (1,1) logical = true;
    options.YTickLabelOffset (1,1) double = 0.05;
    options.XUnits {mustBeTextScalar} = "s";
    options.XLabelRoundingLevel (1,1) {mustBeInteger} = 2;
    options.LineWidth (1,1) double = 0.5;
    options.Position (1,4) double = [0.5 1.5 9 6]; % Figure position (inches)
    options.Title {mustBeTextScalar} = "Full Recording";
    options.Subtitle {mustBeTextScalar} = "HPF EMG";
    options.LabelTextOptions cell = {};
end

if iscell(fdata)
    fig = gobjects(size(fdata));
    ax = gobjects(size(fdata));
    y0 = cell(size(fdata));
    for ii = 1:numel(fdata)
        [fig(ii),ax(ii),y0{ii}] = plot_all_fdata(fdata{ii}, ...
            'CData',options.CData, ...
            'SampleRate', options.SampleRate, ...
            'Muscle',options.Muscle,...
            'YOffset',options.YOffset,...
            'YClipping',options.YClipping,...
            'YTickLabelOffset',options.YTickLabelOffset,...
            'XUnits',options.XUnits,...
            'XLabelRoundingLevel',options.XLabelRoundingLevel,...
            'LineWidth',options.LineWidth,...
            'Position',options.Position,...
            'LabelTextOptions',options.LabelTextOptions);
    end
    return;
end
t_fdata = utils.sample_time(fdata, options.SampleRate);
[fig,ax,~,y0] = plot.waterfall(t_fdata, fdata, ...
    'CData', options.CData, ...
    'YOffset', options.YOffset, ...
    'YClipping',options.YClipping, ...
    'AddZeroMarker',false, ...
    'LineWidth',options.LineWidth,...
    'XUnits',options.XUnits, ...
    'XLabelRoundingLevel',options.XLabelRoundingLevel, ...
    'FigurePosition', options.Position);
if strlength(options.Title) > 0
    title(ax, options.Title, 'Color','k','FontWeight','bold','FontName','Tahoma','FontSize',16);
end
if strlength(options.Subtitle) > 0
    subtitle(ax, options.Subtitle, 'Color',[0.65 0.65 0.65],'FontWeight','normal','FontName','Tahoma','FontSize',14);
end
fig.UserData.Title = options.Title;
fig.UserData.Subtitle = options.Subtitle;

if ~isempty(options.Muscle)
    if numel(options.Muscle)~=size(fdata,1)
        error("Must have same number of rows in fdata as elements in 'Muscle' option.");
    end
    x_lab = t_fdata(1)-options.YTickLabelOffset*(t_fdata(end)-t_fdata(1));
    for ii = 1:numel(y0)
        text(ax, x_lab, y0(ii), options.Muscle(ii), ...
            'Color', options.CData(ii,:), ...
            'FontSize', 14, 'FontName', "Tahoma", 'FontWeight', 'normal', ...
            'HorizontalAlignment', 'right', options.LabelTextOptions{:})
    end
end



end