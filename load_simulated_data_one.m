function simdata = load_simulated_data_one(W1, W2, W3, options)
%LOAD_SIMULATED_DATA_ONE  Load data simulated using NEURON tool (new filename schema).
%
% New filenames (preferred):
%   time_%s_p%.2f_%.2f_%.2f_%g_%g_%g_%gdiam_%gm2_%gblend_%dHz.dat
%   voltage_%s_p%.2f_%.2f_%.2f_%g_%g_%g_%gdiam_%gm2_%gblend_%dHz.dat
% Fallback (legacy):
%   ..._%ggl_...      (if diam-based files not found)
%
% Options (added/renamed):
%   SimulationOutputFolder  = fullfile(pwd,"NEURON/MotorNeuron/out_leak")
%   FrequenciesFile         = "frequencies.dat"
%   M2LevelsFile            = "m2_levels.dat"
%   DiamLevelsFile          = "diam_levels.dat"     % NEW (preferred)
%   LeakLevelsFile          = "leak_levels.dat"     % legacy fallback
%   BlendingLevelsFile      = "blending_levels.dat"
%   SeqModesFile            = "syn_sequence_modes.tsv"
%   PulseIntensitiesFile    = "pulse_intensities.tsv"
%   WeightsFile             = "weights.tsv"
%   SynapseJSONFile         = "synapse_params_by_mode.json"   % NEW
%   BiophysicsJSONFile      = "biophysics.json"               % NEW
%   IncludeSeqModes         = []
%   IncludeIntensityRows    = []
%   MissingOK               = false
%   APThreshold             = -10
%
% Returns a table with columns:
%   SeqMode, SeqName, SeqAbbr, P0,P1,P2, M2_Level, Diam, W1,W2,W3, Blending_Level, Frequency, Time, Voltage
% and attaches metadata to: simdata.Properties.UserData.Metadata (struct)

arguments
    W1 (1,1) double
    W2 (1,1) double
    W3 (1,1) double
    options.APThreshold (1,1) double = 10; % mV
    options.SimulationOutputFolder = fullfile(pwd,"NEURON/MotorNeuron/out_leak")
    options.FrequenciesFile = "frequencies.dat"
    options.M2LevelsFile = "m2_levels.dat"
    options.DiamLevelsFile = "diam_levels.dat"
    options.LeakLevelsFile = "leak_levels.dat"      % kept for backward-compat
    options.BlendingLevelsFile = "blending_levels.dat"
    options.SeqModesFile = "syn_sequence_modes.tsv"
    options.PulseIntensitiesFile = "pulse_intensities.tsv"
    options.WeightsFile = "weights.tsv"
    options.SynapseJSONFile = "synapse_params_by_mode.json"
    options.BiophysicsJSONFile = "biophysics.json"
    options.IncludeSeqModes double = []
    options.IncludeIntensityRows double = []
    options.MissingOK (1,1) logical = false
end

outdir = options.SimulationOutputFolder;

% -------- scalar sweep axes --------
Frequency = load(fullfile(outdir, options.FrequenciesFile));   Frequency = Frequency(:);
M2_Level  = load(fullfile(outdir, options.M2LevelsFile));      M2_Level  = M2_Level(:);

% Prefer diam sweep; fall back to leak if needed
diamPath = fullfile(outdir, options.DiamLevelsFile);
if exist(diamPath,'file') == 2
    Diam = load(diamPath);  Diam = Diam(:);
    useDiam = true;
else
    % legacy fallback
    leakPath = fullfile(outdir, options.LeakLevelsFile);
    if exist(leakPath,'file') == 2
        Diam = load(leakPath);  Diam = Diam(:);   % store in Diam variable for unified code path
        useDiam = false;
        warning('Using legacy leak_levels.dat as the sweep axis (stored in Diam).');
    else
        error('Neither diam_levels.dat nor leak_levels.dat found in %s', outdir);
    end
end

Blend     = load(fullfile(outdir, options.BlendingLevelsFile)); Blend = Blend(:);

% -------- sequence modes (TSV) --------
seqPath = fullfile(outdir, options.SeqModesFile);
seqT = readtable(seqPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);

% Required column: mode
if ~ismember('mode', lower(string(seqT.Properties.VariableNames)))
    error('syn_sequence_modes.tsv must include a "mode" column.');
end

% Optional: abbr column now provided by HOC; if absent, infer
vnamesLower = lower(string(seqT.Properties.VariableNames));
modeCol = find(vnamesLower=="mode",1);
nameCol = find(vnamesLower=="name",1);
abbrCol = find(vnamesLower=="abbr",1);

