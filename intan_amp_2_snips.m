function [snips, t, response, blip, filtering, data, trend] = intan_amp_2_snips(intanData, options)
%INTAN_AMP_2_SNIPS  Returns snippets cell arrays of response tensors (and optionally, second output as struct with filtering parameters).
%
% Syntax:
%   [snips, t, response, blip, filtering, data, trend] = intan_amp_2_snips(intanData, 'Name', value, ...);
%
% Inputs:
%   intanData - Struct or array of structs containing amplifier_data from Intan
%   
% Options:
%   'ApplyFiltering' (1,1) logical = true; % Apply filtering to snippets
%   'FilterParameters' cell = {}; % <'Name', value> pairs in a cell array, for `filter_intan_amplifier_data`
%   'Metric' (default: 'pk2pk') - Currently only 'pk2pk' is supported.
%   'TLim' (1,2) double = [-.002, 0.010]; % Times (seconds) relative to each stimulus pulse rising edge.
%   'DigInSyncChannel' (1,1) {mustBePositive, mustBeInteger} = 2; % 1-indexed channel value from intan.board_dig_in_data rows to use for digital sync of stimulus pulses.
%
% Output:
%   snips - Cell or Cell array same size as `intan` input. Each cell is a
%           tensor, organized as nSamples x nChannels x nStimuli. 
%   t     - Times corresponding to rows of each snippet cell array tensor
%   response  - Raw response epoch pre-stim/post-stim values
%   blip      - Detrended response blips in response epoch of interest
%   filtering - Struct indicating what filter parameters were used.
%   data      - Data array after filtering has been applied. Returned as
%               cell  the same size as `intanData` input.
%   trend     - Part that was subtracted from responses to yield blip.
%
% See also: Contents, filter_intan_amplifier_data

arguments
    intanData (:,1) struct
    options.ApplyFiltering (1,1) logical = true;
    options.Channels (1,:) {mustBePositive, mustBeInteger} = 1:16;
    options.FilterParameters cell = {};
    options.TLim (1,2) double = [-0.002, 0.010]; % Seconds around each rising edge
    % options.TLimResponse (:,2) double = [0.0015, 0.0025]; % Window in which to estimate response power
    options.DetrendMode {mustBeMember(options.DetrendMode,{'poly','exp'})} = 'poly';
    options.PolyOrder = [];
    options.Metric {mustBeMember(options.Metric,{'pk2pk'})} = 'pk2pk';
    options.Muscle (:,1) string = repmat("NONE",16,1);
    options.MuscleResponseTimesFile {mustBeTextScalar} = "Muscle_Response_Times.xlsx";
    options.DigInSyncChannel (1,1) {mustBePositive, mustBeInteger} = 2;
    options.SyncDebounce (1,1) double = 0.005;
    options.Verbose (1,1) logical = true;
end
if options.Verbose
    snipsTimerTic = tic;
end
[tResponse, polyOrderExcel] = load_muscle_response_times(options.Muscle, 'CalibrationFile', options.MuscleResponseTimesFile);
if size(tResponse,1)~=size(intanData(1).amplifier_data,1)
    error("Mismatch in number of muscles mapped vs. number of amplifier channels. Either change acquisition settings or fix mapping...");
end
snips = cell(size(intanData));
blip = cell(size(intanData));
trend = cell(size(intanData));
response = cell(size(intanData));
N = numel(intanData);
data = cell(size(intanData));
for ii = 1:N
    if ii == 1 % Get the relative snippet samples only from the first element in the array. Rest should have same sample rate, or something is majorly fucked up.
        fs = intanData(ii).frequency_parameters.amplifier_sample_rate;
        t = options.TLim(1):(1/fs):options.TLim(2);
        iVec = reshape(unique(round(t .* fs)),[],1); % Column vector: rows are relative time-samples to stimuli
    end
    rising = parse_sync_from_intan(intanData(ii).t_dig, intanData(ii).board_dig_in_data(options.DigInSyncChannel,:), 'Debounce', options.SyncDebounce);
    mask = iVec + rising;
    i_remove = any((mask < 1) | (mask > size(intanData(ii).amplifier_data,2)), 1);
    mask(:,i_remove) = [];
    rising(i_remove) = [];
    
    if (ii == 1)
        [data{ii}, filtering] = filter_intan_amplifier_data(intanData(ii).amplifier_data(options.Channels,:), ...
            'ArtifactOnset', rising, ...
            'SampleRate', fs, ...
            'ApplyFiltering', options.ApplyFiltering, ...
            'Verbose', options.Verbose, ...
            options.FilterParameters{:});
    else
        data{ii} = filter_intan_amplifier_data(intanData(ii).amplifier_data(options.Channels,:), ...
            'ArtifactOnset', rising, ...
            'SampleRate', fs, ...
            'ApplyFiltering', options.ApplyFiltering, ...
            'Verbose', options.Verbose, ...
            options.FilterParameters{:});
    end
   
    nTs = numel(iVec);      % # Sample instants
    nCh = size(data{ii},1);     % # Amplifier channels
    nStims = numel(rising); % # Stimulus pulses with valid indexing
    snips{ii} = nan(nTs, nCh, nStims);
    response{ii} = nan(nStims,nCh);
    blip{ii} = cell(nCh,1);
    trend{ii} = cell(nCh,1);
    if isempty(options.PolyOrder)
        polyOrder = polyOrderExcel;
    else
        polyOrder = ones(nCh,1).*options.PolyOrder;
    end
    for iCh = 1:nCh
        samples = data{ii}(iCh,:);
        snips{ii}(:,iCh,:) = samples(mask);
        snips{ii}(:,iCh,:) = snips{ii}(:,iCh,:)-mean(snips{ii}(1:20,iCh,:),1);
        [response{ii}(:,iCh),blip{ii}{iCh},trend{ii}{iCh}] = estimate_recruitment(...
            t, snips{ii}(:,iCh,:), ...
            'DetrendMode',options.DetrendMode,...
            'PolyOrder',polyOrder(iCh),...
            'Metric', options.Metric, ...
            'TStart',tResponse(iCh,1), ...)
            'TStop', tResponse(iCh,2));   
    end
    if options.Verbose
        fprintf(1,'\n -- Snips (%d / %d) indexed (Total: %5.2f seconds) -- \n\n', ii, N, round(toc(snipsTimerTic),2));
    end
end

end