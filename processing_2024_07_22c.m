%PROCESSING_2024_07_22b  Processing associated with 2024-07-22b procedure.
%#ok<*UNRCH>
close all force;
clc;
clear;

%% 1. Set parameters
% % % Recording-specific metadata parameters % % %
SUBJ = "Pilot_SCS_N_CEJ_09";
YYYY = 2024;
MM = 7;
DD = 22;
SWEEP = 0;
TAG = 'c';

PLOT_ALL_FDATA = false;
PLOT_RECRUITMENT = true;
EXPORT_PULSE_RECRUITMENT_SCATTERS = false;

% RAW_DATA_ROOT = "C:/Data/SCS";
RAW_DATA_ROOT = parameters('raw_data_folder_root');
EXPORT_DATA_ROOT = parameters('local_export_folder');

% % % Parameters for response estimation % % %
DIG_IN_SYNC_CHANNEL_NUMBER = 2; % Index of DIG_IN connector used for stim onset sync signals
TLIM_SNIPPETS = [-0.002, 0.006]; % Seconds (for signal indexing, relative to each stim onset)
MUSCLE_RESPONSE_TIMES_FILE = sprintf("Muscle_Response_Times_Exponential_%04d_%02d_%02d%s.xlsx",YYYY,MM,DD,TAG);
[MUSCLE, CHANNEL_INDEX] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));
muscle = MUSCLE(CHANNEL_INDEX);
RECRUITMENT_PULSE_INDEX = 1;
DETREND_MODE = "exp"; % Must be "poly" or "exp"
POLY_ORDER = []; % Leave empty to use values in file otherwise specify global value to override file-specific polynomial detrend order

% % % Powerpoint Deck exporter % % %
pptx = exportToPPTX('', ...
    'Dimensions',[10, 7.5], ...
    'Title',sprintf("%s Recruitment Curves", SUBJ), ...
    'Author','Max Murphy (MATLAB Auto-gen)', ...
    'Subject',SUBJ, ...
    'Comments',sprintf('Recruitment curves from Mouse SCS procedure %s.', SUBJ));