if isempty(nameCol)
    error('syn_sequence_modes.tsv must include a "name" column.');
end

SeqModeAll = seqT{:,modeCol};
SeqNameAll = string(seqT{:,nameCol});

if isempty(abbrCol)
    SeqAbbrAll = arrayfun(@(i) infer_seq_abbr(SeqNameAll(i)), 1:numel(SeqNameAll), 'UniformOutput', false);
    SeqAbbrAll = string(SeqAbbrAll(:));
else
    SeqAbbrAll = string(seqT{:,abbrCol});
end

if ~isempty(options.IncludeSeqModes)
    keep = ismember(SeqModeAll, options.IncludeSeqModes(:));
    SeqModeAll = SeqModeAll(keep);
    SeqNameAll = SeqNameAll(keep);
    SeqAbbrAll = SeqAbbrAll(keep);
end

% -------- pulse intensities (TSV) --------
piPath = fullfile(outdir, options.PulseIntensitiesFile);
piT = readtable(piPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);
vnames = lower(string(piT.Properties.VariableNames));
p0col = find(vnames=="p0",1); p1col = find(vnames=="p1",1); p2col = find(vnames=="p2",1);
if any(isempty([p0col,p1col,p2col]))
    error('pulse_intensities.tsv must contain columns p0, p1, p2.');
end
P0All = piT{:,p0col};  P1All = piT{:,p1col};  P2All = piT{:,p2col};
P0All = P0All(:); P1All = P1All(:); P2All = P2All(:);

if ~isempty(options.IncludeIntensityRows)
    if any(vnames=="row")
        rowcol = find(vnames=="row",1);
        keep = ismember(piT{:,rowcol}, options.IncludeIntensityRows(:));
    else
        keep = false(height(piT),1);
        idx = options.IncludeIntensityRows(options.IncludeIntensityRows<=height(piT));
        keep(idx) = true;
    end
    P0All = P0All(keep); P1All = P1All(keep); P2All = P2All(keep);
end

% -------- Cartesian product (all column vectors) --------
Frequency = Frequency(:); M2_Level = M2_Level(:); Diam = Diam(:); Blend = Blend(:);
SeqModeAll = string(SeqModeAll);  SeqNameAll = string(SeqNameAll);  SeqAbbrAll = string(SeqAbbrAll);

[SeqIdx, PIIdx, DiamIdx, M2Idx, BlendIdx, FIdx] = ndgrid( ...
    1:numel(SeqModeAll), ...
    1:numel(P0All), ...
    1:numel(Diam), ...
    1:numel(M2_Level), ...
    1:numel(Blend), ...
    1:numel(Frequency));

N = numel(SeqIdx);

SeqMode = SeqModeAll(SeqIdx(:));
SeqName = SeqNameAll(SeqIdx(:));
SeqAbbr = SeqAbbrAll(SeqIdx(:));

P0 = P0All(PIIdx(:));  P1 = P1All(PIIdx(:));  P2 = P2All(PIIdx(:));

DiamV  = Diam(DiamIdx(:));
M2V    = M2_Level(M2Idx(:));
BlendV = Blend(BlendIdx(:));
FreqV  = Frequency(FIdx(:));

% -------- Load traces; mark missing, then drop --------
Time    = cell(N,1);
Voltage = cell(N,1);
missing = false(N,1);

for k = 1:N
    p0s = sprintf('%.2f', P0(k));
    p1s = sprintf('%.2f', P1(k));
    p2s = sprintf('%.2f', P2(k));

    % try new file pattern (diam), else fallback (gl)
    base_diam = sprintf('%s_p%s_%s_%s_%g_%g_%g_%gdiam_%gm2_%gblend_%dHz.dat', ...
        SeqAbbr(k), p0s, p1s, p2s, W1, W2, W3, DiamV(k), M2V(k), BlendV(k), round(FreqV(k)));
    fTime = fullfile(outdir, ['time_'    base_diam]);
    fVolt = fullfile(outdir, ['voltage_' base_diam]);

    if ~(exist(fTime,'file') == 2 && exist(fVolt,'file') == 2)
        % fallback to legacy "gl"
        base_gl = sprintf('%s_p%s_%s_%s_%g_%g_%g_%ggl_%gm2_%gblend_%dHz.dat', ...
            SeqAbbr(k), p0s, p1s, p2s, W1, W2, W3, DiamV(k), M2V(k), BlendV(k), round(FreqV(k)));
        fTime = fullfile(outdir, ['time_'    base_gl]);
        fVolt = fullfile(outdir, ['voltage_' base_gl]);
    end

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

