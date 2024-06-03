%EXAMPLE_LOAD_AND_PROCESS_INTAN

close all force;
clc;
clear;

%% 1. Set parameters
% % % Recording-specific metadata parameters % % %
SUBJ = "Test";
YYYY = 2024;
MM = 5;
DD = 13;
SWEEP = 0;
RAW_DATA_ROOT = "C:/Data/SCS";
% RAW_DATA_ROOT = parameters('raw_data_folder_root'); % see: parameters.m

% % % Parameters for response estimation % % %
DIG_IN_SYNC_CHANNEL_NUMBER = 2; % Index of DIG_IN connector used for stim onset sync signals
TLIM_SNIPPETS = [-0.003, 0.009]; % Seconds (for signal indexing, relative to each stim onset)
TLIM_RESPONSE = [0.002, 0.004]; % Seconds (for estimating power in evoked signal, relative to stim onset)
TLIM_BASELINE = [-0.002, 0.000]; % Seconds (for normalizing responses, relative to stim onset)


%% 2. Load data
[~,intan,T] = loadData(SUBJ,YYYY,MM,DD,SWEEP, ...
    'LoadSAGA',false, ...
    'RawDataRoot',RAW_DATA_ROOT);
[muscle, channel_index] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));

%% 3. Index and filter data, estimate responses
[snips, t, response_normed, response_raw, filtering, fdata] =  ...
    intan_amp_2_snips(intan, ...
        "TLim",TLIM_SNIPPETS, ...
        "TLimResponse", TLIM_RESPONSE, ...
        "TLimBaseline", TLIM_BASELINE, ...
        "DigInSyncChannel", DIG_IN_SYNC_CHANNEL_NUMBER, ...
        "Verbose", true, ...
        'FilterParameters',{'ApplyCAR',false,'BlankArtifactBeforeFiltering',true,'CutoffFrequency',100});

%% 4. Quick heuristic to visualize responses across all channels
SNIPPET_BLOCK = 8; % Ad hoc block selection for visualizing

[boxPlotFigure, response_channels, non_response_channels] = plotResponseBoxes( ...
    response_raw{SNIPPET_BLOCK}(:,channel_index),...
    'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD, ...
    'Sweep', SWEEP, 'Block', SNIPPET_BLOCK', 'Muscle', muscle);

%% 5. Plot selected examples of response snippets
snippetStackFigure = plotResponseSnippets(t.*1e3, ...
    snips{SNIPPET_BLOCK}, channel_index, T, ...
    'XLabel', 'Time (ms)', ...
    'YOffset', 2500, ...
    'Muscle', muscle, ...
    'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD, ...
    'Sweep', SWEEP, 'Block', SNIPPET_BLOCK);

%% 6. Plot response curves

% for ii = 1:numel(channel_index)
for ii = 1
    fig = plotRecruitment(T, response_raw, channel_index(ii), muscle(ii));
end