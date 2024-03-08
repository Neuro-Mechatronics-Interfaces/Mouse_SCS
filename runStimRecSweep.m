function T = runStimRecSweep(client, am4100, logger, maxIntensity, options)
%RUNSTIMRECSWEEP  Returns a table of the stim/rec sweep intensity and block indices.
arguments
    client
    am4100
    logger
    maxIntensity (1,1) double % Maximum intensity (uA)
    options.MinIntensity (1,1) double = 100; % Scalar for setting minimum intensity bound
    options.IntensityStep (1,1) double = 50; % Scalar for step size on intensity sweep
    options.PulseWidthMin (1,1) double = 200; % Microseconds for minimum pulse width
    options.InterPulsePeriod (1,1) double = 1; % Seconds between pulses
    options.PostStimBuffer (1,1) double = 2; % Seconds
    options.PulseRepetitions (1,1) double = 10; % Number of repetitions for averaging
    options.PulseReductionFactor (1,1) double = 1; % Amount to scale down/widen the second phase by
end
signIntensity = sign(maxIntensity);
allIntensities = options.MinIntensity : options.IntensityStep : abs(maxIntensity);
allIntensities = allIntensities .* signIntensity;
nLevels = numel(allIntensities);
shuffledIntensities = allIntensities(randsample(nLevels, nLevels));
intensity = reshape(shuffledIntensities, nLevels, 1);
block = nan(size(intensity));
sweep = nan(size(intensity));
intensityOrderStr = strjoin(cellstr(num2str(intensity)), ', ');
if ~isempty(logger)
    logger.info('IntensityOrder = %s', intensityOrderStr);
end
for ii = 1:nLevels
    amp = intensity(ii);
    levelStr = sprintf('Stim = %d uA', amp);
    if ~isempty(logger)
        logger.info(levelStr);
    end
    disp(levelStr);
    if ~isempty(client)
        block(ii) = client.UserData.block;
        sweep(ii) = client.UserData.sweep;
    end
    if ~isempty(am4100.UserData.timer)
        am4100.UserData.timer.StartDelay = options.PulseRepetitions * options.InterPulsePeriod + options.PostStimBuffer;
    end
    AM4100_setStimParameters(am4100, logger, ...
        amp, options.PulseWidthMin, ...
        -amp / options.PulseReductionFactor, options.PulseWidthMin * options.PulseReductionFactor, ...
        options.InterPulsePeriod, options.PulseRepetitions, 'TBuffer', options.PostStimBuffer);
    pause(0.5);
    AM4100_stimulate(am4100, logger, client);
    if isempty(client)
        pause(options.PostStimBuffer + options.PulseRepetitions*options.InterPulsePeriod);
    else
        while (client.UserData.recording) 
            pause(0.1); % Wait 100-ms then check again.
        end
    end
end
T = table(sweep, block, intensity);
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