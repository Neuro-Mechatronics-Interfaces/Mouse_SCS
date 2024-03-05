function record(client, options)
%%RECORD  Run and increment the recording for TMSi-SAGAs AND Plexon (do not manually increment Plexon!)

arguments
    client
    options.SagaCommandPauseDuration (1,1) double {mustBePositive} = 0.25; % seconds
    options.SagaRecordingBufferDuration (1,1) double {mustBePositive} = 500; % seconds
    options.PlexDoPlexRecTriggerPin (1,1) double {mustBeInteger, mustBePositive} = 5;
    options.PlexRecPulseDuration (1,1) double {mustBeInteger, mustBePositive} = 50; % milliseconds
    options.PlexRecStartSyncPulseOffset (1,1) double {mustBePositive} = 1.5; % seconds
    options.PlexDoGoPin (1,1) double {mustBeInteger, mustBePositive} = 10;
    options.GoPulseDuration (1,1) double {mustBeInteger, mustBePositive} = 100; % milliseconds
    options.Tag {mustBeTextScalar} = 'STIM';
    options.Block {mustBeInteger} = [];
end

REC_TAG = options.Tag;

SUBJ = client.UserData.subject; 
YYYY = client.UserData.year;
MM = client.UserData.month;
DD = client.UserData.day;

writeline(client, 'run', client.UserData.saga.address, client.UserData.saga.port.control);
pause(options.SagaCommandPauseDuration);
setBufferSize(client, options.SagaRecordingBufferDuration, 'seconds');

if isempty(options.Block)
    client.UserData.block =  client.UserData.block + 1; 
    block = client.UserData.block;
    fprintf(1,'Incremented `block` to %d.\n', block);
else
    block = options.Block;
    fprintf(1,'Did not change `block` count! Block set to %d.\n', block);
end
new_emg_file_expr = sprintf('%s/%s_%04d_%02d_%02d_%s_%%s_%d', ...
    SUBJ, SUBJ, YYYY, MM, DD, REC_TAG, block);
writeline(client, new_emg_file_expr, ...
    client.UserData.saga.address, ...
    client.UserData.saga.port.name);
pause(options.SagaCommandPauseDuration);
writeline(client, 'rec', client.UserData.saga.address, client.UserData.saga.port.control);
fprintf(1,'Recording EMG for <strong>%s</strong>\n', new_emg_file_expr);

end
