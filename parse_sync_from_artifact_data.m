function [sync, rising_signal, rising_trigger] = parse_sync_from_artifact_data(data, orig, options)
%PARSE_SYNC_FROM_ARTIFACT_DATA  Parse sync TTL from data vector using timing/amplitude assumptions & prior knowledge on when TTL would have occurred.
%
% Syntax:
%   [sync, rising_signal, rising_trigger] = parse_sync_from_artifact_data(data, orig);
%   [sync, rising_signal, rising_trigger] = parse_sync_from_artifact_data(__,'Name',value,...);
%
% See also: Contents, plotSagaRecruitmentRaw, loadData

arguments
    data (1,:) {mustBeNumeric}                                                  % 1 x nSamples vector of numeric data representing some signal with artifact where we want to recover the TTL pulses
    orig (1,:) {mustBeNumeric}                                                  % 1 x nSamples vector of original sync data
    options.Bit (1,1) double {mustBeInteger,mustBeInRange(options.Bit,0,15)} = 12; % Sync bit for original sync triggers vector.
    options.ExpectedPulses (1,1) double {mustBeInteger, mustBePositive} = 10;   % expected number of stim pulses in data signal
    options.OriginalSyncSampleJitter (1,1) double {mustBeInteger} = 20;         % Sample jitter for matching up first parsed sample with original sync vector
    options.PulseCountTolerance (1,1) {mustBeInteger} = 0;                      % Tolerance for number of pulses
    options.ExpectedPeriod (1,1) double = 1;                                    % expected period for stim events (seconds)
    options.KeepFirstTriggerEdge (1,1) logical = false;                         % Keep first TRIGGERS logic edge
    options.PeriodTolerance (1,1) double = 0.002;                               % Tolerance for periodicity (seconds)
    options.SampleRate (1,1) double = 4000;                                     % data vector sample rate
    options.StimEventDebounce (1,1) double = 0.5;                               % Seconds between events
    options.SyncBit (1,1) double {mustBeMember(options.SyncBit,0:15)} = 12;     % Should be a bit, where 0 is the LSB and 15 is MSB, refers to which TRIGGERS port the sync signal comes in on.
    options.ThresholdDeviations (1,1) double = 10;                              % Sign determines direction of leading peak.
    options.TriggerSignalOffset (1,1) double = 0.00                             % Offset between rising edge of detected pulses (seconds)
    options.TriggerPulseWidth (1,1) double = 0.00025;                           % Width of trigger sync TTL pulses (seconds)
    options.Verbose (1,1) logical = false;                                      % Set true to provide Verbose command window print statements.
end

sync = zeros(size(data));
sync(2:end) = 2^options.SyncBit;

data = data - median(data);
sigma = median(abs(data)); % Use median absolute deviation to help with stim artifact part
threshold = abs(options.ThresholdDeviations) * sigma;

suprathreshold = (data.*sign(options.ThresholdDeviations)) > threshold;

n_samples_debounce = options.StimEventDebounce * options.SampleRate;

HIGH = find(suprathreshold);
if isempty(HIGH)
    rising_signal = [];
    rising_trigger = [];
    warning("No triggers identified.");
    return;
end

rising_signal = nan(options.ExpectedPulses,1);
i_compare = 1;
i_assign = 2;
rising_signal(1) = HIGH(1);
while ((i_assign <= numel(rising_signal)) && (i_compare < numel(HIGH)))
    i_compare = i_compare + 1;
    if (HIGH(i_compare)-rising_signal(i_assign-1)) > n_samples_debounce
        rising_signal(i_assign) = HIGH(i_compare);
        i_assign = i_assign + 1;
    end
end
rising_signal(isnan(rising_signal)) = [];

n_samples_trigger_pulse_offset = round(options.TriggerSignalOffset * options.SampleRate);
rising_trigger = rising_signal + n_samples_trigger_pulse_offset;

rising_orig = parse_sync_from_triggers(orig,...
    'Debounce', options.StimEventDebounce, ...
    'Bit', options.Bit, ...
    'KeepFirstEdge', options.KeepFirstTriggerEdge, ...
    'SampleRate', options.SampleRate);

pulse_count = numel(rising_signal);
if abs(options.ExpectedPulses - pulse_count) > options.PulseCountTolerance
    if numel(rising_orig) > 0
        period_samples = round(options.ExpectedPeriod * options.SampleRate);
        first_rising_edge_misalignment = rem(rising_trigger(1), period_samples) - rem(rising_orig(1), period_samples);
        if abs(first_rising_edge_misalignment) < options.OriginalSyncSampleJitter
            first_trig = rising_trigger(1) - first_rising_edge_misalignment;
            rising_trigger = first_trig:period_samples:(first_trig+period_samples*(options.ExpectedPulses-1));
            rising_signal = rising_trigger - n_samples_trigger_pulse_offset;
        else
            warning('Could not align original and parsed rising edges after detecting incorrect parsed pulse count!');
        end
    else
        warning('Detected %d rising edges, which deviates from expected count (%d) by greater than %d pulses!',  ...
            pulse_count, options.ExpectedPulses, options.PulseCountTolerance);
    end
else
    pulse_period = mean(diff(rising_signal)) ./ options.SampleRate;
    if abs(options.ExpectedPeriod - pulse_period) > options.PeriodTolerance
        warning('Detected mean period of %5.3f-s; this deviates from expected mean period of %5.3f-s by greater than %5.3f-s!', ...
            pulse_period, options.ExpectedPeriod, options.PeriodTolerance);
    else
        if options.Verbose
            fprintf(1,'Successfully detected %d rising signal edges with periodicity of %5.3f-s!\n', pulse_count, pulse_period);
        end
    end
end

n_samples_trigger_pulse = round(options.TriggerPulseWidth * options.SampleRate);

tmp = (rising_trigger') + (0:(n_samples_trigger_pulse-1));
for ii = 1:size(tmp,1)
    sync(tmp(ii,:)) = zeros(1,n_samples_trigger_pulse);
end


end