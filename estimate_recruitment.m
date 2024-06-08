function [recruitment, blip] = estimate_recruitment(t, snips, options)
%ESTIMATE_RECRUITMENT  Estimate recruitment from peak-to-peak of snippets
%
% Syntax:
%   [recruitment,blip] = estimate_recruitment(t, snips);
%   recruitment = estimate_recruitment(t, snips, 'Name', value, ...);
%
% Inputs:
%   t - Times (ms) for rows of snips
%   snips - Cell array of tensors or single tensor where 3rd dim is reps
%  
% Options:
%   'TStart' (1,1) double = 1.5  -- Start time of response epoch (ms)
%   'TStop'  (1,1) double = 2.5 -- End time of response epoch (ms)
%
% Output:
%   recruitment - The peak-to-peak amplitude of each blip
%   blip        - The blip from each trial/channel response used for estimating recruitment.
arguments
    t  % Times (ms) for rows of snips
    snips % Cell array of tensors or single tensor where 3rd dim is repetitions, first dim is timestep 2nd dim is channel
    options.TStart (1,1) double = 1.5;
    options.TStop (1,1) double = 2.5;
end

if iscell(snips)
    recruitment = cell(size(snips));
    blip = cell(size(snips));
    for ii = 1:numel(snips)
        [recruitment{ii},blip{ii}] = estimate_recruitment(t, snips{ii}, ...
            'TStart', options.TStart, 'TStop', options.TStop);
    end
    return;
else
    iStart = find(t>=options.TStart,1,'first');
    iStop = find(t<options.TStop,1,'last');
    vec = iStart:iStop;
    recruitment = nan(size(snips,3),size(snips,2));
    blip = nan(numel(vec),size(snips,3),size(snips,2));
    for ii = 1:size(snips,3)
        tmp = interp1([iStart,iStop],snips([iStart,iStop],:,ii),vec,'linear');
        for iCh = 1:size(snips,2)
            blip(:,ii,iCh) = snips(vec,iCh,ii) - tmp(:,iCh);
            recruitment(ii,iCh) = max(blip(:,ii,iCh)) - min(blip(:,ii,iCh));
        end
    end
end


end