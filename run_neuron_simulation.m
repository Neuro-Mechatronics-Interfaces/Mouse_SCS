function run_neuron_simulation(sim_name, options)
%RUN_NEURON_SIMULATION  Run the NEURON simulation from MATLAB with live progress.
%
% Syntax:
%   run_neuron_simulation();
%   run_neuron_simulation('leak');
%   run_neuron_simulation('m2','Name', value, ...);
%
% Name-Value Options:
%   'HocFileExpression' = 'main_%s_freq_sweep.hoc'
%   'SimulationFolder'  = fullfile(pwd,"NEURON/MotorNeuron")
%   'OutputFolder'      = "out_%s"
%   'TERMINAL_COMMAND'  = "C:\Windows\System32\cmd.exe /c"
%   'NEURON_HOME'       = "C:/nrn/bin"
%   'LiveProgress'      = true
%   'HeartbeatFile'     = "" (auto: <OutputFolder>/heartbeat.txt)
%   'DoneMarker'        = "" (auto: <OutputFolder>/done.marker)
%   'LogFile'           = "" (auto: <OutputFolder>/runner.log)
%
% Notes:
% - Live progress requires Windows and that your HOC writes heartbeat JSON, e.g.:
%     {"k":12,"total":96,"elapsed":8.1,"eta":56.7}
%   and (ideally) touches a done marker when finished.
% - This wrapper also creates a done marker when the batch exits.

arguments
    sim_name (1,1) string {mustBeMember(sim_name,["leak","m2"])} = "leak"
    options.HocFileExpression (1,1) string = "main_%s_freq_sweep.hoc"
    options.SimulationFolder (1,1) string = fullfile(pwd,"NEURON/MotorNeuron")
    options.OutputFolder (1,1) string = "out_%s"
    options.TERMINAL_COMMAND (1,1) string = "C:\Windows\System32\cmd.exe /c"
    options.NEURON_HOME (1,1) string = "C:/nrn/bin"
    options.LiveProgress (1,1) logical = true
    options.HeartbeatFile (1,1) string = ""
    options.DoneMarker (1,1) string = ""
    options.LogFile (1,1) string = ""
end

