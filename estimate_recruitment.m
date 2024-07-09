function [recruitment, blip, trend] = estimate_recruitment(t, snips, options)
%ESTIMATE_RECRUITMENT  Estimate recruitment from peak-to-peak of snippets
%
% Syntax:
%   [recruitment,blip,trend] = estimate_recruitment(t, snips);
%   recruitment = estimate_recruitment(t, snips, 'Name', value, ...);
%
% Inputs:
%   t - Times (ms) for rows of snips
%   snips - Cell array of tensors or single tensor where 3rd dim is reps
%  
% Options:
%   'DetrendMode' (default: 'poly') - Can be 'poly' or 'exp'
%   'PolyOrder' (default: 1) - Order for detrend if using 'poly' DetrendMode option.
%   'Metric' (default: 'pk2pk') - Currently only 'pk2pk' is supported.
%   'TStart' (1,1) double = 1.5  -- Start time of response epoch (ms)
%   'TStop'  (1,1) double = 2.5 -- End time of response epoch (ms)
%
% Output:
%   recruitment - The peak-to-peak amplitude of each blip
%   blip        - The blip from each trial/channel response used for estimating recruitment.
%   trend       - The part that was subtracted from each response to yield the blip.
%
% See also: Contents, intan_amp_2_snips, snips_2_blip, blip_2_recruitment
arguments
    t  % Times (ms) for rows of snips
    snips % Cell array of tensors or single tensor where 3rd dim is repetitions, first dim is timestep 2nd dim is channel
    options.DetrendMode {mustBeMember(options.DetrendMode, {'poly', 'exp'})} = 'poly';
    options.PolyOrder (1,1) {mustBePositive, mustBeInteger} = 1;
    options.Metric {mustBeMember(options.Metric,{'pk2pk'})} = 'pk2pk';
    options.TStart (1,1) double = 1.5;
    options.TStop (1,1) double = 2.5;
end

if iscell(snips)
    recruitment = cell(size(snips));
    blip = cell(size(snips));
    trend = cell(size(snips));
    for ii = 1:numel(snips)
        [recruitment{ii},blip{ii},trend{ii}] = estimate_recruitment(t, snips{ii}, ...
            'TStart', options.TStart, 'TStop', options.TStop, ...
            'DetrendMode', options.DetrendMode, 'PolyOrder', options.PolyOrder, ...
            'Metric', options.Metric);
    end
    return;
else
    iStart = find(t>=options.TStart,1,'first');
    iStop = find(t<options.TStop,1,'last');

    % Detrend to find the blips
    [blip,trend] = snips_2_blip(snips, iStart, iStop, ...
        'DetrendMode', options.DetrendMode, ...
        'PolyOrder', options.PolyOrder);

    % Calculate the recruitment as peak-to-peak amplitude in each blip.
    recruitment = blip_2_recruitment(blip,'Metric',options.Metric);
end


end