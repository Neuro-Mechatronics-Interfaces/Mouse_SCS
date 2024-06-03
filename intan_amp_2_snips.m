function [snips, t, response_normed, response_raw, filtering, data] = intan_amp_2_snips(intan, options)
%INTAN_AMP_2_SNIPS  Returns snippets cell arrays of response tensors (and optionally, second output as struct with filtering parameters).
%
% Syntax:
%   [snips, t, response_normed, response_raw, filtering] = intan_amp_2_snips(intan, 'Name', value, ...);
%
% Inputs:
%   intan - Struct or array of structs containing amplifier_data from Intan
%   
% Options:
%   'ApplyFiltering' (1,1) logical = true; % Apply filtering to snippets
%   'FilterParameters' cell = {}; % <'Name', value> pairs in a cell array, for `filter_intan_amplifier_data`
%   'TLim' (1,2) double = [-.002, 0.010]; % Times (seconds) relative to each stimulus pulse rising edge.
%   'DigInSyncChannel' (1,1) {mustBePositive, mustBeInteger} = 2; % 1-indexed channel value from intan.board_dig_in_data rows to use for digital sync of stimulus pulses.
%
% Output:
%   snips - Cell or Cell array same size as `intan` input. Each cell is a
%           tensor, organized as nSamples x nChannels x nStimuli. 
%   t     - Times corresponding to rows of each snippet cell array tensor
%   response_normed - Response values normalized by baseline power
%   response_raw    - Raw response values
%   filtering - Struct indicating what filter parameters were used.
%
% See also: Contents, filter_intan_amplifier_data

arguments
    intan (:,1) struct
    options.ApplyFiltering (1,1) logical = true;
    options.FilterParameters cell = {};
    options.TLim (1,2) double = [-0.002, 0.010]; % Seconds around each rising edge
    options.TLimBaseline (1,2) double = [-0.002, 0.000]; % Window in which to estimate the baseline
    options.TLimResponse (1,2) double = [0.003, 0.008]; % Window in which to estimate response power
    options.DigInSyncChannel (1,1) {mustBePositive, mustBeInteger} = 2;
    options.SyncDebounce (1,1) double = 0.005;
    options.Verbose (1,1) logical = true;
end
if options.Verbose
    snipsTimerTic = tic;
end
snips = cell(size(intan));
response_normed = cell(size(intan));
response_raw = cell(size(intan));
N = numel(intan);
for ii = 1:N
    if ii == 1 % Get the relative snippet samples only from the first element in the array. Rest should have same sample rate, or something is majorly fucked up.
        fs = intan(ii).frequency_parameters.amplifier_sample_rate;
        t = options.TLim(1):(1/fs):options.TLim(2);
        iVec = reshape(unique(round(t .* fs)),[],1); % Column vector: rows are relative time-samples to stimuli
        iBaseline = (t >= options.TLimBaseline(1)) & (t < options.TLimBaseline(2));
        iResponse = (t >= options.TLimResponse(1)) & (t < options.TLimResponse(2));
    end
    rising = parse_sync_from_intan(intan(ii).t_dig, intan(ii).board_dig_in_data(options.DigInSyncChannel,:), 'Debounce', options.SyncDebounce);
    mask = iVec + rising;
    i_remove = any((mask < 1) | (mask > size(intan(ii).amplifier_data,2)), 1);
    mask(:,i_remove) = [];
    rising(i_remove) = [];
    
    if (ii == 1)
        [data, filtering] = filter_intan_amplifier_data(intan(ii).amplifier_data, ...
            'ArtifactOnset', rising, ...
            'SampleRate', fs, ...
            'ApplyFiltering', options.ApplyFiltering, ...
            'Verbose', options.Verbose, ...
            options.FilterParameters{:});
    else
        data = filter_intan_amplifier_data(intan(ii).amplifier_data, ...
            'ArtifactOnset', rising, ...
            'SampleRate', fs, ...
            'ApplyFiltering', options.ApplyFiltering, ...
            'Verbose', options.Verbose, ...
            options.FilterParameters{:});
    end
   
    nTs = numel(iVec);      % # Sample instants
    nCh = size(data,1);     % # Amplifier channels
    nStims = numel(rising); % # Stimulus pulses with valid indexing
    snips{ii} = nan(nTs, nCh, nStims);
    response_raw{ii} = nan(nStims, nCh);
    response_normed{ii} = nan(nStims, nCh);
    for iCh = 1:nCh
        samples = data(iCh,:);
        snips{ii}(:,iCh,:) = samples(mask);
        snips{ii}(:,iCh,:) = snips{ii}(:,iCh,:)-mean(snips{ii}(1:20,iCh,:),1);
        response_raw{ii}(:,iCh) = squeeze(mean(sqrt(snips{ii}(iResponse,iCh,:).^2),1));
        response_normed{ii}(:,iCh) = response_raw{ii}(:,iCh) ./ squeeze(mean(sqrt(snips{ii}(iBaseline,iCh,:).^2),1));
    end
    if options.Verbose
        fprintf(1,'\n -- Snips (%d / %d) indexed (Total: %5.2f seconds) -- \n\n', ii, N, round(toc(snipsTimerTic),2));
    end
end

end