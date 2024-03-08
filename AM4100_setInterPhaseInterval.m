function AM4100_setInterPhaseInterval(am4100, logger, D_interphase)
%AM4100_SETINTERPHASEINTERVAL Sets the interval between the two phases of asymmetric/biphasic pulses.

arguments
    am4100
    logger
    D_interphase (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(D_interphase,0)}; % Duration between phases (microseconds)
end

[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 11 8 %d', D_interphase)); % set menu=Library1:Interphase:50us
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

end