function [data, filtering] = filter_intan_amplifier_data(data, options)
%FILTER_INTAN_AMPLIFIER_DATA  Filter amplifier data from Intan
%
% Syntax:
%   data = filter_intan_amplifier_data(data, 'Name', value, ...);
%
% Inputs:
%   data - nChannels x nSamples amplifier data
%  
% Options:
%   'ApplyFiltering' (1,1) logical = true; % Set false to return data as-is
%   'ApplyCAR' (1,1) logical = true;
%   'ArtifactOnset' (1,:) {mustBePositive, mustBeInteger} = []
%   'SampleRate' (1,1) {mustBePositive} = 20000
%   
arguments
    data
    options.ApplyFiltering (1,1) logical = true;
    options.ApplyCAR (1,1) logical = true;
    options.ApplyPreFilterCAR (1,1) logical = false;
    options.ArtifactDuration (1,1) double = 1e-3; % Artifact duration (seconds)
    options.BlankArtifactBeforeFiltering (1,1) logical = true;
    options.OutlierRejectionCARThresholdDeviations (1,1) double = 3.5; % If channel-wise signal RMS deviates from median RMS by greater than this value, set to zero and suppress in CAR
    options.ArtifactOnset (1,:) {mustBePositive, mustBeInteger} = [];
    options.ComputeEnvelope (1,1) logical = false;
    options.CutoffFrequency (1,:) = 100;
    options.NBlankedSamplesAtStart (1,1) {mustBePositive, mustBeInteger} = 100; % To account for using `filter` instead of `filtfilt`
    options.FilterOrder (1,1) {mustBePositive, mustBeInteger} = 1;
    options.SampleRate (1,1) {mustBePositive} = 20000;
    options.Verbose (1,1) logical = true;
end

filtering = options;
if ~options.ApplyFiltering
    filtering.FilterType = "Raw";
    if options.Verbose
        fprintf(1,'No filtering applied to data\n');
    end
    return; % data already set.
end

if options.Verbose
    timerTic = tic;
end

filtering.FilterType = "Filtered";
if options.ApplyPreFilterCAR
    if options.Verbose
        fprintf(1,'Applying CAR before filtering...');
    end
    filtering.FilterType = strcat(filtering.FilterType, "|Pre-Filter CAR");
    r = rms(data - mean(data,2), 2);
    mu = median(r);
    sigma = median(abs(r - mu));
    i_suppress = sigma > options.OutlierRejectionCARThresholdDeviations;
    data(i_suppress,:) = 0;
    data(~i_suppress,:) = data(~i_suppress,:) - mean(data(~i_suppress,:),1);
    if options.Verbose
        fprintf(1,'(suppressed %d channels)...complete\n', sum(i_suppress));
    end
end

filtering.n_samples_artifact = options.ArtifactDuration * options.SampleRate;
if options.BlankArtifactBeforeFiltering && ~isempty(options.ArtifactOnset)
    if options.Verbose
        fprintf(1,'Blanking artifact before filtering...');
    end
    filtering.FilterType = strcat(filtering.FilterType, sprintf("|Pre-Filter Blanking %3.1fms",options.ArtifactDuration*1e3));
    for ii = 1:numel(options.ArtifactOnset)
        vec = max(options.ArtifactOnset(ii)-1,1):min(options.ArtifactOnset(ii)+filtering.n_samples_artifact,size(data,2));
        for iCh = 1:size(data,1)
            data(iCh, vec) = interp1(vec([1, 2, end-1, end]), data(iCh,vec([1, 2, end-1, end])), vec, 'pchip');
        end
    end
    if options.Verbose
        fprintf(1,'complete\n');
    end
end

filtering.coeff = struct('first',struct('b',[],'a',[]), 'second', struct('b',[],'a',[]));
if isscalar(options.CutoffFrequency)
    filter_str = sprintf("|HPF %4.1fHz",options.CutoffFrequency);
    filtering.FilterType = strcat(filtering.FilterType,filter_str);
    if options.Verbose
        fprintf(1,'Applying Filtering%s...',filter_str);
    end
    [filtering.coeff.first.b,filtering.coeff.first.a] = butter(options.FilterOrder,options.CutoffFrequency./(options.SampleRate/2),'high');
    data = filter(filtering.coeff.first.b, filtering.coeff.first.a, data, [], 2);
    data(:,1:options.NBlankedSamplesAtStart) = 0;
    if options.Verbose
        fprintf(1,'complete\n');
    end
