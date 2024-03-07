function am4100 = initAM4100(client, logger, options)

arguments
    client
    logger
    options.AddressAM4100 = "192.168.88.150";
    options.PortAM4100 = 23;
    options.AddressIntan = "192.168.88.100";
    options.PortIntan = 5000;
    options.UseIntan = true;
end

am4100=tcpclient(options.AddressAM4100, options.PortAM4100); %port 23
fprintf(1,'complete.\n');
am4100.UserData.subject = client.UserData.subject;
am4100.UserData.year = client.UserData.year;
am4100.UserData.month = client.UserData.month;
am4100.UserData.day = client.UserData.day;
am4100.UserData.recording_duration = 20; % Seconds (default stim parameters)
if options.UseIntan
    fprintf(1,'Attempting to connect to INTAN...')
    am4100.UserData.intan = tcpclient(options.AddressIntan, options.PortIntan);
    fprintf(1,'complete.\n');
else
    am4100.UserData.intan = [];
end

am4100.UserData.timer = timer(...
    'TimerFcn', @(~,~)SAGA_stop(client, logger, 'Intan', am4100.UserData.intan), ...
    'StartDelay', am4100.UserData.recording_duration); % Change StartDelay to modify the recording duration without a blocking loop...

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

end