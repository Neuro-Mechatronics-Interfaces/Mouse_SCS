function AM4100_setStimEventPeriodAndCount(am4100, logger, options) 
%AM4100_SETSTIMEVENTPERIODANDCOUNT Set the AM4100 stimulation event period and number of stimuli.

arguments
    am4100 % tcpclient connection to AM4100 stimulator device
    logger % mlog.Logger logging object
    options.PulsePeriod (1,1) double = 1.5; % Number of seconds between each stim event HIGH edge
    options.PulsesPerBurst (1,1) double {mustBePositive, mustBeInteger} = 10; % Number of events for a given stim level
    options.PostBurstBuffer (1,1) double = 2.0; % Number of seconds to "buffer" at the end of the event train
    options.NBursts (1,1) double {mustBePositive, mustBeInteger} = 1;
end

burst_period = round((options.PulsePeriod * (options.PulsesPerBurst+1) + options.PostBurstBuffer) * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 7 3 %d', burst_period)); % set menu=Train:Period=20s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

burst_duration = round((options.PulsePeriod * (options.PulsesPerBurst+1) + options.PostBurstBuffer / 2) * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 7 2 %d', burst_duration)); % set menu=Train:Duration=17.5s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

t_period = round(options.PulsePeriod * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 5 %d', t_period)); % set menu=Library1:Period:1.5s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 4 %d', options.PulsesPerBurst)); % set menu=Library1:Quantity:10
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

am4100.UserData.recording_duration = burst_period / 1e6;

end