%AGGREGATE_SWEEPS_2024_07_02
clear;
clc;

%% 1. Set parameters
% % % Recording-specific metadata parameters % % %
SUBJ = "Pilot_SCS_N_CEJ_05";
YYYY = 2024;
MM = 7;
DD = 2;

PLOT_ALL_FDATA = false;
RAW_DATA_ROOT = "C:/Data/SCS";
% RAW_DATA_ROOT = parameters('raw_data_folder_root');
EXPORT_DATA_ROOT = parameters('local_export_folder');

%% 2. Load aggregated data table (see `exporting_2024_07_02.m`, `aggregate_table_2_granular_table.m` for details)
T = getfield(load(fullfile(EXPORT_DATA_ROOT,sprintf('%s_Responses.mat',SUBJ)), 'T'),'T');

%% 3a. First sub-table is sweeps 28-39: 1-Hz contact 1-6 L/R intensity curves
%  (See: https://docs.google.com/presentation/d/1UvYe2KhSLN36dTu-NWLm647n3b-05qxs4wDSpP6_3jU/edit#slide=id.g2ea862d00fc_0_7)
A = T((T.sweep >= 28) & (T.sweep <= 39),:);
all_muscle = unique(A.Muscle);

%% 3b. Make the figure
fig = gobjects(size(all_muscle));
for ii = 1:numel(all_muscle)
    fig(ii) = plot_spatial_intensity_curves(A, all_muscle(ii));
end

%% 3c. Save these figures
for ii = 1:numel(fig)
    utils.save_figure(fig(ii), fullfile(EXPORT_DATA_ROOT, SUBJ, 'Spatial-Recruitment'), sprintf('%s_%s-Recruitment-Curves', SUBJ, fig(ii).UserData.Muscle));
end