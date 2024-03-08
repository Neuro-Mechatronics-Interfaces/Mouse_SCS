function AM4100_stimulate(am4100, logger, client, options)
%AM4100_STIMULATE  Stimulate using the AM4100, while recording this event. 
arguments
    am4100
    logger
    client
    options.DelayAfterRunCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRunCommand, 0)} = 0.025;
    options.DelayAfterNameCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterNameCommand, 0)} = 0.025; 
    options.DelayAfterRecCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRecCommand, 0)} = 0.1; 
    options.Tag {mustBeTextScalar} = 'STIM';
    options.StartRecording (1,1) logical = true;
end

if options.StartRecording
    if ~isempty(am4100.UserData.timer)
        am4100.UserData.timer.StartDelay = am4100.UserData.recording_duration;
    end
    if ~isempty(client)
        SAGA_record(client, logger, ...
            'DelayAfterRunCommand', options.DelayAfterRunCommand, ...
            'DelayAfterNameCommand', options.DelayAfterNameCommand, ...
            'DelayAfterRecCommand', options.DelayAfterRecCommand, ...
            'Tag', options.Tag, ...
            'Block', client.UserData.block, ...
            'Intan', am4100.UserData.intan, ...
            'Timer', am4100.UserData.timer);
    end
    if ~isempty(logger)
        logger.info('Begin Stimulation');
    end
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s t one');  % set the trigger to free run
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
if ~isempty(am4100.UserData.timer)
    start(am4100.UserData.timer);
end
if ~isempty(client)
    client.UserData.recording = true;
end
end