function client = initTMSi(options)
%INITTMSI Create UDP client to control SAGA state machine running on some host device over IPv4 + UDP.
%
% This function assumes you have already started the "2TMSi_SAGA_MATLAB"
% script to run the state machine for both TMSi SAGA devices. 
%
% Syntax:
%   client = initTMSi('Name', value, ...);

arguments
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
end

client = udpport(options.UDPParameters{:});
client.UserData.saga.address = options.Host;
client.UserData.saga.port = struct(...
    'control', options.PortControl, ...
    'name', options.PortName, ...
    'parameter', options.PortParameters);
client.UserData.block = options.Block;
client.UserData.sweep = options.Sweep;
client.UserData.subject = options.Subject;
client.UserData.year = options.Year;
client.UserData.month = options.Month;
client.UserData.day = options.Day;
client.UserData.recording = false;

end