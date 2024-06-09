function T = runStimRecSweep(client, am4100, logger, options)
%RUNSTIMRECSWEEP  Returns a table of the stim/rec sweep intensity and block indices.
arguments
    client
    am4100
    logger
    options.CathodalLeading (1,1) logical = true; 
    options.Monophasic (1,1) logical = false;
    options.Channel (1,1) {mustBeMember(options.Channel,1:8)} = 1;
    options.Return (1,1) {mustBeMember(options.Return,["?","L","R","X1","X2","X3","X4","X5","X6","X7","X8","X9"])} = "?";
    options.DelayAfterSettingParameters (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterSettingParameters,0)} = 0.5; % 
    options.DelayAfterRunCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRunCommand, 0)} = 0.025;
    options.DelayAfterNameCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterNameCommand, 0)} = 0.025; 
    options.DelayAfterRecCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRecCommand, 0)} = 0.1;
    options.Intensity (:,1) double = 100;  % Amplitude of biphasic pulses (uA) 
    options.Frequency (:,1) double = 1;    % Within-burst frequency (Hz)
    options.PulseWidth (:,1) double = 200; % Microseconds for minimum pulse width
    options.PostBurstBuffer (1,1) double = 1.25; % (seconds)
    options.BurstDuration (1,1) double = 0.5; % (seconds) width of each burst in time, which determines the total number of pulses based on Frequency (rounding up)
    options.PulsesPerBurst (1,1) double = nan; % Specify as scalar to fix the number of pulses per burst instead of setting burst by duration (which is the default)
    options.PulseReductionFactor (1,1) double = 1; % Amount to scale down/widen the second phase by
    options.NBursts (1,1) double {mustBePositive, mustBeInteger} = 1;
    options.Tag {mustBeTextScalar} = 'STIM';
    options.RawDataRoot {mustBeTextScalar} = "";
    options.StartRecording (1,1) logical = true;
    options.BlockUpdateHandle = [];
    options.ProgressDialogBar = [];
    options.UDP = [];
    options.UDPRemotePort = nan;
end

% 1. Get all desired stimulation amplitudes.
nAmplitudeLevels = numel(options.Intensity);
shuffledIntensities = options.Intensity(randsample(nAmplitudeLevels, nAmplitudeLevels));
nFrequencyLevels = numel(options.Frequency);
nPulseWidthLevels = numel(options.PulseWidth);

intensity = repmat(reshape(shuffledIntensities,nAmplitudeLevels,1), nFrequencyLevels*nPulseWidthLevels, 1);
frequency = repmat(repelem(options.Frequency, nAmplitudeLevels, 1), nPulseWidthLevels, 1);
pulse_width = repelem(options.PulseWidth, nAmplitudeLevels*nFrequencyLevels, 1);
G_intensity = findgroups(intensity);
G_frequency = findgroups(frequency);

nTotalLevels = nAmplitudeLevels * nFrequencyLevels * nPulseWidthLevels;
block = nan(size(intensity));
sweep = nan(size(intensity));
n_pulses = nan(nTotalLevels, 1);
channel = ones(size(intensity)).*options.Channel;
return_channel = repmat(options.Return,numel(intensity),1);

intensityOrderStr = strjoin(cellstr(num2str(intensity)), ', ');
if ~isempty(logger)
    logger.info('IntensityOrder = %s', intensityOrderStr);
end
start_time = datetime('now');
udpSender = options.UDP;
if isnan(options.UDPRemotePort)
    udpRemotePort = 5003;
else
    udpRemotePort = options.UDPRemotePort;
end

