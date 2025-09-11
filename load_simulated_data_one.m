function simdata = load_simulated_data_one(W1, W2, W3, options)
%LOAD_SIMULATED_DATA_ONE  Load data simulated using NEURON tool (new filename schema).
%
% Filenames expected (from HOC):
%   time_%s_p%.2f_%.2f_%.2f_%g_%g_%g_%ggl_%gm2_%gblend_%dHz.dat
%   voltage_%s_p%.2f_%.2f_%.2f_%g_%g_%g_%ggl_%gm2_%gblend_%dHz.dat
% where %s = SeqAbbr; the three %.2f are (p0,p1,p2).
%
% Options:
%   SimulationOutputFolder  = fullfile(pwd,"NEURON/MotorNeuron/out_leak")
%   FrequenciesFile         = "frequencies.dat"
%   M2LevelsFile            = "m2_levels.dat"
%   LeakLevelsFile          = "leak_levels.dat"
%   BlendingLevelsFile      = "blending_levels.dat"
%   SeqModesFile            = "syn_sequence_modes.tsv"
%   PulseIntensitiesFile    = "pulse_intensities.tsv"
%   IncludeSeqModes         = []   % e.g., [0 1]; empty = all
%   IncludeIntensityRows    = []   % indices into rows of pulse_intensities.tsv; empty = all
%   MissingOK               = true % skip missing files with warning instead of error
%
% Returns table with columns:
%   SeqMode, SeqName, SeqAbbr, P0,P1,P2, M2_Level, Leak, W1,W2,W3, Blending_Level, Frequency, Time, Voltage

arguments
    W1 (1,1) double
    W2 (1,1) double
    W3 (1,1) double
    options.APThreshold (1,1) double = -10; % mV
    options.SimulationOutputFolder = fullfile(pwd,"NEURON/MotorNeuron/out_leak")
    options.FrequenciesFile = "frequencies.dat"
    options.M2LevelsFile = "m2_levels.dat"
    options.LeakLevelsFile = "leak_levels.dat"
    options.BlendingLevelsFile = "blending_levels.dat"
    options.SeqModesFile = "syn_sequence_modes.tsv"
    options.PulseIntensitiesFile = "pulse_intensities.tsv"
    options.WeightsFile = "weights.tsv";
    options.IncludeSeqModes double = []
    options.IncludeIntensityRows double = []
    options.MissingOK (1,1) logical = false
end

outdir = options.SimulationOutputFolder;

% --- scalar sweep axes ---
Frequency = load(fullfile(outdir, options.FrequenciesFile));   Frequency = Frequency(:);
M2_Level  = load(fullfile(outdir, options.M2LevelsFile));      M2_Level  = M2_Level(:);
Leak      = load(fullfile(outdir, options.LeakLevelsFile));    Leak      = Leak(:);
Blend     = load(fullfile(outdir, options.BlendingLevelsFile));Blend     = Blend(:);

% --- sequence modes (tsv: mode, name, syn0.e, syn1.e, syn2.e) ---
seqPath = fullfile(outdir, options.SeqModesFile);
seqT = readtable(seqPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);
SeqModeAll = seqT.mode(:);
SeqNameAll = string(seqT.name(:));

% Build abbreviations (or add an 'abbr' column in the tsv and read it)
SeqAbbrAll = arrayfun(@(i) infer_seq_abbr(SeqNameAll(i)), 1:numel(SeqNameAll), 'UniformOutput', false);
SeqAbbrAll = string(SeqAbbrAll(:));

if ~isempty(options.IncludeSeqModes)
    keep = ismember(SeqModeAll, options.IncludeSeqModes(:));
    SeqModeAll = SeqModeAll(keep);
    SeqNameAll = SeqNameAll(keep);
    SeqAbbrAll = SeqAbbrAll(keep);
end