hoc_file   = sprintf(options.HocFileExpression, sim_name);
nrn_home   = strrep(options.NEURON_HOME,"\","/");
sim_folder = strrep(options.SimulationFolder,"\","/");
out_folder = strrep(options.OutputFolder,"\","/");
if contains(out_folder,"%s")
    out_folder = sprintf(out_folder, sim_name);
end

% derived paths
if options.HeartbeatFile == ""
    heartbeat = fullfile(out_folder, "heartbeat.txt");
else
    heartbeat = options.HeartbeatFile;
end
if options.DoneMarker == ""
    done_marker = fullfile(out_folder, "done.marker");
else
    done_marker = options.DoneMarker;
end
if options.LogFile == ""
    logfile = fullfile(out_folder, "runner.log");
else
    logfile = options.LogFile;
end

% normalize to Windows separators for the shell
heartbeat_win  = strrep(heartbeat,  "/", "\");
done_marker_win= strrep(done_marker,"/","\");
logfile_win    = strrep(logfile,    "/","\");

% ensure output folder exists; also clear stale heartbeat/done/log
if ~exist(out_folder,'dir'), mkdir(out_folder); end
safe_delete(heartbeat); safe_delete(done_marker); safe_delete(logfile);

[root_folder,~,~] = fileparts(sim_folder);
bat_path = sprintf("%s/nrniv.bat", strrep(root_folder,"\","/"));

% --- Base command (without monitoring) ---
core_cmd = sprintf('"%s" "%s" "%s" "%s" "%s"', ...
    bat_path, sim_folder, hoc_file, out_folder, nrn_home);

% --- Windows live progress path: run in background, redirect log, create done marker ---
use_live = options.LiveProgress && ispc;

if use_live
    % Build a background command:
    % start /b "NEURON sim" cmd /c "<bat> args > log 2>&1 & echo done > done.marker"
    % Note: carets (^) escape special chars in Windows cmd when building strings.
    redirect = sprintf('^> "%s" 2^>^&1', logfile_win);
    wrapper  = sprintf('start "NEURON sim" /b cmd /c "%s %s & echo done > "%s""', ...
        core_cmd, redirect, done_marker_win);

    str_for_terminal = sprintf('%s %s', options.TERMINAL_COMMAND, wrapper);
else
    % Blocking path (no live progress)
    str_for_terminal = sprintf('%s "%s"', options.TERMINAL_COMMAND, core_cmd);
end

fprintf(1,"Attempting to run simulation:\n\t>>> %s\n\n", str_for_terminal);
t0 = tic;

if use_live
    % Launch background process
    [status_launch, msg_launch] = system(str_for_terminal);
    if status_launch ~= 0
        error("Failed to launch NEURON: %s", msg_launch);
    end

    % Live monitor loop
    fprintf(1,"Monitoring heartbeat: %s\n", heartbeat);
    fprintf(1,"Log file: %s\n\n", logfile);
    lastPrintedK = -1; total = NaN;
    spinner = ["|","/","-","\"];
    si = 1;

    while true
        % Done?
        if exist(done_marker,'file')
            % small grace period for final heartbeat/log flush
            pause(0.2);
            break
        end

        % Heartbeat?
        if exist(heartbeat,'file')
            try
                txt = fileread(heartbeat);
                % Read last non-empty line
                lines = regexp(txt, '\r?\n', 'split');
                lines = lines(~cellfun('isempty', lines));
                if ~isempty(lines)
                    hb = jsondecode(lines{end});
                    if isfield(hb,'k')
                        if lastPrintedK ~= hb.k
                            if isfield(hb,'total'), total = hb.total; end
                            eta = NaN; if isfield(hb,'eta'), eta = hb.eta; end
                            if isnan(total)
                                fprintf(1,'[%s] k=%d  ETA=%.1fs\n', spinner(si), hb.k, eta);
                            else
                                fprintf(1,'[%s] %6.2f%%  %d/%d  ETA=%.1fs\n', ...
                                    spinner(si), 100*hb.k/total, hb.k, total, eta);
                            end
                            lastPrintedK = hb.k;
                        end
                    end
                end
            catch  %#ok<CTCH>
                % ignore transient read/parse errors while file is being written
            end
        else
            % No heartbeat yet; show spinner
            fprintf(1,'[%s] waiting for heartbeat...\n', spinner(si));
        end

        si = mod(si, numel(spinner)) + 1;
        pause(0.5); % poll period
    end

    % Print final status / tail the last lines of log (optional)
    fprintf(1,"\nSimulation finished. Elapsed: %.1f s\n", toc(t0));
    if exist(logfile,'file')
        tail_log(logfile, 15);
    end
else
    % Blocking run with stdout returned on completion
    [status, cmdout] = system(str_for_terminal);
    fprintf(1,'Command finished. Exit Status: %d\n', status);
    if ~isempty(cmdout)
        fprintf(1,"%s\n", cmdout);
    end
    fprintf(1,"Elapsed: %.1f s\n", toc(t0));
end

end

% ------------- helpers -------------

function safe_delete(f)
try
    if exist(f,'file'), delete(f); end
catch
end
end

function tail_log(logfile, nlines)
try
    txt = fileread(logfile);
    lines = regexp(txt, '\r?\n', 'split');
    lines = lines(~cellfun('isempty', lines));
    m = numel(lines);
    k = max(1, m - nlines + 1);
    fprintf(1,"--- Last %d lines of log (%s) ---\n", m-k+1, logfile);
    fprintf(1,"%s\n", strjoin(lines(k:end), newline));
    fprintf(1,"---------------------------------\n");
catch e
    fprintf(1,"(Could not read log: %s)\n", e.message);
end
end
