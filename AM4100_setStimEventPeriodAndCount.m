function AM4100_setStimEventPeriodAndCount(am4100, logger, T, N, tBuffer) 
%AM4100_SETSTIMEVENTPERIODANDCOUNT Set the AM4100 stimulation event period and number of stimuli.

arguments
    am4100 % tcpclient connection to AM4100 stimulator device
    logger % mlog.Logger logging object
    T (1,1) double = 1.5; % Number of seconds between each stim event HIGH edge
    N (1,1) double {mustBePositive, mustBeInteger} = 10; % Number of events for a given stim level
    tBuffer (1,1) double = 5.0; % Number of seconds to "buffer" at the end of the event train
end

t_total = round((T * (N+1) + tBuffer) * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 7 3 %d', t_total)); % set menu=Train:Period=20s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

t_duration = round((T * (N+1) + tBuffer / 2) * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 7 2 %d', t_duration)); % set menu=Train:Duration=17.5s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

t_period = round(T * 1e6);
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 5 %d', t_period)); % set menu=Library1:Period:1.5s
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 4 %d', N)); % set menu=Library1:Quantity:10
if ~isempty(logger)
    logger.info(sprintf('sent = %s', inputStr));
    logger.info(sprintf('reply = %s', rplStr));
end

am4100.UserData.recording_duration = t_total / 1e6;

end