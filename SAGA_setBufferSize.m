function setBufferSize(client, sz, mode,options)
%SETBUFFERSIZE Updates tmsi client recording buffer samples for the next record.
%
% Syntax:
%   setBufferSize(client, sz);
%   setBufferSize(client, sz, mode);
%
% Inputs:
%     client - The UDPport object acting as client
%     sz (1,1) double - The desired size. Default value is specified in
%                           seconds, but can set 'mode' to 'samples' to
%                           specify sample buffer size directly.
%     mode {mustBeTextScalar, mustBeMember(mode, {'seconds', 'samples'})} = 'seconds';
%
% See also: Contents
arguments
    client
    sz (1,1) double {mustBePositive, mustBeInteger}
    mode {mustBeTextScalar, mustBeMember(mode, {'seconds', 'samples'})} = 'seconds';
    options.SampleRate (1,1) double {mustBePositive} = 4000; % Sample rate of TMSi SAGA
end

switch mode
    case 'seconds'
        cmd_route = 't';
        approx_seconds = round(2^nextpow2(sz*options.SampleRate)/options.SampleRate);
        fprintf(1,'Sending command to set buffer size to %d seconds.\n',round(sz));
        fprintf(1,'\t->\t(Note: at %3.1f sample rate this will result in buffer size of approximately %d seconds, %d second(s) more than requested.\n\t\t\tTo set precise sample count, use the "samples" mode instead.)\n', round(options.SampleRate*1e-3,1), approx_seconds, approx_seconds-sz);
    case 'samples'
        cmd_route = 'n';
        fprintf(1,'Sending command to set buffer size to %d samples.\n',round(sz));
    otherwise
        error("Unhandled value for `mode` input ('%s').", mode);
end

cmd_bytes = sprintf('%s.%d', cmd_route, sz);
writeline(client, cmd_bytes, ...
    client.UserData.saga.address, ...
    client.UserData.saga.port.parameter);

end