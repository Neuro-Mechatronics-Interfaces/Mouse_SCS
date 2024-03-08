function T = runStimRecSweepFreqs(client, am4100, logger, frequency, options)
%RUNSTIMRECSWEEPFREQS  Returns a table of the stim/rec sweep intensity and block indices.
arguments
    client
    am4100
    logger
    frequency (:, 1) double % Maximum intensity (uA)
    options.PulseWidth (1,1) double = 200; % Microseconds for minimum pulse width
    options.PostStimBuffer (1,1) double = 2; % Seconds
    options.Amplitude (1,1) double = -300; % Microamperes (A1)
    options.Duration (1,1) double = 0.5; % Seconds
    options.NBursts (1,1) double = 10; % Bursts
end

nLevels = numel(frequency);
block = nan(size(frequency));
sweep = nan(size(frequency));
intensity = nan(size(frequency));

freqOrderStr = strjoin(cellstr(num2str(frequency)), ', ');
logger.info('FreqOrder = %s', freqOrderStr);

for ii = 1:nLevels
    intensity(ii) = options.Amplitude;
    levelStr = sprintf('Stim = %d Hz', frequency(ii));
    logger.info(levelStr);
    disp(levelStr);
    block(ii) = client.UserData.block;
    sweep(ii) = client.UserData.sweep;
    
    inter_pulse_period = round(1e6 / frequency(ii));
    n_pulses = round(options.Duration * 1e6 / inter_pulse_period);
    fprintf(1,'Number of pulses: %d\n', n_pulses);
    if ~isempty(am4100.UserData.timer)
        am4100.UserData.timer.StartDelay = n_pulses * inter_pulse_period + options.PostStimBuffer;
    end
    AM4100_setStimParameters(am4100, logger, ...
        options.Amplitude, options.PulseWidth, ...
        -options.Amplitude, options.PulseWidth, ...
        inter_pulse_period, n_pulses);
    if ~isempty(client)
        SAGA_record(client, logger, ...
            'SagaCommandPauseDuration', 0.050, ...
            'Tag', 'STIM', ...
            'Block', client.UserData.block, ...
            'Intan', am4100.UserData.intan, ...
            'Timer', []);
    end
    for iBurst = 1:options.NBursts
        logger.info('Begin Stimulation');
        AM4100_stimulate(am4100, logger, client, 'StartRecording', false);
        pause(inter_pulse_period*n_pulses + options.PostStimBuffer);
    end
    SAGA_stop(client, logger, 'Intan', am4100.UserData.intan);
end
T = table(sweep, block, intensity, frequency);
if ~isempty(client)
    tank = sprintf('%s_%04d_%02d_%02d', ...
        client.UserData.subject, client.UserData.year, ...
        client.UserData.month, client.UserData.day);
    sweep_folder = sprintf('%s_%d', tank, client.UserData.sweep);
    save_folder = fullfile(parameters('raw_data_folder_root'), ...
        client.UserData.subject, tank, sweep_folder);
    
    writetable(T, fullfile(save_folder, sprintf('%s.xlsx', sweep_folder)));
    
    client.UserData.sweep = client.UserData.sweep + 1;
    client.UserData.block = 0;
end

end