elseif isempty(options.CutoffFrequency)
    filtering.FilterType = strcat(filtering.FilterType,"|Raw");
    if options.Verbose
        fprintf(1,'(No filtering applied to data)\n');
    end
else
    if options.ComputeEnvelope || (filtering.CutoffFrequency(2)<filtering.CutoffFrequency(1))
        filtering.ComputeEnvelope = true;
        filter_str = sprintf("|HPF %4.1fHz|Envelope %4.1fHz",options.CutoffFrequency(1),options.CutoffFrequency(2));
        filtering.FilterType = strcat(filtering.FilterType,filter_str);
        if options.Verbose
            fprintf(1,'Applying Filtering%s...',filter_str);
        end
        filtering.FilterType = strcat(filtering.FilterType,filter_str);
        [filtering.coeff.first.b,filtering.coeff.first.a] = butter(options.FilterOrder,options.CutoffFrequency(1)./(options.SampleRate/2),'high');
        data = filter(filtering.coeff.first.b, filtering.coeff.first.a, data, [], 2);
        data(:, 1:options.NBlankedSamplesAtStart) = 0;
        [filtering.coeff.second.b,filtering.coeff.second.a] = butter(options.FilterOrder,options.CutoffFrequency(2)./(options.SampleRate/2),'low');
        data = filter(filtering.coeff.second.b, filtering.coeff.second.a, abs(data), [], 2);
        data(:, 1:options.NBlankedSamplesAtStart) = 0;
        if options.Verbose
            fprintf(1,'complete\n');
        end
    else
        filter_str = sprintf("|BPF %4.1Hz to %4.1Hz", options.CutoffFrequency(1),options.CutoffFrequency(2));
        if options.Verbose
            fprintf(1,'Applying Filtering%s...', filter_str);
        end
        filtering.FilterType = strcat(filtering.FilterType,filter_str);
        [filtering.coeff.first.b,filtering.coeff.first.a] = butter(options.FilterOrder,options.CutoffFrequency./(options.SampleRate/2),'bandpass');
        data = filter(filtering.coeff.first.b, filtering.coeff.first.a, data, [], 2);
        data(:, 1:options.NBlankedSamplesAtStart) = 0;
        if options.Verbose
            fprintf(1,'complete\n');
        end
    end
end

if ~options.BlankArtifactBeforeFiltering && ~isempty(options.ArtifactOnset)
    if options.Verbose
        fprintf(1,'Zero-ing artifact after filtering...');
    end
    filtering.FilterType = strcat(filtering.FilterType, sprintf("|Post-Filter Blanking %3.1fms",options.ArtifactDuration*1e3));
    for ii = 1:numel(options.ArtifactOnset)
        vec = max(options.ArtifactOnset(ii)-1,1):min(options.ArtifactOnset(ii)+filtering.n_samples_artifact,size(data,2));
        data(:, vec) = 0;
    end
    if options.Verbose
        fprintf(1,'complete\n');
    end
end

if options.ApplyCAR
    if options.Verbose
        fprintf(1,'Applying CAR after filtering...');
    end
    filtering.FilterType = strcat(filtering.FilterType, "|Post-Filter CAR");
    r = rms(data - mean(data,2), 2);
    mu = median(r);
    sigma = median(abs(r - mu));
    i_suppress = sigma > options.OutlierRejectionCARThresholdDeviations;
    data(i_suppress,:) = 0;
    data(~i_suppress,:) = data(~i_suppress,:) - mean(data(~i_suppress,:),1);
    if options.Verbose
        fprintf(1,'(suppressed %d channels)...complete\n', sum(i_suppress));
    end
end

if options.Verbose
    fprintf(1,'Completed %s\n(Time: %5.2f seconds)\n\n', filtering.FilterType, round(toc(timerTic),2));
end

end