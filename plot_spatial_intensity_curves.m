function [fig,TID,mdl,gof] = plot_spatial_intensity_curves(A, muscle, options)
%PLOT_SPATIAL_INTENSITY_CURVES  Plot (current intensity) recruitment curves according to rostral/caudal and left/right layout.
arguments
    A
    muscle
    options.CData (1,3) double {mustBeInRange(options.CData,0,1)} = [0 0 0];
    options.MarkerSize (1,1) double = 16;
    options.Position (1,4) double = [2.5 1.5 8 6.5];
    options.YMax (1,1) double = 10000;
end

M = A(A.Muscle==muscle,:);
[G,TID] = findgroups(M(:,["channel", "return_channel"]));
fig = figure('Name','Spatial Intensity Curves', ...
    'Color', 'w', ...
    'Units','inches',...
    'Position',options.Position);
L = tiledlayout(fig, max(TID.channel), 2);
% L = tiledlayout(fig, 2, max(TID.channel));
yl = [0, options.YMax];
N = size(TID,1);
mdl = cell(size(TID,1),1);
gof = cell(size(TID,1),1);
x_p = linspace(min(A.intensity), max(A.intensity), 50);
for ii = 1:N
    sideOffset = double(strcmpi(TID.return_channel{ii},'R'));
    axesIndex = TID.channel(ii)*2-1+sideOffset;
    % sideOffset = max(TID.channel)*strcmpi(TID.return_channel{ii},'R');
    % axesIndex = TID.channel(ii) + sideOffset;
    ax = nexttile(L,axesIndex,[1 1]);
    set(ax,'NextPlot','add','FontName','Tahoma',"FontSize",14,'YLim',yl,'YTick',yl,'XLim',[x_p(1), x_p(end)]);
    if ~ismember(axesIndex,[N-1, N])
        set(ax,'XColor','none');
    end
    if sideOffset == 1
        set(ax,'YColor','none');
    end
    title(ax,sprintf("%d:%s", TID.channel(ii), TID.return_channel{ii}), ...
        'FontName','Tahoma','Color',[0.65 0.65 0.65]);
    mask = G == ii;
    [mdl{ii},gof{ii}] = Somatotopy.fit_sigmoid_response(M.intensity(mask), M.Response(mask));
    y_p = mdl{ii}(x_p);
    line(ax, x_p, y_p, 'Color', 'b', 'LineStyle', '--', 'LineWidth', 1.5);

    scatter(ax, M.intensity(mask), M.Response(mask), ...
        options.MarkerSize, options.CData, "filled", ...
        'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor','none',...
        'XJitter','density');
    
end
allAxes = findobj(L.Children,'type','axes');
linkaxes(allAxes,'xy');
title(L,sprintf("%s Recruitment Curves", string(muscle)),'FontName','Tahoma','Color','k');
ylabel(L,'Peak-to-Peak (μV)','FontName',"Tahoma",'Color','k');
xlabel(L,'Current (μA)', 'FontName',"Tahoma",'Color','k');
fig.UserData.Muscle = string(muscle);
end