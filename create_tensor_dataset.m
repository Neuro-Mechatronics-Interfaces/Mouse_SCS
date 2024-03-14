function [data, t, channel, trial, info] = create_tensor_dataset(T, saga, subject, options)
%CREATE_TENSOR_DATASET  Create tensor dataset around each stimulus onset TTL pulse.
%
% Syntax:
%   [data, t, trial, channel, info] = create_tensor_dataset(T, saga, subject, 'Name', value, ...);
%
% Inputs:
%   T - Table indicating stimulus parameters associated to each saga run.
%   saga - Struct returned by `loadData` with fields 'A' and 'B' each of
%               which correspond to a row in `T`.
%   subject - The name of the subject (must be "Frank" or "BabyYoda" currently).
%  
% Options:
%   SampleRate (1,1) double = 4000               The number of samples per second (SAGA; default 4000)
%   StimWindow (1,2) double = [-0.002, 0.012]    Window to export around each stimulus trigger onset (seconds)
%
% Output:
%   data - Tensor as nTimeSamples x nChannels x nTrials (stimulus repetitions)
%           -> Each dimension corresponds with a matched element from `t`,
%                   `channels` or `trials` respectively.
%   t        - Time vector (milliseconds) relative to the rising edge of TTL trigger.
%   channel  - Struct array with fields 'label', 'id', 'type' which
%               correspond with metadata about each channel.
%   trial    - Metadata indicating the 'intensity' and 'frequency' for each
%               exported trial.
%   info     - Small metadata structure with fields 'Subject', 'SampleRate'
%               and 'StimWindow' (for now)
%
% See also: Contents, loadData, loadMultiData

arguments
    T
    saga
    subject {mustBeTextScalar, mustBeMember(subject, ["Frank", "BabyYoda"])};
    options.ApplyCAR (1,1) logical = true;
    options.Bit (1,1) double {mustBeInteger, mustBeInRange(options.Bit,0,15)} = 12;
    options.DesiredChannels (1,:) {mustBePositive, mustBeInteger} = 2:72;
    options.Debounce (1,1) double = 0.005;
    options.Fc (1,:) double = 5;
    options.KeepFirstEdge (1,1) logical = false; % Keep first sync pulse edge (TMSi; typically everything is pulled LOW until STATUS is set).
    options.Saga (1,:) string = ["A", "B"];
    options.SampleRate (1,1) double = 4000; % Samples per second (TMSi)
    options.StimWindow (1,2) double = [-0.002, 0.012]; % Window to export around each stimulus trigger onset (seconds)
    options.TriggerChannel (1,1) double {mustBePositive, mustBeInteger} = 73;
    options.Verbose (1,1) logical = true;
end

info = struct('ApplyCAR', options.ApplyCAR, 'Fc', options.Fc, 'Subject', subject, 'SampleRate', options.SampleRate, 'StimWindow', options.StimWindow);

idx = round(options.StimWindow * options.SampleRate);
vec = (idx(1):idx(2))';
t = (vec .*1e3) ./ options.SampleRate; % Return times in milliseconds. 

nTimestep = numel(t);
nSubChannel = numel(options.DesiredChannels);
nChannel = numel(options.Saga) * nSubChannel;
channel = struct('label', cell(1,nChannel), 'id', cell(1,nChannel), 'type', cell(1,nChannel));
nSaga = numel(options.Saga);

for iSaga = 1:nSaga
    for iCh = 1:nSubChannel
        channelAssign = iCh + (iSaga-1)*nSubChannel;
        [channel(channelAssign).label, channel(channelAssign).id, channel(channelAssign).type] = saga_channel_2_str_id(options.DesiredChannels(iCh), 'Subject', subject, 'Saga', options.Saga(iSaga));
    end
end

nTrial = sum(T.N);

data = randn(nTimestep, nChannel, nTrial); % Use randn so we pre-allocate maximum amount of memory (no compression possible)
counter = 0;
if options.Verbose
    fprintf(1,'Please wait, creating %d x %d x %d data tensor...%03d%%\n', nTimestep, nChannel, nTrial, 0);
    tic;
end

switch subject
    case "Frank"
        validCARChannels = parameters('frank_valid_uni_channels');
    case "BabyYoda"
        validCARChannels = parameters('babyyoda_valid_uni_channels');
    otherwise
        error("Unhandled subject CAR channels.");
end

for iSaga = 1:nSaga
    iTrialStart = 1;
    valid_car_channels = validCARChannels.(options.Saga(iSaga));
    nGrid = numel(valid_car_channels);
    for iRun = 1:size(T,1)
        rising = parse_sync_from_triggers(saga.(options.Saga(iSaga))(iRun).samples(options.TriggerChannel,:), ...
            'Bit', options.Bit, ...
            'Debounce', options.Debounce, ...
            'KeepFirstEdge', options.KeepFirstEdge, ...
            'SampleRate', options.SampleRate);
        iTrialStop = sum(T.N(1:iRun));
        trialAssign = iTrialStart : iTrialStop;
        mask = vec + rising;
        for iCh = 1:nSubChannel
            channelAssign = iCh + (iSaga-1)*nSubChannel;
            ch = options.DesiredChannels(iCh);
            if startsWith(channel(channelAssign).type, "UNI")
                tmpData = applyFilters(saga.(options.Saga(iSaga))(iRun).samples, ch, ... 
                    'ApplyCAR', options.ApplyCAR, ...
                    'Fc', options.Fc, ...
                    'SampleRate', options.SampleRate, ...
                    'PlotCARRMS', false, ...
                    'ValidCARChannels', valid_car_channels{ceil(channel(channelAssign).id / (64 / nGrid))});
            elseif startsWith(channel(channelAssign).type, "BIP")
                tmpData = applyFilters(saga.(options.Saga(iSaga))(iRun).samples, ch, 'ApplyCAR', false, 'Fc', options.Fc, 'SampleRate', options.SampleRate, 'PlotCARRMS', false);
            else
                tmpData = saga.(options.Saga(iSaga))(iRun).samples(ch,:);
            end
            data(:,channelAssign, trialAssign) = tmpData(mask);
        end
        iTrialStart = iTrialStop + 1;
        counter = counter + T.N(iRun);
        if options.Verbose
            fprintf(1,'\b\b\b\b\b%03d%%\n', round(counter*100/(nSaga*nTrial)));
        end
    end
end

trial = repelem(T, T.N, 1); %
trial.N = ones(size(trial,1),1);
[~,ifreq] = sort(trial.frequency, 'ascend');
trial = trial(ifreq,:);
data = data(:,:,ifreq);
[~,iamp] = sort(abs(trial.intensity),'ascend');
trial = trial(iamp, :);
data = data(:,:,iamp);
info.NPerRun = T.N(1);
if options.Verbose
    toc;
end

end