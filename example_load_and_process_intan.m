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
% RAW_DATA_ROOT = parameters('raw_data_folder_root');

% % % Parameters for response estimation % % %
DIG_IN_SYNC_CHANNEL_NUMBER = 2; % Index of DIG_IN connector used for stim onset sync signals
TLIM_SNIPPETS = [-0.02, 0.010]; % Seconds (for signal indexing, relative to each stim onset)
TLIM_RESPONSE = [0.003, 0.008]; % Seconds (for estimating power in evoked signal, relative to stim onset)
TLIM_BASELINE = [-0.02, 0.000]; % Seconds (for normalizing responses, relative to stim onset)


%% 2. Load data
[~,intan,T] = loadData("Test",YYYY,MM,DD,SWEEP, ...
    'LoadSAGA',false, ...
    'RawDataRoot',RAW_DATA_ROOT);

%% 3. Index and filter data, estimate responses
[snips, t, response_normed, response_raw, filtering] =  ...
    intan_amp_2_snips(intan, ...
        "TLim",TLIM_SNIPPETS, ...
        "TLimResponse", TLIM_RESPONSE, ...
        "TLimBaseline", TLIM_BASELINE, ...
        "DigInSyncChannel", DIG_IN_SYNC_CHANNEL_NUMBER, ...
        "Verbose", true);

%% 4. Quick heuristic to visualize responses across all channels
SNIPPET_BLOCK = 16; % Ad hoc block selection for visualizing

[boxPlotFigure, response_channels, non_response_channels] = plotResponseBoxes( ...
    response_normed{SNIPPET_BLOCK},...
    'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD, ...
    'Sweep', SWEEP, 'Block', SNIPPET_BLOCK);

%% 5. Plot selected examples of response snippets

my_cmap = [ repmat([0.8 0.1 0.2], 3, 1); ...
            repmat([0.2 0.1 0.8], numel(response_channels), 1)];
snippetStackFigure = plotResponseSnippets(t.*1e3, snips{SNIPPET_BLOCK}, [non_response_channels(1:3),response_channels], ...
    'XLabel', 'Time (ms)', ...
    'CMapData', my_cmap, ...
    'Subject', SUBJ, 'Year', YYYY, 'Month', MM, 'Day', DD, ...
    'Sweep', SWEEP, 'Block', SNIPPET_BLOCK);