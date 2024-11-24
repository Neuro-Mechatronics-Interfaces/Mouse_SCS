%EXPORT_SOMATOTOPY_2024_07_02  Export Somatotopy curves for CEJ-05 (2024-07-02)

clear;
close all force;
clc;

SUBJ = 'Pilot_SCS_N_CEJ_05';
NAME = 'CEJ-05';
DATE = '2024-07-02';
EXPORT_DATA_ROOT = parameters('local_export_folder');
T = getfield(load(sprintf('%s/%s_Responses.mat',EXPORT_DATA_ROOT,SUBJ), 'T'),'T');

RET_OPT = {'R'};
% AMP_OPT = [3000,3500,4000,4500,5000]; 
% FREQ_OPT = [5, 10, 20, 40];
% PULSE_OPT = [2, 2, 2, 2];
AMP_OPT = 4000;
FREQ_OPT = 40;
PULSE_OPT = 2;

for iFreqPulse = 1:numel(FREQ_OPT)
    freq = FREQ_OPT(iFreqPulse);
    pulse_index = PULSE_OPT(iFreqPulse);
    for iRet = 1:numel(RET_OPT)
        ret_ch = RET_OPT{iRet};
        for iAmp = 1:numel(AMP_OPT)
            amp = AMP_OPT(iAmp);
            [data, somatotopicOutput] = granular_table_2_somatotopy_data(T, ...
                'Intensity', amp, ...
                'Frequency', freq, ...
                'Return_Channel', ret_ch, ...
                'TrainPulseIndex', pulse_index);
            somatObj = Somatotopy('Data', data, ...
                'SomatotopicOutput', somatotopicOutput, ...
                'Title', sprintf('%s: %s', NAME, DATE), ...
                'Subtitle', sprintf('%d \\muA | %d-Hz | %s-Return | pulse-%d ', amp, freq, ret_ch, pulse_index));
            utils.save_figure(somatObj.fig, fullfile(EXPORT_DATA_ROOT,SUBJ,'Somatotopy'), ...
                sprintf('%s_%duA_%dHz_%s-Ret_pulse-%d', NAME, amp, freq, ret_ch, pulse_index), ...
                'ExportAs', {'.png'}, 'SaveFigure', true);
            delete(somatObj);
        end
    end
end
