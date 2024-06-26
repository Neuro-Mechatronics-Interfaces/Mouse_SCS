function SAGA_updateFileNames(client, logger, options)
%SAGA_UPDATEFILENAMES Update filenames for SAGA A and SAGA B devices. 
arguments
    client (1,1) % udpport connection to SAGA state machine
    logger (1,1) % mlog.Logger logging object
    options.Tag {mustBeTextScalar} = "STIM";
    options.RawDataRoot {mustBeTextScalar} = "";
    options.Intan = [];
end

SUBJ = client.UserData.subject; 
YYYY = client.UserData.year;
MM = client.UserData.month;
DD = client.UserData.day;
REC_TAG = options.Tag;
tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
sweep_folder = sprintf('%s_%04d_%02d_%02d_%d', SUBJ, YYYY, MM, DD, client.UserData.sweep);
new_emg_file_expr = sprintf('%s/%s/%s/%s_%04d_%02d_%02d_%s_%%s_%d', ...
    SUBJ, tank, sweep_folder, ...
    SUBJ, YYYY, MM, DD, REC_TAG, client.UserData.block);
writeline(client, new_emg_file_expr, ...
    client.UserData.saga.address, ...
    client.UserData.saga.port.name);
if ~isempty(options.Intan)
    if strlength(options.RawDataRoot) == 0
        raw_root = parameters('raw_data_folder_root');
    else
        raw_root = options.RawDataRoot;
    end
    full_sweep_folder = strrep(fullfile(raw_root, SUBJ, tank, sweep_folder),'\','/');
    if exist(full_sweep_folder, 'dir')==0
        mkdir(full_sweep_folder);
    end
    intan.setFile(options.Intan, SUBJ, YYYY, MM, DD, client.UserData.block, 'DataTankFolder', full_sweep_folder);
    logger.info('Updated Intan Folder: %s', full_sweep_folder);
end
logger.info(sprintf('Updated Filename = %s', new_emg_file_expr));

end