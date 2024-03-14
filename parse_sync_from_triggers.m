function [rising,sync] = parse_sync_from_triggers(triggers, options)
%PARSE_SYNC_FROM_TRIGGERS Parse the rising edge of bit-encoded TRIGGERS signal.
%
% Syntax:
%   [rising,sync] = parse_sync_from_triggers(triggers, 'Name', value, ...);
%
% Inputs:
%   triggers - (1 x nSamples) trigger samples
%
% Options:
%     Bit = 12;
%     Debounce = 0.5; % Debounce between triggers
%     KeepFirstEdge (1,1) logical = false;
%     SampleRate = 4000; 

arguments
    triggers (1,:) double
    options.Bit {mustBeInteger, mustBeInRange(options.Bit, 0, 15)} = 12;
    options.Debounce = 0.5; % Debounce between triggers
    options.KeepFirstEdge (1,1) logical = false;
    options.SampleRate = 4000;
end

n_debounce_samples = round(options.SampleRate * options.Debounce);

sync = bitand(triggers,2^options.Bit)==0;
HIGH = find(sync);
rising = HIGH([options.KeepFirstEdge, diff(HIGH) > n_debounce_samples]);

end