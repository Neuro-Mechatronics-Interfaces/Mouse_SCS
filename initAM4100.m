function am4100 = initAM4100(client, logger, options)
%INITAM4100 Initialize TCP interface to AM4100.
%
% Syntax:
%   am4100 = initAM4100(client, logger, 'Name', value, ...);
%
% Inputs
%     client TMSi udpport client object
%     logger mlog.Logger logging object.
%
% Options:
%     AddressAM4100 = "127.0.0.1";
%     PortAM4100 = 23;
%     AddressIntan = "127.0.0.1";
%     PortIntan = 5000;
%     UseIntan = true;
% 
% Output:
%   am4100 - tcpclient to the AM4100 device, with pre-populated UserData
%               fields.
%
% See also: Contents, initInterfaces

arguments
    client
    logger
    options.AddressAM4100 {mustBeTextScalar} = "10.0.0.80";
    options.PortAM4100 (1,1) {mustBePositive, mustBeInteger} = 23;
    options.AddressIntan {mustBeTextScalar} = "127.0.0.1";
    options.PortIntan (1,1) {mustBePositive, mustBeInteger} = 5000;
    options.UseIntan (1,1) logical = true;
    options.UseRelays (1,1) logical = true;
    options.AddressRelays = "10.0.0.10"; % IPv4 Address of the RPi v4b running stim switching relays on network
    options.PortRelays (1,1) {mustBePositive, mustBeInteger} = 7010
    options.DefaultRecordingDuration = 20; % Seconds
end

am4100=tcpclient(options.AddressAM4100, options.PortAM4100); %port 23
pause(0.050);
fprintf(1,'AM4100 TCP connection complete.\n');
if ~isempty(client)
    am4100.UserData.subject = client.UserData.subject;
    am4100.UserData.year = client.UserData.year;
    am4100.UserData.month = client.UserData.month;
    am4100.UserData.day = client.UserData.day;
else
    am4100.UserData.subject = 'Test';
    am4100.UserData.year = year(today);
    am4100.UserData.month = month(today);
    am4100.UserData.day = day(today);
end
am4100.UserData.recording_duration = options.DefaultRecordingDuration; % Seconds (default stim parameters)
if options.UseIntan
    fprintf(1,'Attempting to connect to INTAN...')
    am4100.UserData.intan = tcpclient(options.AddressIntan, options.PortIntan);
    fprintf(1,'complete.\n');
else
    am4100.UserData.intan = [];
end
if options.UseRelays
    am4100.UserData.relay_pi = udpport();
    am4100.UserData.relay_pi.UserData = struct('address', options.AddressRelays, 'port', options.PortRelays, 'logger', logger);
    configureCallback(am4100.UserData.relay_pi, "terminator", @log_relay_interaction);
else
    am4100.UserData.relay_pi = [];
end
if isempty(client)
    if options.UseIntan
        am4100.UserData.timer = timer(...
            'TimerFcn', @(~,~)INTAN_stop(am4100.UserData.intan, logger), ...
            'StartDelay', am4100.UserData.recording_duration);
    else
        am4100.UserData.timer = [];
    end
else
    am4100.UserData.timer = timer(...
        'TimerFcn', @(~,~)SAGA_stop(client, logger, 'Intan', am4100.UserData.intan), ...
        'StartDelay', am4100.UserData.recording_duration); % Change StartDelay to modify the recording duration without a blocking loop...
end
if isempty(logger)
    disp(strtrim(char(read(am4100))));
else
    logger.info(strtrim(char(read(am4100))));   % empties buffer
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a stop');
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
sndStr='get rev';
write(am4100,uint8(sprintf('%s\r',sndStr)));
if ~isempty(logger)
    logger.info(sprintf('sent= %s',sndStr));  %display send strring
end
pause(0.01); % and give it a bit of time to reply
rplStr=read(am4100,am4100.BytesAvailable,'string');
if isempty(logger)
    fprintf(1,'reply= %s', strtrim(rplStr));
else
    logger.info(sprintf('reply= %s', strtrim(rplStr)));  %display reply
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'get active');
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'g n');
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'g r');
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
am4100.UserData.enable = true;
end