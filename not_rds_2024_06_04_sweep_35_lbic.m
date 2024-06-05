close all force;
clear;
clc;

SUBJ = "Pilot_SCS_N_CEJ_03";
[~,intanData,T] = loadData(SUBJ,2024,6,4,35, ...
        'LoadSAGA',false, ...
        'RawDataRoot',"C:/Data/SCS");
[muscle, channel_index] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));
[snips, t, response_normed, response_raw, filtering, fdata] =  ...
        intan_amp_2_snips(intanData, ...
            "TLim",[-0.002, 0.006], ...
            "TLimResponse", [0.001, 0.003], ...
            "TLimBaseline", [-0.002, -0.001], ...
            "DigInSyncChannel", 2, ...
            "Verbose", true, ...
            'FilterParameters',{'ApplyFiltering', false});
[snip_subset,Tsub] = get_snips_subset(snips,T,40,2500);

%%
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]); 
ax = axes(fig,'NextPlot','add', ...
    'FontName','Tahoma', ...
    'Box','off', ...
    'YColor','none',...
    'XLim',[-2.75, 6], ...
    'ColorOrder',winter(20));
plot(ax, t.*1e3, squeeze(snip_subset(:,muscle=="L-BICEPS",:)) + (0:1500:(1500*(size(snip_subset,3)-1)))); 
line(ax,[-2.5 -2.5],[0, 30000],'LineWidth',1.5,'Color','k');
text(ax,-2.75,1500,'30mV','FontName','Tahoma','FontSize',8,'Color','k','Rotation',90);
title(ax,"Not Rate-Dependent Suppression",'FontName','Tahoma','Color','k');
subtitle(ax,"(@ 40-Hz | 2.5mA | Sweep-35 | L-BICEPS )",'FontName','Tahoma','Color',[0.65 0.65 0.65]);
utils.save_figure(fig,'export/Pilot_SCS_N_CEJ_03/ad hoc','Sweep-35_L-BIC_Not_RDS');

%%
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]);
L = tiledlayout(fig,5,4);
cdata = winter(20);
[~,iStart] = min(abs(t-0.000525));
iStop = numel(t);
[~,iResponseStart] = min(abs(t-0.001));
[~,iResponseEnd] = min(abs(t-0.003)); 

post_stim_power_raw = nan(20,5);
for ii = 1:20
    ax = nexttile(L);
    set(ax,'NextPlot','add', ...
        'FontName','Tahoma', ...
        'Box','off', ...
        'YLim',[0 15000]);
    curdata = squeeze(snip_subset(:,muscle=="L-BICEPS",ii:20:end));
    plot(ax,t.*1e3,curdata + (0:1500:(1500*4)),'Color',cdata(ii,:));
    plot(ax,t([iStart,iStop]).*1e3,squeeze(snip_subset([iStart,iStop],muscle=="L-BICEPS",ii:20:end)) + (0:1500:(1500*4)),'Color','k','LineStyle',':')
    title(ax,sprintf('Pulse-%d',ii),'FontName','Tahoma','Color',cdata(ii,:));
    post_stim_power_raw(ii,:) = mean(sqrt(curdata(iResponseStart:iResponseEnd,:).^2),1);
end
xlabel(L,'Time (ms)','FontName','Tahoma','Color','k');
utils.save_figure(fig,'export/Pilot_SCS_N_CEJ_03/ad hoc','Sweep-35_L-BIC_Not_RDS_alt');

%% With subtractions
fig = figure('Color','w','Units','inches','Position',[5 1 6 7]);
L = tiledlayout(fig,5,4);
post_stim_power_fix = nan(20,5);
for ii = 1:20
    ax = nexttile(L);
    set(ax,'NextPlot','add', ...
        'FontName','Tahoma', ...
        'Box','off', ...
        'YLim',[-2500 15000]);
    curdata = squeeze(snip_subset(:,muscle=="L-BICEPS",ii:20:end));
    art_part = interp1([iStart,iStop],curdata([iStart,iStop],:),iStart:iStop,'linear');
    curdata_minus_art = curdata;
    curdata_minus_art(iStart:iStop,:) = curdata(iStart:iStop,:) - art_part;
    plot(ax,t.*1e3, curdata_minus_art + (0:1500:(1500*4)),'Color',cdata(ii,:));
    title(ax,sprintf('Pulse-%d',ii),'FontName','Tahoma','Color',cdata(ii,:));
    post_stim_power_fix(ii,:) = mean(sqrt(curdata_minus_art(iResponseStart:iResponseEnd,:).^2),1);
end
xlabel(L,'Time (ms)','FontName','Tahoma','Color','k');
utils.save_figure(fig,'export/Pilot_SCS_N_CEJ_03/ad hoc','Sweep-35_L-BIC_Not_RDS_alt_detrend');


%%
fig = figure;
boxchart(post_stim_power_fix');
ylabel("Mean sqrt(x^2) (1-3 ms)");
xlabel("Pulse Number");
set(fig,'Color','w');
utils.save_figure(fig,'export/Pilot_SCS_N_CEJ_03/ad hoc','Sweep-35_L-BIC_Not_RDS_alt_detrend_rms');
