function AM4100_stimulate(am4100, logger, client, options)
%AM4100_STIMULATE  Stimulate using the AM4100, while recording this event. 
arguments
    am4100
    logger
    client
    options.SagaCommandPauseDuration (1,1) double {mustBePositive} = 0.05; % seconds
    options.Tag {mustBeTextScalar} = 'STIM';
    options.StartRecording (1,1) logical = true;
    options.Block {mustBeInteger} = [];
end

if options.StartRecording
    if ~isempty(am4100.UserData.timer)
        am4100.UserData.timer.StartDelay = am4100.UserData.recording_duration;
    end
    if ~isempty(client)
        SAGA_record(client, logger, ...
            'SagaCommandPauseDuration', options.SagaCommandPauseDuration, ...
            'Tag', options.Tag, ...
            'Block', options.Block, ...
            'Intan', am4100.UserData.intan, ...
            'Timer', am4100.UserData.timer);
    end
    if ~isempty(logger)
        logger.info('Begin Stimulation');
    end
    pause(options.SagaCommandPauseDuration);
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s t one');  % set the trigger to free run
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end
pause(options.SagaCommandPauseDuration);
if ~isempty(am4100.UserData.timer)
    start(am4100.UserData.timer);
end
if ~isempty(client)
    client.UserData.recording = true;
end
end