keep = ~missing;
SeqMode = SeqMode(keep);  SeqName = SeqName(keep);  SeqAbbr = SeqAbbr(keep);
P0 = P0(keep); P1 = P1(keep); P2 = P2(keep);
DiamV = DiamV(keep); M2V = M2V(keep); BlendV = BlendV(keep); FreqV = FreqV(keep);
Time = Time(keep); Voltage = Voltage(keep);

% Columnize everything
SeqMode = SeqMode(:); SeqName = SeqName(:); SeqAbbr = SeqAbbr(:);
P0 = P0(:); P1 = P1(:); P2 = P2(:);
DiamV = DiamV(:); M2V = M2V(:); BlendV = BlendV(:); FreqV = FreqV(:);
Time = Time(:); Voltage = Voltage(:);

W1col = repmat(W1, numel(SeqMode), 1);
W2col = repmat(W2, numel(SeqMode), 1);
W3col = repmat(W3, numel(SeqMode), 1);

% -------- Derive sweep labels from weights + blend --------
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
SweepBase(SweepBase=="") = "Custom";

blendPct = round(100*BlendV);
hasBlend = BlendV > tol;
SweepName = SweepBase;
SweepName(hasBlend) = SweepBase(hasBlend) + " (" + string(blendPct(hasBlend)) + "% blending)";

% -------- Build output table (Leak -> Diam) --------
heights = cellfun(@(x) size(x,1), {SeqMode, SeqName, SeqAbbr, P0, P1, P2, ...
    M2V, DiamV, W1col, W2col, W3col, BlendV, FreqV, Time, Voltage, SweepBase, SweepName});
assert(all(heights == heights(1)), 'Internal size mismatch before table creation.');

simdata = table(SeqMode, SeqName, SeqAbbr, P0, P1, P2, ...
    M2V, DiamV, W1col, W2col, W3col, BlendV, FreqV, Time, Voltage, ...
    SweepBase, SweepName, ...
    'VariableNames', {'SeqMode','SeqName','SeqAbbr','P0','P1','P2', ...
    'M2_Level','Diam','W1','W2','W3','Blending_Level','Frequency','Time','Voltage', ...
    'SweepBase','SweepName'});

% -------- Attach metadata (JSONs + flags) to table.UserData --------
ud = struct();

% synapse_params_by_mode.json
synjsonPath = fullfile(outdir, options.SynapseJSONFile);
if exist(synjsonPath,'file') == 2
    ud.SynapseParams = jsondecode(fileread(synjsonPath));
else
    ud.SynapseParams = [];
    if ~options.MissingOK
        warning('Synapse JSON not found: %s', synjsonPath);
    end
end

% biophysics.json
biojsonPath = fullfile(outdir, options.BiophysicsJSONFile);
if exist(biojsonPath,'file') == 2
    ud.Biophysics = jsondecode(fileread(biojsonPath));
else
    ud.Biophysics = [];
    if ~options.MissingOK
        warning('Biophysics JSON not found: %s', biojsonPath);
    end
end

% whether we used diam or legacy leak as the axis (stored in DiamV)
ud.UsedDiameterSweep = useDiam;

% weights levels (optional: load to attach)
wPath = fullfile(outdir, options.WeightsFile);
if exist(wPath,'file') == 2
    try
        ud.WeightsTable = readtable(wPath, 'FileType','text', 'Delimiter','\t', 'ReadVariableNames',true);
    catch
        ud.WeightsTable = [];
    end
end

simdata.Properties.UserData.Metadata = ud;

% -------- Simple feature extraction (unchanged) --------
simdata.Peaks = zeros(height(simdata),1);
simdata.PreSynapticRate = zeros(height(simdata),1);
simdata.PostSynapticRate = zeros(height(simdata),1);
simdata.CoV_ISI          = nan(height(simdata),1);
for ii = 1:height(simdata)
    v = simdata.Voltage{ii};
    t = simdata.Time{ii}; % ms
    [pks,locs] = findpeaks(v, 'MinPeakHeight', options.APThreshold);
    simdata.Peaks(ii) = numel(pks);
    simdata.PreSynapticRate(ii) = simdata.Frequency(ii)/3;
    simdata.PostSynapticRate(ii) = simdata.Peaks(ii)/((t(end)-t(1))/1000); % spikes/sec
    if numel(locs) >= 2
        isi = diff(t(locs) / 1000);
        mu  = mean(isi);
        sd  = std(isi, 0);
        simdata.CoV_ISI(ii) = (mu>0) * (sd/mu);
        if mu==0, simdata.CoV_ISI(ii) = NaN; end
    else
        simdata.CoV_ISI(ii) = NaN;
    end
end
end

function ab = infer_seq_abbr(name)
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
