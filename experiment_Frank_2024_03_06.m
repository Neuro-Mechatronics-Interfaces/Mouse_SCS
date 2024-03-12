%EXPERIMENT_FRANK_2024_03_06  Script for testing/setup prior to experiment
clear;
clc;

%% 1. Create all connections/logging
[client, am4100, logger] = initInterfaces('Subject', 'Frank', 'Sweep', 4);

%% 2. Record impedances from TMSi SAGA
SAGA_impedances(client, logger);
keyboard;

%% 3. Run stimulation/recording sweep
% for freq = [40,80,160]
%     for amp = 500:50:600
%         for ii = 1:10
%             fprintf(1,'%d) Freq: %d Hz - Amp: %d uA\n', ii, freq, amp);
%             pulse_period = 1/freq;
%             pulse_reps = round(0.5 / pulse_period); 
%             runStimRecSweep(client, am4100, logger, amp, ...
%                 'PulsePeriod', pulse_period, ...
%                 'PulseRepetitions', pulse_reps, ...
%                 'MinIntensity', abs(amp), ...
%                 'NBursts', 10);
%         end
%     end
% end
If i

% T = runStimRecSweep(client, am4100, logger, -800, 'InterPulsePeriod', 1, 'PulseRepetitions', 10, 'MinIntensity',500, 'IntensityStep', 100);
% disp(T);

%% 4. 
% T = runStimRecSweepFreqs(client, am4100, logger, [5, 10, 20, 40, 80, 160]); 
% disp(T);