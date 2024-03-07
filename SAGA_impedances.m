function SAGA_impedances(client, logger)
%SAGA_IMPEDANCES  Measure impedances on HD-EMG array(s)
%
% Syntax:
%   SAGA_impedances(client, logger);
logger.info(sprintf('Measured Impedances (Block = %d)', client.UserData.block));
writeline(client, 'imp', client.UserData.saga.address, client.UserData.saga.port.control);
end