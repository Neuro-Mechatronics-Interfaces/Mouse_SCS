close all force;
clear;
clc;

SUBJ = "Pilot_SCS_N_CEJ_04";
MUSCLE = "L-P-DELTOID";
FREQ = 40;
AMP = 2500;
SWEEP = 38;
YYYY = 2024;
MM = 6;
DD = 10;
[~,intanData,T] = loadData(SUBJ,YYYY,MM,DD,SWEEP, ...
        'LoadSAGA',false, ...
        'RawDataRoot',"C:/Data/SCS");
[muscle, channel_index] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));
[snips, t, response, blip, filtering, fdata] =  ...
        intan_amp_2_snips(intanData, ...
            "TLim",[-0.002, 0.006], ...
            "DigInSyncChannel", 1, ...
            "Verbose", true, ...
            'FilterParameters',{'ApplyFiltering', true});
[snip_subset,Tsub] = get_snips_subset(snips,T,FREQ,AMP);

%%
nPerBurst = Tsub.n_pulses;
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]); 
ax = axes(fig,'NextPlot','add', ...
    'FontName','Tahoma', ...
    'Box','off', ...
    'YColor','none',...
    'XLim',[-2.75, 6], ...
    'ColorOrder',winter(nPerBurst));
plot(ax, t.*1e3, squeeze(snip_subset(:,muscle==MUSCLE,:)) + (0:1500:(1500*(size(snip_subset,3)-1)))); 
line(ax,[-2.5 -2.5],[0, 30000],'LineWidth',1.5,'Color','k');
text(ax,-2.75,1500,'30mV','FontName','Tahoma','FontSize',8,'Color','k','Rotation',90);
title(ax,"Not Rate-Dependent Suppression",'FontName','Tahoma','Color','k');
subtitle(ax,sprintf("(@ %d-Hz | %gmA | Sweep-%d | %s )",FREQ,AMP/1000,SWEEP,MUSCLE),'FontName','Tahoma','Color',[0.65 0.65 0.65]);
utils.save_figure(fig,sprintf('export/%s/ad hoc',SUBJ),sprintf('Sweep-%d_%s_RDS_%dHz',SWEEP,MUSCLE,FREQ));

%%
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]);
L = tiledlayout(fig,'flow');

[~,iStart] = min(abs(t-0.0022));
iStop = numel(t);
[~,iResponseStart] = min(abs(t-0.0022));
[~,iResponseEnd] = min(abs(t-0.0032)); 
% nPerBurst = max(round(FREQ*0.5),1);

nTotal = size(snip_subset,3)/nPerBurst;
post_stim_power_raw = nan(nTotal,nPerBurst);
cdata = winter(nTotal);
for ii = 1:nTotal
    ax = nexttile(L);
    set(ax,'NextPlot','add', ...
        'FontName','Tahoma', ...
        'Box','off', ...
        'YLim',[0 15000]);
    curdata = squeeze(snip_subset(:,muscle==MUSCLE,ii:nTotal:end));
    plot(ax,t.*1e3,curdata + (0:1500:(1500*(size(curdata,2)-1))),'Color',cdata(ii,:));
    plot(ax,t([iStart,iStop]).*1e3,squeeze(snip_subset([iStart,iStop],muscle==MUSCLE,ii:nTotal:end)) + (0:1500:(1500*(size(curdata,2)-1))),'Color','k','LineStyle',':')
    title(ax,sprintf('Pulse-%d',ii),'FontName','Tahoma','Color',cdata(ii,:));
    post_stim_power_raw(ii,:) = mean(sqrt(curdata(iResponseStart:iResponseEnd,:).^2),1);
end
xlabel(L,'Time (ms)','FontName','Tahoma','Color','k');
utils.save_figure(fig,sprintf('export/%s/ad hoc',SUBJ),sprintf('Sweep-%d_%s_RDS_alt_%dHz',SWEEP,MUSCLE,FREQ));

%% With subtractions
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]);
L = tiledlayout(fig,'flow');
post_stim_power_fix = nan(nTotal,nPerBurst);
cdata = winter(nTotal);
for ii = 1:nTotal
    ax = nexttile(L);
    set(ax,'NextPlot','add', ...
        'FontName','Tahoma', ...
        'Box','off', ...
        'YLim',[-2500 15000]);
    curdata = squeeze(snip_subset(:,muscle==MUSCLE,ii:nTotal:end));
    art_part = interp1([iStart,iStop],curdata([iStart,iStop],:),iStart:iStop,'linear');
    curdata_minus_art = curdata;
    curdata_minus_art(iStart:iStop,:) = curdata(iStart:iStop,:) - art_part;
    plot(ax,t.*1e3, curdata_minus_art + (0:1500:(1500*(size(curdata,2)-1))),'Color',cdata(ii,:));
    title(ax,sprintf('Pulse-%d',ii),'FontName','Tahoma','Color',cdata(ii,:));
    post_stim_power_fix(ii,:) = mean(sqrt(curdata_minus_art(iResponseStart:iResponseEnd,:).^2),1);
end
xlabel(L,'Time (ms)','FontName','Tahoma','Color','k');
utils.save_figure(fig,sprintf('export/%s/ad hoc',SUBJ),sprintf('Sweep-%d_%s_RDS_alt_detrend_%dHz',SWEEP,MUSCLE,FREQ));


%%
fig = figure;
boxchart(post_stim_power_fix');
ylabel("Mean sqrt(x^2)");
xlabel("Pulse Number");
set(fig,'Color','w');
utils.save_figure(fig,sprintf('export/%s/ad hoc',SUBJ),sprintf('Sweep-%d_%s_RDS_alt_detrend_rms_%dHz',SWEEP,SUBJ,FREQ));
