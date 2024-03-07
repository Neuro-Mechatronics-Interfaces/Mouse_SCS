function AM4100_setStimParameters(am4100, logger, A1, D1, A2, D2, T, N, options)
%AM4100_SETSTIMPARAMETERS Set the stimulation parameters for AM4100 experiment

arguments
    am4100 % tcpclient connection to AM4100 system
    logger % mlog.Logger object
    A1 (1,1) double {mustBeInteger} = 1000 % Amplitude (micro-amperes) for phase 1
    D1 (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(D1,0)} = 200  % Duration (micro-seconds) for phase 1
    A2 (1,1) double {mustBeInteger} = -1000 % Amplitude (micro-amperes) for phase 2
    D2 (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(D2,0)} = 200  % Duration (micro-seconds) for phase 2
    T  (1,1) double {mustBeGreaterThanOrEqual(T, 0)} = 1.5; % Period between stim events (time between single-pulse stimuli); seconds
    N  (1,1) double {mustBeInteger, mustBePositive} = 10;
    options.InterPhaseInterval (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.InterPhaseInterval, 0)} = 50; % Microseconds between phases
    options.TBuffer (1,1) double = 10;
end

if sign(A2) == sign(A1)
    A2 = -A2; % Flip sign if both signs are the same. 
end
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a stop');
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 0 0 1'); % set menu=General:Mode:Internal Current
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 0 1 6'); % set menu=General:Monitor:1mA/V
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 4 0 1'); % set menu=UniformEvent:Library:1
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 7 0'); % set menu=Train:Type=Uniform
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 7 4 1'); % set menu=Train:Number=1
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

% % % Set the number of pulses etc. % % %
AM4100_setStimEventPeriodAndCount(am4100, logger, T, N, options.TBuffer);

% % % Configure the Event parameters % % %
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s m 10 2 2'); % set menu=Library1:Type:Asymm
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 6 %d', D1)); % set menu=Library1:Duration1: 0.2ms
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

AM4100_setInterPhaseInterval(am4100, logger, options.InterPhaseInterval); % 50-microsecond inter-phase interval

[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 9 %d', D2)); % set menu=Library1:Dur2:0.8 ms
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 7 %d', A1)); % set menu=Library1:Amplitude1 1mA
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));
[rplStr,inputStr]=AM4100_sendCommand(am4100,sprintf('1001 s m 10 10 %d', A2)); % set menu=Library1:Amplitude2 -250uA
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

% % % Set the stimulator ready to run % % %
[rplStr,inputStr]=AM4100_sendCommand(am4100,'1001 s a run');    % When you are done changing values RUN
logger.info(sprintf('sent = %s', inputStr));
logger.info(sprintf('reply = %s', rplStr));

end