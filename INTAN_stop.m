function INTAN_stop(intanClient, logger)
%INTAN_STOP  Stops intan recording.

intan.stopRecording(intanClient);
logger.info('Stopped Intan');

end