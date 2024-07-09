%EXPORTING_2024_07_02  Exporting curve data from 2024-07-02 procedure.
%#ok<*UNRCH>
%#ok<*AGROW>
close all force;
clc;
clear;

%% 1. Set parameters
% % % Recording-specific metadata parameters % % %
SUBJ = "Pilot_SCS_N_CEJ_05";
YYYY = 2024;
MM = 7;
DD = 2;
SWEEP = 0:66;

PLOT_ALL_FDATA = false;
RAW_DATA_ROOT = "C:/Data/SCS";
% RAW_DATA_ROOT = parameters('raw_data_folder_root');
EXPORT_DATA_ROOT = parameters('local_export_folder');

% % % Parameters for response estimation % % %
DIG_IN_SYNC_CHANNEL_NUMBER = 2; % Index of DIG_IN connector used for stim onset sync signals
TLIM_SNIPPETS = [-0.002, 0.006]; % Seconds (for signal indexing, relative to each stim onset)
MUSCLE_RESPONSE_TIMES_FILE = "Muscle_Response_Times_Exponential.xlsx";
[MUSCLE, CHANNEL_INDEX] = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJ));
muscle = MUSCLE(CHANNEL_INDEX);
RECRUITMENT_PULSE_INDEX = 1;
DETREND_MODE = 'exp';
POLY_ORDER = []; % Leave empty to use values in file otherwise specify global value to override file-specific polynomial detrend order

%% 2. Iterate over sweeps
iCount = 0;
N = numel(SWEEP);
S = [];
response = cell(N,1);
blip = cell(N,1);
trend = cell(N,1);

fprintf(1,'Please wait, collecting %d response curves...000%%\n',N);
for iSweep = SWEEP
    iCount = iCount + 1;
    [~,intanData,T] = loadData(SUBJ,YYYY,MM,DD,iSweep, ...
        'LoadSAGA',false, ...
        'RawDataRoot',RAW_DATA_ROOT, ...
        'Verbose', false);
    [T.long_name,T.short_name] = metadata_2_title(T);
    S = [S; T]; 

    % 3. Index and filter data, estimate responses
    [~, t, response{iCount}, blip{iCount}, filtering, fdata, trend{iCount}] =  ...
        intan_amp_2_snips(intanData, ...
            "Channels", CHANNEL_INDEX, ...
            "TLim",TLIM_SNIPPETS, ...
            "DetrendMode",DETREND_MODE,...
            "PolyOrder",POLY_ORDER,...
            "Muscle", MUSCLE, ... 
            "MuscleResponseTimesFile", MUSCLE_RESPONSE_TIMES_FILE, ...
            "DigInSyncChannel", DIG_IN_SYNC_CHANNEL_NUMBER, ...
            "Verbose", false, ...
            'FilterParameters',{'ApplyFiltering', true});
    fprintf(1,'\b\b\b\b\b%03d%%\n',round(iCount*100/N));
end

%% 4. Save output
S.Response_Curve_Value_By_Channel = cellfun(@(C){C'},vertcat(response{:}));
S.Blip_By_Channel = vertcat(blip{:});
S.Removed_Part_By_Channel = vertcat(trend{:});
S.Properties.UserData = struct;
S.Properties.UserData.Muscle = categorical(1:numel(muscle),1:numel(muscle),muscle);
S.Properties.UserData.Filtering = filtering;
S.Properties.UserData.DetrendMode = DETREND_MODE;
[S.Properties.UserData.TLimBlip, S.Properties.UserData.PolyOrder] = load_muscle_response_times(muscle,"CalibrationFile",MUSCLE_RESPONSE_TIMES_FILE);
S.Properties.UserData.Subject = SUBJ;
S.Properties.UserData.Year = YYYY;
S.Properties.UserData.Month = MM;
S.Properties.UserData.Day = DD;
S.Properties.UserData.CData = winter(numel(muscle)).*0.65;
T = aggregate_table_2_granular_table(S);
save(fullfile(EXPORT_DATA_ROOT,sprintf('%s_Responses.mat',SUBJ)), 'S','T','-v7.3');
writetable(T,fullfile(EXPORT_DATA_ROOT,sprintf('%s_Responses.xlsx',SUBJ)));