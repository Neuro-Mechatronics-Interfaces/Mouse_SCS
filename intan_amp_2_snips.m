function [snips, t, response, blip, filtering, data] = intan_amp_2_snips(intanData, options)
%INTAN_AMP_2_SNIPS  Returns snippets cell arrays of response tensors (and optionally, second output as struct with filtering parameters).
%
% Syntax:
%   [snips, t, response, blip, filtering, data] = intan_amp_2_snips(intanData, 'Name', value, ...);
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
    intanData (:,1) struct
    options.ApplyFiltering (1,1) logical = true;
    options.FilterParameters cell = {};
    options.TLim (1,2) double = [-0.002, 0.010]; % Seconds around each rising edge
    % options.TLimResponse (:,2) double = [0.0015, 0.0025]; % Window in which to estimate response power
    options.Muscle (:,1) string = repmat("NONE",16,1);
    options.MuscleResponseTimesFile {mustBeTextScalar} = "Muscle_Response_Times.xlsx";
    options.DigInSyncChannel (1,1) {mustBePositive, mustBeInteger} = 2;
    options.SyncDebounce (1,1) double = 0.005;
    options.Verbose (1,1) logical = true;
end
if options.Verbose
    snipsTimerTic = tic;
end
tResponse = load_muscle_response_times(options.Muscle, 'CalibrationFile', options.MuscleResponseTimesFile);
if size(tResponse,1)~=size(intanData(1).amplifier_data,1)
    error("Mismatch in number of muscles mapped vs. number of amplifier channels. Either change acquisition settings or fix mapping...");
end
snips = cell(size(intanData));
blip = cell(size(intanData));
response = cell(size(intanData));
N = numel(intanData);
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
        [data, filtering] = filter_intan_amplifier_data(intanData(ii).amplifier_data, ...
            'ArtifactOnset', rising, ...
            'SampleRate', fs, ...
            'ApplyFiltering', options.ApplyFiltering, ...
            'Verbose', options.Verbose, ...
            options.FilterParameters{:});
    else
        data = filter_intan_amplifier_data(intanData(ii).amplifier_data, ...
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
    response{ii} = nan(nStims,nCh);
    blip{ii} = cell(nCh,1);
    for iCh = 1:nCh
        samples = data(iCh,:);
        snips{ii}(:,iCh,:) = samples(mask);
        snips{ii}(:,iCh,:) = snips{ii}(:,iCh,:)-mean(snips{ii}(1:20,iCh,:),1);
        [response{ii}(:,iCh),blip{ii}{iCh}] = estimate_recruitment(...
            t, snips{ii}(:,iCh,:), ...
            'TStart',tResponse(iCh,1), ...)
            'TStop', tResponse(iCh,2));   
    end
    if options.Verbose
        fprintf(1,'\n -- Snips (%d / %d) indexed (Total: %5.2f seconds) -- \n\n', ii, N, round(toc(snipsTimerTic),2));
    end
end

end