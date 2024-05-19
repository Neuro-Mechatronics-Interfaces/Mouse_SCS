function rising = parse_sync_from_intan(t, dig_in, options)
%PARSE_SYNC_FROM_INTAN Parse the rising edge of intan dig_in signal.
%
% Syntax:
%   rising = parse_sync_from_intan(t, dig_in, 'Name', value, ...);
%
% Inputs:
%   t - (1 x nSamples) trigger samples
%   dig_in - (1 x nSamples) dig_in samples vector
%
% Options:
%     Debounce = 0.5; % Debounce between triggers (seconds)

arguments
    t (1,:) double
    dig_in (1,:) double
    options.Debounce = 0.5; % Debounce between triggers
end

HIGH = find(dig_in > 0);
T_HIGH = t(HIGH);
rising = HIGH([HIGH(1)>1, diff(T_HIGH) > options.Debounce]);

end