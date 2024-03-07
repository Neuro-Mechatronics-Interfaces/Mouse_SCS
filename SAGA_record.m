function SAGA_record(client, logger, options)
%%SAGA_RECORD  Run and increment the recording for TMSi-SAGAs AND Plexon (do not manually increment Plexon!)

arguments
    client % udpport object (connection to SAGA state machine)
    logger % mlog.Logger object
    options.SagaCommandPauseDuration (1,1) double {mustBePositive} = 0.5; % seconds
    options.Tag {mustBeTextScalar} = 'STIM';
    options.Block {mustBeInteger} = [];
    options.Intan = [];
    options.Timer = [];

end

writeline(client, 'run', client.UserData.saga.address, client.UserData.saga.port.control);
pause(options.SagaCommandPauseDuration);

if ~isempty(options.Block)
    client.UserData.block = options.Block;
    fprintf(1,'Set `block` to %d.\n', client.UserData.block);
    logger.info(sprintf('Block = %d', client.UserData.block));
end
SAGA_updateFileNames(client, logger, 'Intan', options.Intan, 'Tag', options.Tag);
if ~isempty(options.Intan)
    write(options.Intan, uint8('set runmode record'));
    logger.info('Started Intan Recording');
    if ~isempty(options.Timer)
        options.Timer.TimerFcn = @(~,~)SAGA_stop(client, logger, 'Intan', options.Intan);
    end
end
pause(options.SagaCommandPauseDuration);
writeline(client, 'rec', client.UserData.saga.address, client.UserData.saga.port.control);
pause(1.5);
fprintf(1,'Recording EMG for <strong>Block=%d</strong>\n', client.UserData.block);
logger.info(sprintf('Started SAGA recording (Block=%d)', client.UserData.block));

end
