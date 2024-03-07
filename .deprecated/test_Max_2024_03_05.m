%TEST_MAX_2024_03_05  Script for testing/setup prior to experiment
clear;
clc;

%% 1. Create all connections/logging
[client, am4100, logger] = initInterfaces('Subject', 'Max');

% %% 2. Initialize the stimulator with desired parameters
% AM4100_setStimParameters(am4100, logger, 1000, 150, -250, 600, 1.5, 10);

% %% 3. Record impedances from TMSi SAGA
% SAGA_impedances(client, logger);
% keyboard;

% %% 4. Begin stimulation and recording. 
% AM4100_stimulate(am4100, logger, client);



%% Run stimulation/recording sweep

T = runStimRecSweep(client, am4100, logger, 2000);
disp(T);
