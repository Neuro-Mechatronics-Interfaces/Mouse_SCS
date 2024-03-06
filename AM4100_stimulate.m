function AM4100_stimulate(am4100, logger, client, options)
%AM4100_STIMULATE  Stimulate using the AM4100, while recording this event. 
arguments
    am4100
    logger
    client
    options.SagaCommandPauseDuration (1,1) double {mustBePositive} = 0.05; % seconds
    options.Tag {mustBeTextScalar} = 'STIM';
    options.Block {mustBeInteger} = [];
end

am4100.UserData.timer.StartDelay = am4100.UserData.recording_duration;
SAGA_record(client, logger, ...
    'SagaCommandPauseDuration', options.SagaCommandPauseDuration, ...
    'Tag', options.Tag, ...
    'Block', options.Block, ...
    'Intan', am4100.UserData.intan, ...
    'Timer', am4100.UserData.timer);
logger.info('Begin Stimulation');
pause(options.SagaCommandPauseDuration);
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s t one');  % set the trigger to free run
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
pause(options.SagaCommandPauseDuration);
start(am4100.UserData.timer);
client.UserData.recording = true;

end