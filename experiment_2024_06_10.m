%%EXPERIMENT_2024_06_10  Runs experiment (2024-06-10: Pilot-4).

SUBJECT_NAME = "Pilot_SCS_N_CEJ_04";  % Name of the subject
START_SWEEP = 44; % Modify this if you have to reset in the middle.
START_BLOCK = 0; % Modify this if you have to reset in the middle. 
RAW_DATA_ROOT = parameters('raw_data_folder_root'); % Should be correct on NML Rodent lab computer

AMPLIFIER_CHANNELS = 0:15;
AMPLIFIER_PORT = 'b';

IPV4_ADDRESS_AM4100 = "10.0.0.80";  % Network Address of AM4100 unit
IPV4_ADDRESS_INTAN = "127.0.0.1";   % Device running Intan acquisition
IPV4_ADDRESS_TMSI  = "127.0.0.1";   % Device running TMSi acquisition


MAP_NAME_LOCAL = sprintf('%s_Channel_Map.txt',SUBJECT_NAME);
DATA_TANK_ROOT = fullfile(RAW_DATA_ROOT,SUBJECT_NAME);
if exist(DATA_TANK_ROOT,'dir')==0
    mkdir(DATA_TANK_ROOT);
end
MAP_NAME_REMOTE = fullfile(RAW_DATA_ROOT, MAP_NAME_LOCAL);
if exist(MAP_NAME_LOCAL,'file')==0
    copyfile('Default_Mouse_EMG_Channel_Map.txt', MAP_NAME_REMOTE);
else
    copyfile(MAP_NAME_LOCAL, MAP_NAME_REMOTE); 
end

STIM_ENABLE = true;
INTAN_ENABLE = true;

if INTAN_ENABLE
    intanTcpClient = tcpclient("127.0.0.1", 5000);
    intanTcpClient.configureCallback("byte", 1, @(src,~)fprintf(read(src)));
    intan.enablePortChannelBatch(intanTcpClient, AMPLIFIER_PORT, AMPLIFIER_CHANNELS, 'EnableTCP', false);
    intan.enableAudio(intanTcpClient);
    intan.enableDigIn(intanTcpClient);
end

%% Initialize interfaces
[client, am4100, logger] = initInterfaces( ...
    'UseAM4100', STIM_ENABLE, ...
    'UseIntan', INTAN_ENABLE, ...
    'Subject', SUBJECT_NAME, ...
    'Sweep', START_SWEEP, ...
    'Block', START_BLOCK, ...
    'AddressTMSi', IPV4_ADDRESS_TMSI, ...
    'AddressAM4100', IPV4_ADDRESS_AM4100, ...
    'AddressIntan', IPV4_ADDRESS_INTAN, ...
    'IntanClient', intanTcpClient);

%% Run stimulation/recording sweep via GUI
fig = init_stim_rec_sweep_gui(client, am4100, logger);