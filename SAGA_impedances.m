function SAGA_impedances(client, logger)
%SAGA_IMPEDANCES  Measure impedances on HD-EMG array(s)
%
% Syntax:
%   SAGA_impedances(client, logger);
if ~isempty(logger)
    logger.info(sprintf('Measured Impedances (Block = %d)', client.UserData.block));
end
writeline(client, 'imp', client.UserData.saga.address, client.UserData.saga.port.control);
end