function SAGA_stop(client, logger, options)
%SAGA_STOP  Stop the current recording/running SAGA state
%
% Syntax:
%   SAGA_stop(client, logger);

arguments
    client (1,1) % udpport connection to the SAGA state server
    logger (1,1) % mlog.Logger logging object
    options.Intan = []; % Can be tcpclient with connection to Intan command server
end

if ~isempty(options.Intan)
    INTAN_stop(options.Intan, logger);
end

writeline(client, 'idle', client.UserData.saga.address, client.UserData.saga.port.control);
logger.info(sprintf('Stopped SAGA recording (Block = %d)', client.UserData.block));

client.UserData.block = client.UserData.block + 1;
fprintf(1,'Incremented block to %d\n', client.UserData.block);
client.UserData.recording = false;

end