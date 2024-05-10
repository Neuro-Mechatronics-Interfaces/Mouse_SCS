function SAGA_record(client, logger, options)
%%SAGA_RECORD  Run and increment the recording for TMSi-SAGAs AND Plexon (do not manually increment Plexon!)

arguments
    client % udpport object (connection to SAGA state machine)
    logger % mlog.Logger object
    options.DelayAfterRunCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRunCommand, 0)} = 0.025;
    options.DelayAfterNameCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterNameCommand, 0)} = 0.025; 
    options.DelayAfterRecCommand (1,1) double {mustBeGreaterThanOrEqual(options.DelayAfterRecCommand, 0)} = 0.1; 
    options.Tag {mustBeTextScalar} = 'STIM';
    options.Block {mustBeInteger} = [];
    options.RawDataRoot {mustBeTextScalar} = "";
    options.Intan = [];
    options.Timer = [];

end

writeline(client, 'run', client.UserData.saga.address, client.UserData.saga.port.control);
pause(options.DelayAfterRunCommand);

if ~isempty(options.Block)
    client.UserData.block = options.Block;
    fprintf(1,'Set `block` to %d.\n', client.UserData.block);
    logger.info(sprintf('Block = %d', client.UserData.block));
end
SAGA_updateFileNames(client, logger, 'Intan', options.Intan, 'Tag', options.Tag, 'RawDataRoot', options.RawDataRoot);
if ~isempty(options.Intan)
    intan.startRecording(options.Intan);
    logger.info('Started Intan Recording');
    if ~isempty(options.Timer)
        options.Timer.TimerFcn = @(~,~)SAGA_stop(client, logger, 'Intan', options.Intan);
    end
end
pause(options.DelayAfterNameCommand);
writeline(client, 'rec', client.UserData.saga.address, client.UserData.saga.port.control);
pause(options.DelayAfterRecCommand);
fprintf(1,'Recording EMG for <strong>Block=%d</strong>\n', client.UserData.block);
logger.info(sprintf('Started SAGA recording (Block=%d)', client.UserData.block));

end
