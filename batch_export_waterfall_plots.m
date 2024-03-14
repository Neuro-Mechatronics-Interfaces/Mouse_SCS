%BATCH_EXPORT_WATERFALL_PLOTS  Export waterfall plots using tensor-style dataset

% FIG_POSITION = [14.25, 3.25, 2.75, 5]; % "Standard"
FIG_POSITION = [11.5417    1.2135    3.7240    8.5990]; % For 40, 80, 160-Hz, gives more space
LINE_WIDTH = 0.25; % Default is 0.5
tScale = t(end) + mean(diff(t))*2;
for f = [40,80,160]
    freqMask = trial.frequency == f;
    [G,TID] = findgroups(trial(freqMask,["intensity", "frequency"]));
    nCol = splitapply(@sum,trial.N(freqMask),G);
    colOrder = repelem(copper(size(TID,1)),nCol,1);
    y_step = 20;
    y_offset = (0:y_step:((sum(freqMask)-1)*y_step));
    for iCh = [1:68, 72:138] % Do different for accelerometers
        fig = figure('Color', 'w', 'Units', 'Inches', 'Position', FIG_POSITION);
        y = squeeze(data(:,iCh,freqMask));
        ax = axes(fig, 'NextPlot','add','Clipping', 'off', 'XColor','none','YColor','none', 'FontName','Tahoma', 'ColorOrder', colOrder);
        line(ax,[t(1),t(1)]-0.5,[-150,150],'Color','k','LineWidth',1.25);
        text(ax,t(1)-1.25,-100,'300 \muV','FontName','Tahoma','Color','k','HorizontalAlignment','right');
        line(ax,[t(1)-0.5,t(1)+2],[-150, -150],'Color','k','LineWidth',1.25);
        text(ax,t(1),-200,'2.5 ms','FontName','Tahoma','Color','k','VerticalAlignment','top');
        plot(ax,repmat(t,1,sum(freqMask)), y + y_offset, 'LineWidth', LINE_WIDTH);
        line(ax,[0 0],[0, ax.YLim(2)],'LineWidth', 1.25,'Color','r','LineStyle','--');
        text(ax,0,ax.YLim(2)+50,"Stim Onset",'FontName','Tahoma','Color','r','HorizontalAlignment','right','VerticalAlignment','bottom');
        title(ax, sprintf('%s: %d-Hz', channel(iCh).label, f), 'FontName','Tahoma','Color','k','FontWeight','bold');
        allIntensity = sort(abs(TID.intensity),'ascend');
        colOrderIntensity = copper(size(TID,1));
        intensityScaleStart = 0;
        for iIntensity = 1:numel(allIntensity)
            intensityScaleEnd = intensityScaleStart + y_step * nCol(iIntensity);
            line(ax,[tScale, tScale], [intensityScaleStart,intensityScaleEnd],...
                'LineWidth',5,'Color',colOrderIntensity(iIntensity,:));
            text(ax, tScale+mean(diff(t)), (intensityScaleStart+intensityScaleEnd)/2, sprintf('%d \\muA', allIntensity(iIntensity)), ...
                'FontName', 'Tahoma', 'Color', colOrderIntensity(iIntensity,:));
            intensityScaleStart = intensityScaleEnd;
        end
        out_folder = fullfile('R:\NMLShare\generated_data\primate\DRGS\Frank\sweeps', num2str(trial.key(1)), 'figures\Waterfall');
        if exist(out_folder,'dir')==0
            mkdir(out_folder);
        end
        utils.save_figure(fig, out_folder, sprintf('%s_%d-Hz', channel(iCh).label, f), 'ExportAs', {'.png', '.svg'});
    end
    
    y_step = 0.15;
    y_offset = (0:y_step:((sum(freqMask)-1)*y_step));
    for iCh = 139:142
        fig = figure('Color', 'w', 'Units', 'Inches', 'Position', FIG_POSITION);
        y = squeeze(data(:,iCh,freqMask));
        ax = axes(fig, 'NextPlot','add','Clipping', 'off', 'XColor','none','YColor','none', 'FontName','Tahoma', 'ColorOrder', colOrder);
        line(ax,[t(1),t(1)]-0.5,[-0.25,0.25],'Color','k','LineWidth',1.25);
        text(ax,t(1)-1.25,-0.125,'0.5 g','FontName','Tahoma','Color','k','HorizontalAlignment','right');
        line(ax,[t(1)-0.5,t(1)+2],[-0.25, -0.25],'Color','k','LineWidth',1.25);
        text(ax,t(1),-0.375,'2.5 ms','FontName','Tahoma','Color','k','VerticalAlignment','top');
        plot(ax,repmat(t,1,sum(freqMask)), y + y_offset, 'LineWidth', LINE_WIDTH);
        line(ax,[0 0],[0, ax.YLim(2)],'LineWidth', 1.25,'Color','r','LineStyle','--');
        text(ax,0,ax.YLim(2)+50,"Stim Onset",'FontName','Tahoma','Color','r','HorizontalAlignment','right','VerticalAlignment','bottom');
        title(ax, sprintf('%s: %d-Hz', channel(iCh).label, f), 'FontName','Tahoma','Color','k','FontWeight','bold');
        allIntensity = sort(abs(TID.intensity),'ascend');
        colOrderIntensity = copper(size(TID,1));
        intensityScaleStart = 0;
        for iIntensity = 1:numel(allIntensity)
            intensityScaleEnd = intensityScaleStart + y_step * nCol(iIntensity);
            line(ax,[tScale, tScale], [intensityScaleStart,intensityScaleEnd],...
                'LineWidth',5,'Color',colOrderIntensity(iIntensity,:));
            text(ax, tScale+mean(diff(t)), (intensityScaleStart+intensityScaleEnd)/2, sprintf('%d \\muA', allIntensity(iIntensity)), ...
                'FontName', 'Tahoma', 'Color', colOrderIntensity(iIntensity,:));
            intensityScaleStart = intensityScaleEnd;
        end
        out_folder = fullfile('R:\NMLShare\generated_data\primate\DRGS\Frank\sweeps', num2str(trial.key(1)), 'figures\Waterfall');
        if exist(out_folder,'dir')==0
            mkdir(out_folder);
        end
        utils.save_figure(fig, out_folder, sprintf('%s_%d-Hz', channel(iCh).label, f), 'ExportAs', {'.png', '.svg'});
    end
end