% --- pulse intensities (tsv: row, p0, p1, p2) ---
piPath = fullfile(outdir, options.PulseIntensitiesFile);
piT = readtable(piPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);
% Support header names 'row','p0','p1','p2' (case-insensitive)
vnames = lower(string(piT.Properties.VariableNames));
p0col = find(vnames=="p0",1); p1col = find(vnames=="p1",1); p2col = find(vnames=="p2",1);
if any(isempty([p0col,p1col,p2col]))
    error('pulse_intensities.tsv must contain columns p0, p1, p2.');
end
P0All = piT{:,p0col};  P1All = piT{:,p1col};  P2All = piT{:,p2col};
P0All = P0All(:); P1All = P1All(:); P2All = P2All(:);

if ~isempty(options.IncludeIntensityRows)
    % If your TSV also has an explicit 'row' index, filter by that; otherwise by position
    if any(vnames=="row")
        rowcol = find(vnames=="row",1);
        keep = ismember(piT{:,rowcol}, options.IncludeIntensityRows(:));
    else
        keep = false(height(piT),1);
        keep(options.IncludeIntensityRows(options.IncludeIntensityRows<=height(piT))) = true;
    end
    P0All = P0All(keep); P1All = P1All(keep); P2All = P2All(keep);
end

% --- build Cartesian product (all column vectors) ---
Frequency = Frequency(:); M2_Level = M2_Level(:); Leak = Leak(:); Blend = Blend(:);

SeqModeAll = string(SeqModeAll);
SeqNameAll = string(SeqNameAll);
SeqAbbrAll = string(SeqAbbrAll);
[SeqIdx, PIIdx, LeakIdx, M2Idx, BlendIdx, FIdx] = ndgrid( ...
    1:numel(SeqModeAll), ...
    1:numel(P0All), ...
    1:numel(Leak), ...
    1:numel(M2_Level), ...
    1:numel(Blend), ...
    1:numel(Frequency));

N = numel(SeqIdx);

SeqMode = SeqModeAll(SeqIdx(:));
SeqName = SeqNameAll(SeqIdx(:));
SeqAbbr = SeqAbbrAll(SeqIdx(:));

P0 = P0All(PIIdx(:));
P1 = P1All(PIIdx(:));
P2 = P2All(PIIdx(:));

LeakV  = Leak(LeakIdx(:));
M2V    = M2_Level(M2Idx(:));
BlendV = Blend(BlendIdx(:));
FreqV  = Frequency(FIdx(:));

% --- Load traces; mark missing, then DROP them before creating the table ---
Time    = cell(N,1);
Voltage = cell(N,1);
missing = false(N,1);

for k = 1:N
    p0s = sprintf('%.2f', P0(k));
    p1s = sprintf('%.2f', P1(k));
    p2s = sprintf('%.2f', P2(k));
    base = sprintf('%s_p%s_%s_%s_%g_%g_%g_%ggl_%gm2_%gblend_%dHz.dat', ...
        SeqAbbr(k), p0s, p1s, p2s, W1, W2, W3, LeakV(k), M2V(k), BlendV(k), round(FreqV(k)));

    fTime = fullfile(outdir, ['time_'    base]);
    fVolt = fullfile(outdir, ['voltage_' base]);

    if exist(fTime,'file') ~= 2 || exist(fVolt,'file') ~= 2
        missing(k) = true;
        if ~options.MissingOK
            error('Missing file(s):\n%s\n%s', fTime, fVolt);
        end
        continue
    end

    Time{k}    = load(fTime);
    Voltage{k} = load(fVolt);
end

% Keep only rows with both files present
keep = ~missing;

SeqMode = SeqMode(keep);  SeqName = SeqName(keep);  SeqAbbr = SeqAbbr(keep);
P0 = P0(keep); P1 = P1(keep); P2 = P2(keep);
LeakV = LeakV(keep); M2V = M2V(keep); BlendV = BlendV(keep); FreqV = FreqV(keep);
Time = Time(keep); Voltage = Voltage(keep);

