%PROCESSING_2024_06_02

close all force;
clc;
clear;

%% 1. Set parameters
% % % Recording-specific metadata parameters % % %
SUBJ = "Pilot_SCS_N_CEJ_02";
YYYY = 2024;
MM = 6;
DD = 2;
SWEEP = [0,13,11,12];
SIDE = ["L","L","R","L"];
RAW_DATA_ROOT = "C:/Data/SCS";
EXPORT_DATA_ROOT = parameters('local_export_folder');

% % % Parameters for response estimation % % %
DIG_IN_SYNC_CHANNEL_NUMBER = 2; % Index of DIG_IN connector used for stim onset sync signals
TLIM_SNIPPETS = [-0.002, 0.006]; % Seconds (for signal indexing, relative to each stim onset)
TLIM_RESPONSE = [0.002, 0.004]; % Seconds (for estimating power in evoked signal, relative to stim onset)
TLIM_BASELINE = [-0.002, 0.000]; % Seconds (for normalizing responses, relative to stim onset)
SYNC_DEBOUNCE_SEC = 0.005;

% % % Powerpoint Deck exporter % % %
pptx = exportToPPTX('', ...
    'Dimensions',[10, 7.5], ...
    'Title',sprintf("%s Recruitment Curves", SUBJ), ...
    'Author','Max Murphy', ...
    'Subject',SUBJ, ...
    'Comments',sprintf('Recruitment curves from Mouse SCS procedure %s.', SUBJ));

%% 2. Iterate over sweeps
iCount = 0;
for iSweep = SWEEP
    iCount = iCount + 1;
    [~,intan,T] = loadData(SUBJ,YYYY,MM,DD,iSweep, ...
        'LoadSAGA',false, ...
        'RawDataRoot',RAW_DATA_ROOT);
    [muscle, channel_index] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));
    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
            'Position',[4 7 0.5 0.5], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','center', ...
            'FontSize', 10);
    pptx.addTextbox(sprintf('SWEEP-%02d: CH-%d (%s)', iSweep, T.channel(1), SIDE{iCount}), ...
            'Position',[0 3.5 10 1.5], ...
            'FontName', 'Tahoma', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 36);


    % 3. Index and filter data, estimate responses
    [snips, t, response_normed, response_raw, filtering, fdata] =  ...
        intan_amp_2_snips(intan, ...
            "TLim",TLIM_SNIPPETS, ...
            "TLimResponse", TLIM_RESPONSE, ...
            "TLimBaseline", TLIM_BASELINE, ...
            "DigInSyncChannel", DIG_IN_SYNC_CHANNEL_NUMBER, ...
            'SyncDebounce', SYNC_DEBOUNCE_SEC, ...
            "Verbose", true, ...
            'FilterParameters',{'ApplyFiltering', false, 'ApplyCAR',false,'BlankArtifactBeforeFiltering',true,'CutoffFrequency',100});
    
    % 4. Plot selected examples of response snippets
    snippetStackFigure = plotResponseSnippets(t.*1e3, ...
        snips, channel_index, T, ...
        'XLabel', 'Time (ms)', ...
        'YOffset', 1500, ...
        'Muscle', muscle, ...
        'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD,'Sweep', iSweep);
    for ii = 1:numel(snippetStackFigure)
        slideId = pptx.addSlide();
        pptx.addTextbox(num2str(slideId), ...
            'Position',[4 7 0.5 0.5], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','center', ...
            'FontSize', 10);
        pptx.addTextbox(snippetStackFigure(ii).UserData.Title, ...
            'Position',[0 0 10 1], ...
            'FontName', 'Tahoma', ...
            'FontSize', 24);
        pptx.addTextbox(strrep(snippetStackFigure(ii).UserData.Subtitle,'\mu','μ'), ...
            'Position',[0 0.75 10 1], ...
            'FontName','Tahoma',...
            'FontSize',16);
        pptx.addPicture(snippetStackFigure(ii),'Position',[0 1.75 10 5.75]);
        utils.save_figure(snippetStackFigure(ii),sprintf('%s/%s/Sweep-%02d/Snippets',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_Recruitment-Snippets_%d-Hz',SUBJ,snippetStackFigure(ii).UserData.Frequency));
    end
    
    % 5. Plot response curves
    for iCh = 1:numel(channel_index)
        recruitmentFigure = plotRecruitment(T, response_raw, channel_index(iCh), muscle(iCh));
        slideId = pptx.addSlide();
        pptx.addTextbox(num2str(slideId), ...
                'Position',[4 7 0.5 0.5], ...
                'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center', ...
                'FontSize', 10);
        pptx.addTextbox(muscle(iCh), ...
                'Position',[0 3.5 10 1.5], ...
                'FontName', 'Tahoma', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 36);
        for ii = 1:numel(recruitmentFigure)
            slideId = pptx.addSlide();
            pptx.addTextbox(num2str(slideId), ...
                'Position',[4 7 0.5 0.5], ...
                'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center', ...
                'FontSize', 10);
            pptx.addTextbox(strrep(recruitmentFigure(ii).UserData.Channel,'\mu','μ'), ...
                'Position',[0 0 10 1], ...
                'FontName', 'Tahoma', ...
                'FontSize', 24);
            pptx.addPicture(recruitmentFigure(ii),'Position',[3 1 4 6.5]);
            utils.save_figure(recruitmentFigure(ii), sprintf('%s/%s/Sweep-%02d/Recruitment',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_%s_Recruitment-Curve_%d-Hz',SUBJ,muscle(iCh),recruitmentFigure(ii).UserData.Frequency));
        end
    end
end

%% 7. Save Powerpoint
if exist(fullfile(EXPORT_DATA_ROOT,SUBJ),'dir')==0
    mkdir(fullfile(EXPORT_DATA_ROOT,SUBJ));
end
pptx.save(sprintf('%s/%s/%s_Recruitment',EXPORT_DATA_ROOT,SUBJ,SUBJ));