function AM4100_setStimParameters(am4100, logger, A1, D1, A2, D2, options)
%AM4100_SETSTIMPARAMETERS Set the stimulation parameters for AM4100 experiment

arguments
    am4100 % tcpclient connection to AM4100 system
    logger % mlog.Logger object
    A1 (1,1) double {mustBeInteger} = 1000 % Amplitude (micro-amperes) for phase 1
    D1 (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(D1,0)} = 200  % Duration (micro-seconds) for phase 1
    A2 (1,1) double {mustBeInteger} = -1000 % Amplitude (micro-amperes) for phase 2
    D2 (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(D2,0)} = 200  % Duration (micro-seconds) for phase 2
    options.PulsePeriod  (1,1) double {mustBeGreaterThanOrEqual(options.PulsePeriod, 0)} = 1.5; % Period between stim events (time between single-pulse stimuli); seconds
    options.PulsesPerBurst  (1,1) double {mustBeInteger, mustBePositive} = 10;
    options.InterPhaseInterval (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.InterPhaseInterval, 0)} = 50; % Microseconds between phases
    options.PostBurstBuffer (1,1) double = 2.5;
    options.NBursts (1,1) double {mustBeInteger, mustBePositive} = 1;
    options.Monophasic (1,1) logical = false;
end

if sign(A2) == sign(A1)
    A2 = -A2; % Flip sign if both signs are the same. 
end
if am4100.UserData.enable
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a stop');
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end

    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 0 0 1'); % set menu=General:Mode:Internal Current
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 0 1 6'); % set menu=General:Monitor:1mA/V
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 1 1 6'); % set menu=Configuration:Sync1:6=EvntTotalDur
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 4 0 1'); % set menu=UniformEvent:Library:1
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 7 0'); % set menu=Train:Type=Uniform
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 7 4 %d', options.NBursts)); % set menu=Train:Number=1
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
    % % % Set the number of pulses etc. % % %
    AM4100_setStimEventPeriodAndCount(am4100, logger, ...
        'PulsePeriod', options.PulsePeriod,  ...
        'PulsesPerBurst', options.PulsesPerBurst, ...
        'PostBurstBuffer', options.PostBurstBuffer, ...
        'NBursts', options.NBursts);
    
    % % % Configure the Event parameters % % %
    if options.Monophasic
        [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 10 2 0'); % set menu=Library1:Type:Mono
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
        
        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 6 %d', D1)); % set menu=Library1:Duration1: 0.2ms
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end

        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 7 %d', A1)); % set menu=Library1:Amplitude1 1mA
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
    else
        [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 10 2 2'); % set menu=Library1:Type:Asymm
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
        
        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 6 %d', D1)); % set menu=Library1:Duration1: 0.2ms
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
        
        AM4100_setInterPhaseInterval(am4100, logger, options.InterPhaseInterval); % 50-microsecond inter-phase interval
        
        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 9 %d', D2)); % set menu=Library1:Dur2:0.8 ms
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 7 %d', A1)); % set menu=Library1:Amplitude1 1mA
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
        [rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 10 %d', A2)); % set menu=Library1:Amplitude2 -250uA
        if ~isempty(logger)
            logger.info(sprintf('sent = %s', inputStr));
            logger.info(sprintf('reply = %s', rplStr));
        end
    end
    % % % Set the stimulator ready to run % % %
    [rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a run');    % When you are done changing values RUN
    if ~isempty(logger)
        logger.info(sprintf('sent = %s', inputStr));
        logger.info(sprintf('reply = %s', rplStr));
    end
end
end