% Columnize everything (defensive)
SeqMode = SeqMode(:); SeqName = SeqName(:); SeqAbbr = SeqAbbr(:);
P0 = P0(:); P1 = P1(:); P2 = P2(:);
LeakV = LeakV(:); M2V = M2V(:); BlendV = BlendV(:); FreqV = FreqV(:);
Time = Time(:); Voltage = Voltage(:);

W1col = repmat(W1, numel(SeqMode), 1);
W2col = repmat(W2, numel(SeqMode), 1);
W3col = repmat(W3, numel(SeqMode), 1);

% ---- Derive sweep labels from weights + blend ----
tol = 1e-9;

eq12 = abs(W1col - W2col) <= tol;
eq23 = abs(W2col - W3col) <= tol;
isConstant   =  eq12 & eq23;

isIncreasing =  (W1col <= W2col + tol) & (W2col <= W3col + tol) & ~isConstant;
isDecreasing =  (W1col >= W2col - tol) & (W2col >= W3col - tol) & ~isConstant;

SweepBase = strings(numel(W1col),1);
SweepBase(isConstant)   = "Constant";
SweepBase(isIncreasing) = "Increasing";
SweepBase(isDecreasing) = "Decreasing";
SweepBase(SweepBase=="") = "Custom";  % anything else (e.g., up-down)

% Append blending iff nonzero
blendPct = round(100*BlendV);
hasBlend = BlendV > tol;
SweepName = SweepBase;
SweepName(hasBlend) = SweepBase(hasBlend) + " (" + string(blendPct(hasBlend)) + "% blending)";


% Final sanity check (all same height)
heights = cellfun(@(x) size(x,1), {SeqMode, SeqName, SeqAbbr, P0, P1, P2, ...
                                    M2V, LeakV, W1col, W2col, W3col, BlendV, FreqV, Time, Voltage, SweepBase, SweepName});
assert(all(heights == heights(1)), 'Internal size mismatch before table creation.');

simdata = table(SeqMode, SeqName, SeqAbbr, P0, P1, P2, ...
                M2V, LeakV, W1col, W2col, W3col, BlendV, FreqV, Time, Voltage, ...
                SweepBase, SweepName, ...
    'VariableNames', {'SeqMode','SeqName','SeqAbbr','P0','P1','P2', ...
                      'M2_Level','Leak','W1','W2','W3','Blending_Level','Frequency','Time','Voltage', ...
                      'SweepBase','SweepName'});
simdata.Peaks = zeros(height(simdata),1);
simdata.PreSynapticRate = zeros(height(simdata),1);
simdata.PostSynapticRate = zeros(height(simdata),1);
for ii = 1:height(simdata)
    pks = findpeaks(simdata.Voltage{ii}, 'MinPeakHeight', options.APThreshold);
    simdata.Peaks(ii) = numel(pks);
    simdata.PreSynapticRate(ii) = simdata.Frequency(ii)/3; % stim intervals are 9000 ms divided by freq, for 3 interleaved netstim; 3x gap allows "burstiness" but divides total stimuli effectively by 3.  
    simdata.PostSynapticRate(ii) = simdata.Peaks(ii)/((simdata.Time{ii}(end)-simdata.Time{ii}(1))/1000); % spikes/sec
end
end

function ab = infer_seq_abbr(name)
% map your HOC names to short tags used in filenames
n = lower(strtrim(name));
switch n
    case 'epsp_only',            ab = 'E3';
    case 'ipsp_ipsp_epsp',       ab = 'IIE';
    case 'ipsp_only',            ab = 'I3';
    case 'ipsp_epsp_epsp',       ab = 'IEE';
    case 'epsp_ipsp_epsp',       ab = 'EIE';
    case 'ipsp_epsp_ipsp',       ab = 'IEI';
    case 'custom',               ab = 'CUST';
    otherwise
        % simple heuristic: count E/I tokens
        if contains(n,'ipsp') && contains(n,'epsp')
            ab = 'MIX';
        elseif contains(n,'ipsp')
            ab = 'I3';
        elseif contains(n,'epsp')
            ab = 'E3';
        else
            ab = 'CUST';
        end
end
end
