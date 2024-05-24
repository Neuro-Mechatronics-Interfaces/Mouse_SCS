%%EXAMPLE_QUICK_CONNECT_INTAN  Template for connecting to Intan/running experimental sweeps.
AMPLIFIER_CHANNELS = 0:15;
ANALOG_CHANNELS = 1;
DIG_IN_PRESENT = true;
SAMPLE_RATE = 20000;
% INTENSITIES = 500:50:650;
INTENSITIES = [500:500:1500];
FREQUENCIES = [1, 10, 100];
% FREQUENCIES = 100;
PULSES_PER_BURST = 10;
BURST_REPETITIONS = 5;
% BURST_REPETIONS = 3;
STIM_CHANNEL = 1;
AMPLIFIER_PORT = 'b';

intanTcpClient = tcpclient("127.0.0.1", 5000);
intanTcpClient.configureCallback("byte", 1, @(src,~)fprintf(read(src)));
waveformTcpClient = tcpclient("127.0.0.1", 5001);
numAmplifierBands = intan.enablePortChannelBatch(intanTcpClient, AMPLIFIER_PORT, AMPLIFIER_CHANNELS);
numAnalogChannels = numel(ANALOG_CHANNELS);
for ii = 1:numAnalogChannels
    intan.setAnalogTCP(intanTcpClient,ANALOG_CHANNELS(ii),1); % 1 analog channel present (parameter 3)
end
if DIG_IN_PRESENT
    intan.setDigitalTCP(intanTcpClient,1,1);
    intan.setDigitalTCP(intanTcpClient,2,1); % Yes, digital "words" are present (parameter 4)
end
numBlocksPerRead = ceil(1/0.0064); % At 20kHz we expect 6.4 milliseconds per data frame (128 bytes per frame / 20000 <SAMPLE_RATE> samples per second)
numSamplesPerBlock = numBlocksPerRead * 128; % We will pull in just over 1 second of samples each tick.
waveformBytesTotal = intan.computeBytesPerBlock(numBlocksPerRead, numAmplifierBands, numel(ANALOG_CHANNELS), DIG_IN_PRESENT, 1);
waveformTcpClient.UserData = intan.initWaveformBytesGraphicsHandles(numAmplifierBands, numAnalogChannels, DIG_IN_PRESENT, ...
    'NumPointsToPlot', numSamplesPerBlock, ...
    'NumAmplitudes', numel(INTENSITIES), ...
    'NumFrequencies', numel(FREQUENCIES), ...
    'NumTriggersSaved', BURST_REPETITIONS, ...
    'SampleRate', SAMPLE_RATE);
configureCallback(waveformTcpClient,"byte",waveformBytesTotal,@intan.handleWaveformBytesCallback);

%%
IPV4_ADDRESS_AM4100 = "10.0.0.80";  % Network Address of AM4100 unit
IPV4_ADDRESS_INTAN = "127.0.0.1";   % Device running Intan acquisition
IPV4_ADDRESS_TMSI  = "127.0.0.1";   % Device running TMSi acquisition

START_SWEEP = 0; % Modify this if you have to reset in the middle.
START_BLOCK = 0; % Modify this if you have to reset in the middle. 
SUBJECT_NAME = "Pilot_SCS_N_CEJ_01";  % Name of the subject
RAW_DATA_ROOT = parameters('raw_data_folder_root'); % Should be correct on NML Rodent lab computer

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
% RAW_DATA_ROOT = "C:/Data/SCS";
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
% am4100.UserData.intan = intanTcpClient;
% am4100.UserData.timer = timer(...
%             'TimerFcn', @(~,~)INTAN_stop(intan_client, logger), ...
%             'StartDelay', 20);

T = runStimRecSweep(client, am4100, logger, ...
    'Channel', STIM_CHANNEL, ...
    'Intensity', INTENSITIES, ...
    'Frequency', FREQUENCIES, ...
    ...'PulsesPerBurst', PULSES_PER_BURST, ... % DO NOT SPECIFY THIS!!!
    'NBursts', BURST_REPETITIONS, ...
    'RawDataRoot', RAW_DATA_ROOT, ...
    'UDP', udpport, ...
    'UDPRemotePort', waveformTcpClient.UserData.UDP.LocalPort);
disp(T);

% muscle = load_channel_map(sprintf('%s_Channel_Map.txt',SUBJECT_NAME));


% pause(1.0);
% [data, timestamp] = intan.readWaveformByteBlock(waveformTcpClient, numAmplifierBands, 1, 1);
% intan.stopRunning(intanTcpClient);
% waveformTcpClient.flush(); % Make sure no "lingering bytes" that will mess us up next time. 