function [client, am4100, logger] = initInterfaces(options)
%INITINTERFACES Initialize interfaces to TMSi and AM4100, plus logging.

arguments
    % Options for AM4100 system
    options.AddressAM4100 = "192.168.88.150"; % IPv4 Address of the AMS4100 device on network
    options.PortAM4100 = 23;
    options.UseIntan = true; % Set false to not try to connect to Intan server
    options.AddressIntan = "192.168.88.100"; % IPv4 Address of device hosting Intan command server
    options.PortIntan = 5000; % Port for controlling the Intan command server
    
    % Options for TMSi client
    options.Subject (1,1) string = "Default"; % Name of subject to record
    options.Year (1,1) double = year(today); % Numeric year part of date
    options.Month (1,1) double = month(today); % Numeric month part of date
    options.Day (1,1) double = day(today); % Numeric day part of date
    options.Block (1,1) double = 0; % Recording block index.
    options.Sweep (1,1) double = 0; % Recording sweep index.
    options.Host (1,1) string = "192.168.88.100"; % Address of TMSi HOST machine
    options.PortControl (1,1) double = 3030; % UDP port for controlling SAGA acquisition state machine. 
    options.PortName (1,1) double = 3031; % UDP port for setting SAGA recording file name(s). 
    options.PortParameters (1,1) double = 3036; % UDP port for changing SAGA parameters, such as the buffer size. 
    options.UDPParameters (1,:) cell = {};
    options.BufferSamples (1,1) double = 1048576; % Number of samples in buffer (1048576 is nextpow2 greater than 240s (~262s))
end
% 0. Delete any existing timers (just in case)
ht = timerfindall;
if ~isempty(ht)
    delete(ht);
end

% 1. Create the logger object
logger = mlog.Logger(options.Subject);
fprintf(1,'Setting up tcpclient to %s...', options.AddressAM4100);

% 2. Define the AM4100 device connection
am4100=tcpclient(options.AddressAM4100, options.PortAM4100); %port 23
fprintf(1,'complete.\n');
am4100.UserData.subject = options.Subject;
am4100.UserData.year = options.Year;
am4100.UserData.month = options.Month;
am4100.UserData.day = options.Day;
am4100.UserData.recording_duration = 20; % Seconds (default stim parameters)
if options.UseIntan
    fprintf(1,'Attempting to connect to INTAN...')
    am4100.UserData.intan = tcpclient(options.AddressIntan, options.PortIntan);
    fprintf(1,'complete.\n');
else
    am4100.UserData.intan = [];
end

% 3. Define the TMSi SAGA UDP state machine connection
client = createTMSiClient('Subject', options.Subject, ...
    'Year', options.Year, 'Month', options.Month, 'Day', options.Day, ...
    'Block', options.Block, 'Host', options.Host, 'PortControl', options.PortControl, ...
    'PortName', options.PortName, 'PortParameters', options.PortParameters, ...
    'UDPParameters', options.UDPParameters, 'Sweep', options.Sweep);
SAGA_setBufferSize(client, options.BufferSamples, 'samples');
SAGA_updateFileNames(client, logger);

% 4. Do initial configuration of AM4100
logger.info(strtrim(char(read(am4100))));   % empties buffer

[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a stop');
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

sndStr='get rev';
write(am4100,uint8(sprintf('%s\r',sndStr)));
logger.info(sprintf('Send= %s \n',sndStr));  %display send strring
pause(0.01); % and give it a bit of time to reply
rplStr=read(am4100,am4100.BytesAvailable,'string');
logger.info(sprintf('Reply= %s \n', rplStr));  %display reply
[rplStr,inputStr]=AM4100_sendCommand(am4100,'get active');
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'g n');
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'g r');
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

am4100.UserData.timer = timer(...
    'TimerFcn', @(~,~)SAGA_stop(client, logger, 'Intan', am4100.UserData.intan), ...
    'StartDelay', am4100.UserData.recording_duration); % Change StartDelay to modify the recording duration without a blocking loop...

end