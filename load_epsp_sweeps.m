function T = load_epsp_sweeps(outdir, opts)
%LOAD_EPSP_SWEEPS  Load EPSP sweep results + traces and compute spike statistics.
%
% T = load_epsp_sweeps(outdir)
% T = load_epsp_sweeps(outdir, opts)
%
% Inputs
%   outdir : folder containing files produced by epsp_rate_current_clamp_sweep.hoc (default: './NEURON/MotorNeuron/out_epsp')
%   opts.APThreshold_mV : spike detection threshold (default -10)
%   opts.MissingOK      : true = skip missing traces with warning (default true)
%   opts.Verbose        : true = print progress (default true)
%
% Output table columns
%   Rate_Hz, DC_nA, Weight_uS, Seed, SpikeCount, Duration_ms, FiringRate_Hz
%   Time_ms (cell), Vm_mV (cell)
%   NumPeaks, PeakTimes_ms (cell), CoV_ISI

if nargin < 1 || isempty(outdir)
    outdir = fullfile(pwd, 'NEURON', 'MotorNeuron', 'out_epsp');
end
if nargin < 2, opts = struct(); end
if ~isfield(opts, 'APThreshold_mV'), opts.APThreshold_mV = -10; end
if ~isfield(opts, 'MissingOK'),      opts.MissingOK      = true; end
if ~isfield(opts, 'Verbose'),        opts.Verbose        = true; end

% --- sanity: results.tsv is the authoritative index
resPath = fullfile(outdir, 'results.tsv');
if ~exist(resPath, 'file')
    error('results.tsv not found at: %s', resPath);
end

% Read results.tsv (tab-delimited with header)
R = readtable(resPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);

% Normalize expected variable names (tolerant to case/order)
vn = lower(string(R.Properties.VariableNames));
rate_Hz       = R{:, vn=="rate_hz"};
DC_nA         = R{:, vn=="dc_na"};
Weight_uS     = R{:, vn=="weight_us"};
Seed          = R{:, vn=="seed"};
SpikeCount    = R{:, vn=="spike_count"};
Duration_ms   = R{:, vn=="duration_ms"};
firing_rate_Hz = R{:, vn=="firing_rate_hz"};

N = height(R);

% Pre-allocate outputs
Time_ms       = cell(N,1);
Vm_mV         = cell(N,1);
NumPeaks      = zeros(N,1);
PeakTimes_ms  = cell(N,1);
CoV_ISI       = nan(N,1);

% Pre-scan directory to avoid repeated dir() calls
files = dir(fullfile(outdir, 'trace_rate_*Hz_DC_*_nA_w_*_uS.tsv'));
names = {files.name}';

% Build parse cache from filenames -> numeric triple (rate, dc, w)
ftriples = nan(numel(names), 3);
for k = 1:numel(names)
    [ok, a,b,c] = parse_trace_fname(names{k});
    if ok, ftriples(k,:) = [a,b,c]; end
end

% Helper: numeric match tolerance (handles %g formatting)
tolRate = 1e-9;   % rate is an integer in your examples; keep tight
tolDC   = 1e-6;   % DC printed with %g; allow tiny float diffs
tolW    = 1e-9;

if opts.Verbose
    fprintf('Found %d trace files in %s\n', numel(names), outdir);
end

% Main loop
for i = 1:N
    rate = rate_Hz(i);
    dc   = DC_nA(i);
    w    = Weight_uS(i);

    % Try exact file name first (fast path)
    exact = sprintf('trace_rate_%gHz_DC_%g_nA_w_%g_uS.tsv', rate, dc, w);
    fpath = fullfile(outdir, exact);

    if ~exist(fpath, 'file')
        % Fallback: tolerant match from parsed directory listing
        idx = find( abs(ftriples(:,1)-rate)<=tolRate & ...
                    abs(ftriples(:,2)-dc)  <=tolDC   & ...
                    abs(ftriples(:,3)-w)   <=tolW, 1, 'first');
        if ~isempty(idx)
            fpath = fullfile(outdir, names{idx});
        end
    end

    if ~exist(fpath, 'file')
        if opts.MissingOK
            if opts.Verbose
                warning('Missing trace for (rate=%g, DC=%g, W=%g). Row %d skipped for trace/peaks.', rate, dc, w, i);
            end
            continue
        else
            error('Missing trace for (rate=%g, DC=%g, W=%g).', rate, dc, w);
        end
    end

    % Load trace (two columns with header)
    T = readmatrix(fpath, 'FileType','text', 'Delimiter','\t', 'NumHeaderLines',1);
    if size(T,2) < 2
        if opts.MissingOK
            warning('Trace file malformed: %s', fpath);
            continue
        else
            error('Trace file malformed: %s', fpath);
        end
    end
    t = T(:,1); v = T(:,2);

    Time_ms{i} = t;
    Vm_mV{i}   = v;

    % Spike detection from Vm
    [pks, locs] = findpeaks(v, 'MinPeakHeight', opts.APThreshold_mV);
    NumPeaks(i)     = numel(pks);
    PeakTimes_ms{i} = t(locs);

    % CoV_ISI (seconds)
    if numel(locs) >= 2
        isi = diff(t(locs)) / 1000;       % sec
        mu  = mean(isi);
        sd  = std(isi, 0);
        if mu > 0
            CoV_ISI(i) = sd / mu;
        else
            CoV_ISI(i) = NaN;
        end
    else
        CoV_ISI(i) = NaN;
    end
end

% Final table
T = table( ...
    rate_Hz, DC_nA, Weight_uS, Seed, SpikeCount, Duration_ms, firing_rate_Hz, ...
    Time_ms, Vm_mV, NumPeaks, PeakTimes_ms, CoV_ISI);

% (Optional) attach fixed params JSON if present
fixedJson = fullfile(outdir, 'fixed_params.json');
if exist(fixedJson, 'file')
    try
        meta = jsondecode(fileread(fixedJson));
        T.Properties.UserData.fixed_params = meta;
    catch
        % ignore JSON issues
    end
end
end

function [ok, rate, dc, w] = parse_trace_fname(fname)
% Parse: trace_rate_%gHz_DC_%g_nA_w_%g_uS.tsv
ok = false; rate = NaN; dc = NaN; w = NaN;
expr = '^trace_rate_([\-0-9.eE]+)Hz_DC_([\-0-9.eE]+)_nA_w_([\-0-9.eE]+)_uS\.tsv$';
tok = regexp(fname, expr, 'tokens', 'once');
if isempty(tok), return; end
rate = str2double(tok{1});
dc   = str2double(tok{2});
w    = str2double(tok{3});
ok = all(~isnan([rate, dc, w]));
end
