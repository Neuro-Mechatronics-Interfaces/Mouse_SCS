function [client, am4100, logger] = initInterfaces(options)
%INITINTERFACES Initialize interfaces to TMSi and AM4100, plus logging.

arguments
    options.Subject (1,1) string = "Default"; % Name of subject to record
    options.Year (1,1) double = year(today); % Numeric year part of date
    options.Month (1,1) double = month(today); % Numeric month part of date
    options.Day (1,1) double = day(today); % Numeric day part of date
    options.Block (1,1) double = 0; % Recording block index.
    options.Sweep (1,1) double = 0; % Recording sweep index.
    
    % Options for AM4100 system
    options.UseAM4100 (1,1) logical = true;
    options.AddressAM4100 = "10.0.0.80"; % IPv4 Address of the AMS4100 device on network
    options.PortAM4100 = 23;
    options.UseRelays (1,1) logical = true;
    options.AddressRelays = "10.0.0.10"; % IPv4 Address of the RPi v4b running stim switching relays on network
    options.PortRelays (1,1) {mustBePositive, mustBeInteger} = 7010
    
    % Options for INTAN system
    options.UseIntan (1,1) logical = true; % Set false to not try to connect to Intan server
    options.AddressIntan = "127.0.0.1"; % IPv4 Address of device hosting Intan command server
    options.PortIntan = 5000; % Port for controlling the Intan command server
    options.IntanClient = [];
    
    % Options for TMSi client
    options.AddressTMSi (1,1) string = "127.0.0.1"; % Address of TMSi HOST machine
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


% 2. Define the TMSi SAGA UDP state machine connection
client = initTMSi('Subject', options.Subject, ...
    'Year', options.Year, 'Month', options.Month, 'Day', options.Day, ...
    'Block', options.Block, 'Host', options.AddressTMSi, 'PortControl', options.PortControl, ...
    'PortName', options.PortName, 'PortParameters', options.PortParameters, ...
    'UDPParameters', options.UDPParameters, 'Sweep', options.Sweep);
SAGA_setBufferSize(client, options.BufferSamples, 'samples');
SAGA_updateFileNames(client, logger);


% 3. Do initial configuration of AM4100
if options.UseAM4100
    am4100 = initAM4100(client, logger, ...
        'AddressAM4100', options.AddressAM4100, ...
        'AddressIntan', options.AddressIntan, ...
        'PortAM4100', options.PortAM4100, ...
        'PortIntan', options.PortIntan, ...
        'UseIntan', options.UseIntan, ...
        'IntanClient', options.IntanClient);
else
    if options.UseIntan
        if isempty(options.IntanClient)
            intan_client = tcpclient(options.AddressIntan, options.PortIntan);
        else
            intan_client = options.IntanClient;
        end
        timer_obj = timer(...
            'TimerFcn', @(~,~)INTAN_stop(intan_client, logger), ...
            'StartDelay', 20);
    else
        intan_client = [];
        timer_obj = [];
    end
    am4100 = struct('UserData', ...
                struct(...
                    'subject', 'Test', ...
                    'year', year(today), ...
                    'month', month(today), ...
                    'day', day(today), ...
                    'recording_duration', 20, ...
                    'timer', timer_obj, ...
                    'intan', intan_client, ...
                    'enable', false));
end

end