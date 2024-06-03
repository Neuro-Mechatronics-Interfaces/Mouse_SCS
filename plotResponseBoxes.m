function [fig, response_channels, non_response_channels] = plotResponseBoxes(response_data, options)
%PLOTRESPONSEBOXES  Plots box plot of per-channel response data
%
% Syntax:
%   [fig, response_channels, non_response_channels] = plotResponseBoxes(response_data, 'Name', value, ...);
%
% Inputs:
%   response_data (:, :) double % Normalized response data
% 
% Options:
%   'Subject' {mustBeTextScalar} = "Unknown";
%   'Year' (1,1) double = year(today);
%   'Month' (1,1) double = month(today);
%   'Day' (1,1) double = day(today);
%   'Sweep' (1,1) double {mustBeInteger} = 0;
%   'Block' (1,1) double {mustBeInteger} = 0;
%   'ResponseThreshold' (1,1) double {mustBePositive} = 20.0;
%   'FigurePosition' = [100 300 900 420];
%
% Output:
%   fig - Figure handle
%   response_channels - Indexing vector indicating which channels had 
%                       responses given the specified `ResponseThreshold` 
%                       option value.
%   non_response_channels - Indicates which channels did not have responses
%
% See also: Contents

arguments
    response_data (:, :) double % Normalized response data
    options.Subject {mustBeTextScalar} = "Unknown";
    options.Year (1,1) double = year(today);
    options.Month (1,1) double = month(today);
    options.Day (1,1) double = day(today);
    options.Sweep (1,1) double {mustBeInteger} = 0;
    options.Block (1,1) double {mustBeInteger} = 0;
    options.ResponseThreshold (1,1) double {mustBePositive} = 20.0;
    options.FigurePosition = [100 300 900 420];
    options.Muscle (:,1) string = "";
end
fig = figure('Color', 'w', 'Name', 'BoxPlot of Channelwise Responses',...
    'Position',options.FigurePosition);
warning('off','MATLAB:Axes:NegativeLimitsInLogAxis');
ax = axes(fig,'NextPlot','add','FontName','Tahoma',...
    'XColor','k','YColor','k','Color','none','YScale','log');
title(ax, sprintf('%s: %04d-%02d-%02d', ...
    strrep(options.Subject,'_','\_'), options.Year, options.Month, options.Day), ...
    'FontName','Tahoma','Color','k');
subtitle(ax, ...
    sprintf('Normalized Response Power: Sweep-%d | Block-%d', ...
    options.Sweep, options.Block), ...
    'FontName','Tahoma','Color',[0.65 0.65 0.65]);
iResponse = mean(response_data,1) >= options.ResponseThreshold;
no_response = response_data;
no_response(:,iResponse) = nan;
response = response_data;
response(:,~iResponse) = nan;
boxchart(ax,no_response);
boxchart(ax, response);
if numel(options.Muscle) == size(response,2)
    set(ax,'XTickLabel',options.Muscle);
end
yline(ax, options.ResponseThreshold, 'k--', ...
    'LineWidth', 1.5, ...
    'Label', 'Response Threshold', ...
    'LabelVerticalAlignment','middle', ...
    'LabelHorizontalAlignment','left');
response_channels = find(iResponse);
non_response_channels = setdiff(1:size(response_data,2), response_channels);
warning('on','MATLAB:Axes:NegativeLimitsInLogAxis');
end