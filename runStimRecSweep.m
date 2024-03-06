function T = runStimRecSweep(client, am4100, logger, maxIntensity, options)
%RUNSTIMRECSWEEP  Returns a table of the stim/rec sweep intensity and block indices.
arguments
    client
    am4100
    logger
    maxIntensity (1,1) double % Maximum intensity (uA)
    options.Levels (1,1) double = 10; % Number of stimulation intensities for recruitment curve
    options.MinIntensityScale (1,1) double = 0.1; % Scalar for setting minimum intensity bound
    options.PulseWidthMin (1,1) double = 200; % Microseconds for minimum pulse width
    options.InterPulsePeriod (1,1) double = 5; % Seconds between pulses
    options.PulseRepetitions (1,1) double = 10; % Number of repetitions for averaging
    options.PulseReductionFactor (1,1) double = 1; % Amount to scale down/widen the second phase by
end

allIntensities = round(linspace(options.MinIntensityScale * maxIntensity, maxIntensity, options.Levels));
shuffledIntensities = allIntensities(randsample(options.Levels, options.Levels));
intensity = reshape(shuffledIntensities, options.Levels, 1);
block = nan(size(intensity));
sweep = nan(size(intensity));
intensityOrderStr = strjoin(cellstr(num2str(intensity)), ', ');
logger.info('IntensityOrder = %s', intensityOrderStr);

for ii = 1:options.Levels
    amp = intensity(ii);
    levelStr = sprintf('Stim = %d uA', amp);
    logger.info(levelStr);
    disp(levelStr);
    block(ii) = client.UserData.block;
    sweep(ii) = client.UserData.sweep;
    AM4100_setStimParameters(am4100, logger, ...
        amp, options.PulseWidthMin, ...
        -amp / options.PulseReductionFactor, options.PulseWidthMin * options.PulseReductionFactor, ...
        options.InterPulsePeriod, options.PulseRepetitions);
    pause(0.5);
    AM4100_stimulate(am4100, logger, client);
    while (client.UserData.recording) 
        pause(0.1); % Wait 100-ms then check again.
    end
end
tank = sprintf('%s_%04d_%02d_%02d', ...
    client.UserData.subject, client.UserData.year, ...
    client.UserData.month, client.UserData.day);
sweep = sprintf('%s_%d', tank, client.UserData.sweep);
save_folder = fullfile(parameters('raw_data_folder_root'), ...
    client.UserData.subject, tank, sweep);

T = table(sweep, block, intensity);
writetable(T, fullfile(save_folder, sprintf('%s.xlsx', sweep)));

client.UserData.sweep = client.UserData.sweep + 1;
client.UserData.block = 0;


end