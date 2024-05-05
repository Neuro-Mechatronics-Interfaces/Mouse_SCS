%EXAMPLE_RUN_EXPERIMENT  Script for testing/setup prior to experiment
clear;
clc;

%% 0. Set network parameters etc.
IPV4_ADDRESS_AM4100 = "10.0.0.80";  % Network Address of AM4100 unit
IPV4_ADDRESS_INTAN = "127.0.0.1";   % Device running Intan acquisition
IPV4_ADDRESS_TMSI  = "127.0.0.1";   % Device running TMSi acquisition

START_SWEEP = 0; % Modify this if you have to reset in the middle.
START_BLOCK = 0; % Modify this if you have to reset in the middle. 
SUBJECT_NAME = "Test";  % Name of the subject 

%% 1. Create all connections/logging
[client, am4100, logger] = initInterfaces( ...
    'Subject', SUBJECT_NAME, ...
    'Sweep', START_SWEEP, ...
    'Block', START_BLOCK, ...
    'AddressTMSi', IPV4_ADDRESS_TMSI, ...
    'AddressAM4100', IPV4_ADDRESS_AM4100, ...
    'AddressIntan', IPV4_ADDRESS_INTAN);

% %% 2. Record impedances from TMSi SAGA
% SAGA_impedances(client, logger);
% keyboard;

%% 3. Run stimulation/recording sweep
% for freq = [40,80,160]
%     for amp = 500:50:600
%         for ii = 1:10
%             fprintf(1,'%d) Freq: %d Hz - Amp: %d uA\n', ii, freq, amp);
%             pulse_period = 1/freq;
%             pulse_reps = round(0.5 / pulse_period); 
%             runStimRecSweep(client, am4100, logger, ...
%                 'Intensity', amp, ...
%                 'Frequency', freq, ...
%                 'PulseRepetitions', pulse_reps, ...
%                 'MinIntensity', abs(amp), ...
%                 'NBursts', 10);
%         end
%     end
% end

T = runStimRecSweep(client, am4100, logger, ...
    'Intensity', [500 550 600], ...
    'Frequency', [1 10 100], ...
    'PulsesPerBurst', 10, ...
    'NBursts', 2);
disp(T);

% %% 4. 
% T = runStimRecSweepFreqs(client, am4100, logger, [5, 10, 20, 40, 80, 160]); 
% disp(T);