for ii = 1:nTotalLevels
    if options.CathodalLeading
        amp = -intensity(ii);
    else
        amp = intensity(ii);
    end
    pulse_period = 1/frequency(ii);
    pw = pulse_width(ii);
    if ~isnan(options.PulsesPerBurst)
        n_pulses(ii) = options.PulsesPerBurst;
    else
        n_pulses(ii) = round(options.BurstDuration / pulse_period);
    end
    n_pulses(ii) = max(n_pulses(ii),1);
    if ~isempty(udpSender)
        packet = jsonencode(struct('Frequency', G_frequency(ii), 'Amplitude', G_intensity(ii)));
        writeline(udpSender, packet, "127.0.0.1", udpRemotePort);
    end

    levelStr = sprintf('Stim = %d uA', amp);
    if ~isempty(logger)
        logger.info(levelStr);
    end
    disp(levelStr);
    if ~isempty(options.ProgressDialogBar)
        options.ProgressDialogBar.Message = sprintf('%d-Hz: %s', frequency(ii), levelStr);
    end
    if ~isempty(client)
        block(ii) = client.UserData.block;
        sweep(ii) = client.UserData.sweep;
        if ~isempty(options.BlockUpdateHandle)
            options.BlockUpdateHandle.Value = client.UserData.block;
            drawnow();
        end
    end
    AM4100_setStimParameters(am4100, logger, ...
        amp, pw, ...
        -amp / options.PulseReductionFactor, pw * options.PulseReductionFactor, ...
        'Monophasic', options.Monophasic, ...
        'PulsePeriod', pulse_period, ...
        'PulsesPerBurst', n_pulses(ii),  ...
        'PostBurstBuffer', options.PostBurstBuffer, ...
        'NBursts', options.NBursts);
    pause(options.DelayAfterSettingParameters);
    am4100.UserData.recording_duration = (options.PostBurstBuffer + n_pulses(ii)*pulse_period)*options.NBursts;
    AM4100_stimulate(am4100, logger, client, ...
        'Tag', options.Tag, ...
        'StartRecording', options.StartRecording, ...
        'DelayAfterRunCommand', options.DelayAfterRunCommand, ...
        'DelayAfterNameCommand', options.DelayAfterNameCommand, ...
        'DelayAfterRecCommand', options.DelayAfterRecCommand, ...
        'RawDataRoot', options.RawDataRoot);
    if isempty(client)
        pause((options.PostBurstBuffer + n_pulses(ii)*pulse_period)*options.NBursts);
    else
        while (client.UserData.recording) 
            pause(0.1); % Wait 100-ms then check again.
        end
    end
    if ~isempty(options.ProgressDialogBar)
        options.ProgressDialogBar.Value = ii/nTotalLevels;
    end
    current_duration = datetime('now')-start_time;
    current_rate = current_duration / ii;
    n_remaining = nTotalLevels - ii;
    projected_remaining = current_rate * n_remaining;
    if current_duration > hours(1)
        fprintf(1,'Current sweep has lasted %4.1f hours...\n', hours(current_duration));
    elseif current_duration > minutes(1)
        fprintf(1,'Current sweep has lasted %4.1f minutes..\n', minutes(current_duration));
    else
        fprintf(1,'Current sweep has lasted %4.1f seconds.\n', seconds(current_duration));
    end
    if projected_remaining > hours(1)
        fprintf(1,'Still %4.1f hours remaining...\n', hours(projected_remaining));
    elseif projected_remaining > minutes(1)
        fprintf(1,'%4.1f minutes remaining.\n', minutes(projected_remaining));
    else
        fprintf(1,'Only %4.1f seconds remaining!\n', seconds(projected_remaining));
    end
end

is_monophasic = repmat(options.Monophasic, nTotalLevels,1);
is_cathodal_leading = repmat(options.CathodalLeading, nTotalLevels, 1);
T = table('Size',[nTotalLevels 10],'VariableTypes',{'double','double','string','double','double','double','double','double'},...
        'VariableNames',{'sweep','block','channel','return_channel','intensity','frequency','pulse_width','n_pulses','is_monophasic','is_cathodal_leading'});
T.sweep = sweep;
T.block = block;
T.channel = channel;
T.return_channel = return_channel;
T.intensity = intensity;
T.frequency = frequency;
T.pulse_width = pulse_width;
T.n_pulses = n_pulses;
T.is_monophasic = is_monophasic;
T.is_cathodal_leading = is_cathodal_leading;

% T = table(sweep, block, channel, return_channel, intensity, frequency, pulse_width, n_pulses, is_monophasic, is_cathodal_leading);
T.Properties.UserData = struct(...
    'Parameters', options, ...
    'TStart', start_time, ...
    'Duration', datetime('now')-start_time);

if ~isempty(client)
    tank = sprintf('%s_%04d_%02d_%02d', ...
        client.UserData.subject, client.UserData.year, ...
        client.UserData.month, client.UserData.day);
    sweep_folder = sprintf('%s_%d', tank, client.UserData.sweep);
    subject_folder = fullfile(options.RawDataRoot, client.UserData.subject);
    save_folder = fullfile(subject_folder, tank, sweep_folder);
    writetable(T, fullfile(save_folder, sprintf('%s.xlsx', sweep_folder)));
    save(fullfile(save_folder, sprintf('%s_Table.mat', sweep_folder)), 'T', '-v7.3');
    
    % Parse metadata overview and make a summary spreadsheet/file as well
    overview_file = fullfile(subject_folder,sprintf("%s.xlsx",tank));
    if exist(overview_file,'file')==0
        S = [];
    else
        S = readtable(overview_file);
    end
    s = table('Size',[1 10],'VariableTypes',{'double','double','string','logical','logical','double','double','double','double','double'},...
        'VariableNames',{'Sweep','Stim_Channel','Return_Channel','Monophasic','CathodalLeading','Min_Intensity','Max_Intensity','Intensity_Step','Min_Frequency','Max_Frequency'});

    s.Sweep = client.UserData.sweep;
    s.Stim_Channel = T.channel(1);
    s.Return_Channel = T.return_channel(1);
	s.Monophasic = options.Monophasic;
	s.CathodalLeading = options.CathodalLeading;
    s.Min_Intensity = min(T.intensity);
    s.Max_Intensity = max(T.intensity);
    all_intensity_asc = sort(unique(T.intensity),'ascend');
    s.Intensity_Step = mode(diff(all_intensity_asc));
    s.Min_Frequency = min(T.frequency);
    s.Max_Frequency = max(T.frequency);
    S = [S; s];
    writetable(S, overview_file);
    save(fullfile(subject_folder,sprintf('%s.mat',tank)),'S','-v7.3');

    client.UserData.sweep = client.UserData.sweep + 1;
    client.UserData.block = 0;
end
end