%% 2. Iterate over sweeps
iCount = 0;
for iSweep = SWEEP
    iCount = iCount + 1;
    [~,intanData,T] = loadData(SUBJ,YYYY,MM,DD,iSweep, ...
        'LoadSAGA',false, ...
        'RawDataRoot',RAW_DATA_ROOT);
    [longName,shortName] = metadata_2_title(T);
    
    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
            'Position',[4 7 0.5 0.5], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','center', ...
            'FontSize', 10);
    pptx.addTextbox(sprintf('SWEEP-%03d: CH-%d (%s)', iSweep, T.channel(1), T.return_channel{1}), ...
            'Position',[0 3.5 10 1.5], ...
            'FontName', 'Tahoma', ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 36);
    if T.is_monophasic(1)
        pulse_type = "monophasic";
    else
        pulse_type = "biphasic";
    end
    if T.is_cathodal_leading(1)
        pulse_pol = "cathodal";
    else
        pulse_pol = "anodal";
    end
    pptx.addTextbox(sprintf('%s-%s pulses', pulse_type, pulse_pol), ...
            'Position',[0 5.5 10 1.5], ...
            'FontName', 'Tahoma', ...
            'HorizontalAlignment', 'center', ...
            'Color', [0.65 0.65 0.65], ...
            'FontSize', 18);


    % 3. Index and filter data, estimate responses
    [snips, t, response, blip, filtering, fdata, trend] =  ...
        intan_amp_2_snips(intanData, ...
            "TLim",TLIM_SNIPPETS, ...
            "DetrendMode",DETREND_MODE,...
            "PolyOrder",POLY_ORDER,...
            "Muscle", MUSCLE, ... % Use one that does not have removals
            "MuscleResponseTimesFile", MUSCLE_RESPONSE_TIMES_FILE, ...
            "DigInSyncChannel", DIG_IN_SYNC_CHANNEL_NUMBER, ...
            "Verbose", true, ...
            'FilterParameters',{'ApplyFiltering', true});
    
    % 4. Plot selected examples of response snippets
    [snippetStackFigure, cdata] = plotResponseSnippets(t.*1e3, ...
        snips, CHANNEL_INDEX, T, ...
        'XLabel', 'Time (ms)', ...
        'YOffset', 500, ...
        'Muscle', muscle, ...
        'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD,'Sweep', iSweep);
    
    
    for ii = 1:numel(snippetStackFigure)
        currentFreq = snippetStackFigure(ii).UserData.Frequency;
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
        utils.save_figure(snippetStackFigure(ii),sprintf('%s/%s/Sweep-%03d/Snippets',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_Recruitment-Snippets_%d-Hz',SUBJ,currentFreq));
    end

    if PLOT_ALL_FDATA
        fdataFigure = plot_all_fdata( ...
            cellfun(@(c){c(CHANNEL_INDEX([1:4,6:9]),:)},fdata), ...
            'Muscle',muscle([1:4,6:9]),...
            'CData',cdata([1:4,6:9],:)); 
        [~,iAmplitudeOrder] = sort(T.intensity,'ascend');
        for ii = 1:numel(fdataFigure)
            slideId = pptx.addSlide();
            k = iAmplitudeOrder(ii);
            pptx.addTextbox(num2str(slideId), ...
                'Position',[4 7 0.5 0.5], ...
                'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center', ...
                'FontSize', 10);
            pptx.addTextbox(sprintf('Block-%d: %s', k-1, longName(k)), ...
                'Position',[0 0 10 1], ...
                'FontName', 'Tahoma', ...
                'FontSize', 24);
            pptx.addPicture(fdataFigure(k),'Position',[0 1.75 10 5.75]);
            utils.save_figure(fdataFigure(k),sprintf('%s/%s/Sweep-%03d/Full',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_%s',SUBJ,shortName(k)));
        end
    end
    
    if EXPORT_PULSE_RECRUITMENT_SCATTERS
        uIntensity = unique(T.intensity);
        uFrequency = unique(T.frequency);
        
        batch_export_pulse_recruitment(uIntensity, uFrequency, muscle, T, response, 'CData', cdata);
        for ii = 1:numel(uFrequency)
            for ik = 1:numel(uIntensity)
                for iM = 1:numel(muscle)
                    slideId = pptx.addSlide();
                    pptx.addTextbox(num2str(slideId), ...
                        'Position',[4 7 0.5 0.5], ...
                        'VerticalAlignment','bottom', ...
                        'HorizontalAlignment','center', ...
                        'FontSize', 10);
                    pptx.addTextbox(sprintf('%d-Hz | %d-μA',uFrequency(ii),uIntensity(ik)), ...
                        'Position',[0 0 10 1], ...
                        'FontName', 'Tahoma', ...
                        'FontSize', 24);
                    pptx.addPicture(char(fullfile(pwd,'export',SUBJ,'Pulse-Recruitment',sprintf('%s_%04d_%02d_%02d_%d_%duA_%dHz_%s_Pulse-Recruitment.png',SUBJ,YYYY,MM,DD,SWEEP,uIntensity(ik),uFrequency(ii),muscle(iM)))),'Position',[0 1.75 10 5.75]);
                end
            end
        end
            
    end
    
    if numel(unique(T.frequency)) <= numel(unique(T.intensity))
        blipFigure = plot_blips(muscle,blip,trend,T,[],...
            'ChannelIndex', CHANNEL_INDEX, ...
            'DetrendMode', DETREND_MODE, ...
            'PolyOrder',POLY_ORDER,...
            'CalibrationFile',MUSCLE_RESPONSE_TIMES_FILE, ...
            'YOffset', 100);
        for ii = 1:numel(blipFigure)
            slideId = pptx.addSlide();
            pptx.addTextbox(num2str(slideId), ...
                'Position',[4 7 0.5 0.5], ...
                'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center', ...
                'FontSize', 10);
            pptx.addTextbox(blipFigure(ii).UserData.Title, ...
                'Position',[0 0 10 1], ...
                'FontName', 'Tahoma', ...
                'FontSize', 24);
            pptx.addTextbox(blipFigure(ii).UserData.Subtitle, ...
                'Position',[0 1 10 0.75], ...
                'FontName','Tahoma',...
                'FontSize',16);
            pptx.addPicture(blipFigure(ii),'Position',[0.5 1.75 9 5.25]);
            utils.save_figure(blipFigure(ii),sprintf('%s/%s/Sweep-%03d/Blips',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_Blips_%d-Hz_%s',SUBJ,blipFigure(ii).UserData.Frequency,blipFigure(ii).UserData.Muscle));
        end
    end
    
    % 5. Plot response curves
    if ((numel(unique(T.intensity)) > 1) || (numel(unique(T.frequency)) > 1)) && PLOT_RECRUITMENT
        for iCh = 1:numel(CHANNEL_INDEX)
            recruitmentFigure = plotRecruitment(T, response, CHANNEL_INDEX(iCh), muscle(iCh), ...
                'Color', cdata(iCh,:), ...
                'PulseIndex', RECRUITMENT_PULSE_INDEX);
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
                if ~isa(recruitmentFigure(ii),'matlab.ui.Figure')
                    continue;
                end
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
                pptx.addPicture(recruitmentFigure(ii),'Position',[0 1 10 6.5]);
                utils.save_figure(recruitmentFigure(ii), sprintf('%s/%s/Sweep-%03d/Recruitment',EXPORT_DATA_ROOT,SUBJ,iSweep),sprintf('%s_%s_Recruitment-Curve_%s',SUBJ,muscle(iCh),recruitmentFigure(ii).UserData.GroupData));
            end
        end
    end
end

%% 7. Save Powerpoint
if exist(fullfile(EXPORT_DATA_ROOT,SUBJ),'dir')==0
    mkdir(fullfile(EXPORT_DATA_ROOT,SUBJ));
end
if isscalar(SWEEP)
    pptx.save(sprintf('%s/%s/%s_Recruitment_%03d',EXPORT_DATA_ROOT,SUBJ,SUBJ,SWEEP));
else
    pptx.save(sprintf('%s/%s/%s_Recruitment_All',EXPORT_DATA_ROOT,SUBJ,SUBJ));
end

% %%
% 
% pptx = exportToPPTX('', ...
%     'Dimensions',[10, 7.5], ...
%     'Title',sprintf("%s Recruitment Curves", SUBJ), ...
%     'Author','Max Murphy (MATLAB Auto-gen)', ...
%     'Subject',SUBJ, ...
%     'Comments',sprintf('Recruitment curves from Mouse SCS procedure %s.', SUBJ));
% muscle_index = 4;
% recruitmentFigure = batch__export_recruitment_by_pulse(T, response, CHANNEL_INDEX(muscle_index), MUSCLE(muscle_index), pptx);
% close all force;
% pptx.save('recruitment-by-pulse');