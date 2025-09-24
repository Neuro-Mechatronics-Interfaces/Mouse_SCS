function [fig, T] = plot_fi_curves(outdir)
%PLOT_FI_CURVES Plot f–I curves + CoV_ISI and matched time traces.
%   [fig,T] = plot_fI_curves(outdir)
%
% Supports f–I files named like:
%   - fI_diam_<DIAM>_m2_<M2>_tauca_<TAU>_picton_<P>_kdrop_<K>.tsv
%   - fI_diam_<DIAM>_m2_<M2>_tauca_<TAU>_picton_<P>.tsv   (legacy without kdrop)
%
% Also searches trace files named like:
%   - trace_diam_<DIAM>_m2_<M2>_tauca_<TAU>_picton_<P>_kdrop_<K>_I_<I>.tsv
%   - trace_diam_<DIAM>_m2_<M2>_tauca_<TAU>_picton_<P>_I_<I>.tsv
%
% Overlays CoV_ISI (computed from traces) as a scatter vs current on the
% right y-axis for each f–I tile. The trace tile title appends CoV_ISI at
% the max-rate current if available.

if nargin < 1
    outdir = fullfile(pwd, "NEURON","MotorNeuron","out_pbr");
end

files = dir(fullfile(outdir, 'fI_diam_*_m2_*_tauca_*_picton_*.tsv'));
if isempty(files)
    error('No f–I TSV files found in: %s', outdir);
end

% Regex (case-insensitive): tauca & picton required, kdrop optional
rx     = '^[fF][iI]_diam_(?<diam>[0-9]+(?:\.[0-9]+)?)_m2_(?<m2>[0-9]+(?:\.[0-9]+)?)_tauca_(?<tauca>[0-9]+(?:\.[0-9]+)?)_picton_(?<picton>[0-9]+(?:\.[0-9]+)?)_kdrop_(?<kdrop>[0-9]+(?:\.[0-9]+)?)?\.tsv$';
rx_old = '^[fF][iI]_diam_(?<diam>[0-9]+(?:\.[0-9]+)?)_m2_(?<m2>[0-9]+(?:\.[0-9]+)?)_tauca_(?<tauca>[0-9]+(?:\.[0-9]+)?)_picton_(?<picton>[0-9]+(?:\.[0-9]+)?)?\.tsv$';

T = table();
for k = 1:numel(files)
    fname = files(k).name;
    fpath = fullfile(outdir, fname);

    tok = regexp(fname, rx, 'names');
    if isempty(tok)
        tok = regexp(fname, rx_old, 'names');
    end
    if isempty(tok)
        warning('Skipping unparseable f–I file name: %s', fname);
        continue;
    end
    Diam_um      = str2double(tok.diam);
    M2           = str2double(tok.m2);
    PIC_t_ON_ms  = str2double(tok.picton);
    TauCa_ms     = str2double(tok.tauca);
    kdrop        = 0;
    if isfield(tok,'kdrop') && ~isempty(tok.kdrop)
        kdrop = str2double(tok.kdrop);
    end

    % Read table (tolerant to header variants)
    t  = readtable(fpath, 'FileType','text', 'Delimiter','\t');
    vn = lower(string(t.Properties.VariableNames));
    i_col = find(vn=="i_na", 1);
    r_col = find(vn=="rate_hz" | vn=="rate" | vn=="hz", 1);
    if isempty(i_col), i_col = find(strcmp(t.Properties.VariableNames,'I_nA'),1); end
    if isempty(r_col), r_col = find(strcmp(t.Properties.VariableNames,'Rate_Hz'),1); end
    if isempty(i_col) || isempty(r_col)
        error('File %s: could not find I_nA / Rate_Hz columns.', fname);
    end

    ti = table(t{:,i_col}, t{:,r_col}, 'VariableNames', {'I_nA','Rate_Hz'});
    good = isfinite(ti.I_nA) & isfinite(ti.Rate_Hz);
    ti = sortrows(ti(good,:), 'I_nA');

    ti.M2           = repmat(M2, height(ti), 1);
    ti.Diam_um      = repmat(Diam_um, height(ti), 1);
    ti.TauCa_ms     = repmat(TauCa_ms, height(ti), 1);
    ti.PIC_t_ON_ms  = repmat(PIC_t_ON_ms, height(ti), 1);
    ti.KDrop        = repmat(kdrop, height(ti), 1);
    ti.File         = repmat(string(fname), height(ti), 1);

    % Placeholder for CoV_ISI per row; fill below when traces are found
    ti.CoV_ISI      = nan(height(ti),1);

    T = [T; ti]; %#ok<AGROW>
end

if isempty(T)
    error('No valid data parsed from files in %s', outdir);
end

% Unique panels by (Diam, TauCa)
pairs = unique([T.Diam_um, T.TauCa_ms], 'rows', 'stable');
nP    = size(pairs,1);
nRows = ceil(sqrt(nP));
nCols = ceil(nP/nRows);

fig = gobjects(2,1);

% --- Figure 1: f–I curves with CoV_ISI scatter (right y-axis)
fig(1) = figure('Color','w','WindowState','maximized');
tl = tiledlayout(fig(1), nRows, nCols, 'Padding','compact','TileSpacing','compact');
title(tl, 'f–I curves by Diameter × \tau_{Ca} (right axis: CoV_{ISI})', 'FontName','Arial');

m2_all   = unique(T.M2);
pic_all  = unique(T.PIC_t_ON_ms);
kdrop_all= unique(T.KDrop);

palette = validatecolor(["#E0E0E0"; "#EF3A47"; "#FDB515"],'multiple');
cols = cell(numel(m2_all), numel(pic_all), numel(kdrop_all));
for i = 1:numel(pic_all)
    cdata = cm.umap(palette(i,:),numel(m2_all)*numel(kdrop_all)+5);
    cdata = cdata(2:(end-3),:);
    j = 0;
    for m = 1:numel(m2_all)
        for k = 1:numel(kdrop_all)
            j = j + 1;
            cols{i,m,k} = cdata(j,:);
        end
    end
end

tileTitles   = strings(nP,1);
axs          = gobjects(nP,1);
panelMaxRows = nan(nP,1);

% We’ll also keep the best params/I for retrieving the matching trace
i_nA_best   = nan(nP,1);
m2_best     = nan(nP,1);
tauca_best  = nan(nP,1);
diam_best   = nan(nP,1);
pic_best    = nan(nP,1);
kdrop_best  = nan(nP,1);
cov_best    = nan(nP,1);   % CoV at the max-rate point (for trace title)

for p = 1:nP
    d = pairs(p,1);  tau = pairs(p,2);
    maskD = (isnan(d)  & isnan(T.Diam_um)) | (~isnan(d)  & T.Diam_um==d);
    maskT = (isnan(tau)& isnan(T.TauCa_ms))| (~isnan(tau)& T.TauCa_ms==tau);
    Tp = T(maskD & maskT, :);
    if isempty(Tp), nexttile(tl); axis off; continue; end

    % Compute/attach CoV_ISI per row by scanning for corresponding trace files
    % (do it once per tile to avoid repeated search)
    for r = 1:height(Tp)
        if isnan(Tp.CoV_ISI(r))
            tr_path = find_trace(outdir, Tp.Diam_um(r), Tp.M2(r), Tp.TauCa_ms(r), Tp.PIC_t_ON_ms(r), Tp.KDrop(r), Tp.I_nA(r));
            if ~isempty(tr_path)
                trTbl = readtable(tr_path, 'FileType','text', 'Delimiter','\t');
                cov = cov_from_trace(trTbl);
                Tp.CoV_ISI(r) = cov;
                % write back into T
                rowIdx = find(T.Diam_um==Tp.Diam_um(r) & T.M2==Tp.M2(r) & ...
                              T.TauCa_ms==Tp.TauCa_ms(r) & T.PIC_t_ON_ms==Tp.PIC_t_ON_ms(r) & ...
                              T.KDrop==Tp.KDrop(r) & T.I_nA==Tp.I_nA(r), 1, 'first');
                if ~isempty(rowIdx), T.CoV_ISI(rowIdx) = cov; end
            end
        end
    end

    ax = nexttile(tl); axs(p) = ax;
    hold(ax,'on'); grid(ax,'on'); set(ax,'FontName','Arial');

    % Draw f–I curves (left y-axis)
    yyaxis(ax,'left');
    for i = 1:numel(m2_all)
        m2val = m2_all(i);
        for k = 1:numel(pic_all)
            picval = pic_all(k);
            pic_lab = tern(picval < 1000,sprintf("PIC_{ON} = %d ms",picval),"PIC_{OFF}");
            for j = 1:numel(kdrop_all)
                kdropval = kdrop_all(j);
                Ti = Tp(Tp.M2==m2val & Tp.PIC_t_ON_ms==picval & Tp.KDrop==kdropval, :);
                if isempty(Ti), continue; end
                Ti = sortrows(Ti, 'I_nA');
                plot(ax, Ti.I_nA, Ti.Rate_Hz, tern(kdropval==0,':','-'), ...
                    'DisplayName', sprintf('M2 = %.2f | %s (kdrop=%.1f)', m2val, pic_lab, kdropval), ...
                    'LineWidth', 1.5, 'Color', cols{k,i,j});
            end
        end
    end
    ylabel(ax,'Firing rate (Hz)','FontName','Arial');

    % Overlay CoV_ISI scatter (right y-axis)
    yyaxis(ax,'right');
    set(ax, 'YColor',[0.1 0.1 0.1]);
    scatter(ax, Tp.I_nA, Tp.CoV_ISI, 22, 'o', 'MarkerEdgeColor',[0.1 0.1 0.1], ...
        'MarkerFaceColor','none', 'DisplayName','CoV_{ISI}');
    ylabel(ax,'CoV_{ISI}','FontName','Arial');

    xlabel(ax,'Injected current (nA)','FontName','Arial');

    % Title/legend
    if isnan(d) && isnan(tau)
        ttl = 'Diameter: (unknown), \tau_{Ca}: (unknown)';
    elseif isnan(d)
        ttl = sprintf('Diameter: (unknown), \\tau_{Ca}: %.0f ms', tau);
    elseif isnan(tau)
        ttl = sprintf('Diameter: %.0f \\mum, \\tau_{Ca}: (unknown)', d);
    else
        ttl = sprintf('Diameter: %.0f \\mum, \\tau_{Ca}: %.0f ms', d, tau);
    end
    title(ax, ttl, 'FontName','Arial');
    if p == 1
        lgd = legend(ax,'Location','southeast','FontName','Arial','Box','off', ...
            'FontSize',6,'NumColumns',1);
        lgd.AutoUpdate = 'off';
    end
    tileTitles(p) = string(ttl);

    % pick the single point with maximum rate in this panel (and remember CoV)
    [~, localIdx] = max(Tp.Rate_Hz);
    i_nA_best(p)  = Tp.I_nA(localIdx);
    m2_best(p)    = Tp.M2(localIdx);
    tauca_best(p) = Tp.TauCa_ms(localIdx);
    diam_best(p)  = Tp.Diam_um(localIdx);
    pic_best(p)   = Tp.PIC_t_ON_ms(localIdx);
    kdrop_best(p) = Tp.KDrop(localIdx);
    cov_best(p)   = Tp.CoV_ISI(localIdx);
    panelMaxRows(p)= find(maskD & maskT, 1, 'first'); %#ok<NASGU>
end

% Try to keep axes comparable
try, linkaxes(axs(isgraphics(axs)),'x'); catch, end

% --- Figure 2: time traces at the max-rate current (title shows CoV_ISI)
fig(2) = figure('Color','w','WindowState','maximized');
tl2 = tiledlayout(fig(2), nRows, nCols, 'Padding','compact','TileSpacing','compact');
title(tl2, 'Time traces at panel''s max-rate point (V: black, [Ca^{2+}]: blue)', 'FontName','Arial');

for p = 1:nP
    ax2 = nexttile(tl2); set(ax2,'FontName','Arial'); grid(ax2,'on'); hold(ax2,'on');

    tr_path = find_trace(outdir, diam_best(p), m2_best(p), tauca_best(p), pic_best(p), kdrop_best(p), i_nA_best(p));
    if isempty(tr_path)
        title(ax2, sprintf('%s — (no trace found)', tileTitles(p)));
        xlabel(ax2,'t (ms)'); ylabel(ax2,'V (mV)');
        continue;
    end

    tr = readtable(tr_path, 'FileType','text', 'Delimiter','\t');

    tcol = pick_var(tr, ["t_ms","t","time_ms","time"]);
    vcol = pick_var(tr, ["Vsom_mV","Vsoma_mV","V_mV","v_mV","Vm_mV","Vm"]);
    ccol = pick_var(tr, ["cai_mM","cai","Ca_mM","Ca","[Ca]_mM"]);
    if isempty(tcol) || isempty(vcol) || isempty(ccol)
        title(ax2, sprintf('%s — (trace columns missing)', tileTitles(p)));
        xlabel(ax2,'t (ms)'); ylabel(ax2,'V (mV)');
        continue;
    end

    t_ms   = tr{:,tcol};
    v_mV   = tr{:,vcol};
    cai_mM = tr{:,ccol};

    % Left axis: V (black); Right axis: Ca (blue)
    yyaxis(ax2,'left');  set(ax2,'YColor','k');
    plot(ax2, t_ms, v_mV, 'k-', 'LineWidth', 1.2);
    ylabel(ax2,'V (mV)', 'FontName','Arial');

    yyaxis(ax2,'right'); set(ax2,'YColor','b');
    plot(ax2, t_ms, cai_mM, 'b-', 'LineWidth', 1.2);
    ylabel(ax2,'[Ca^{2+}] (mM)', 'FontName','Arial');

    xlabel(ax2,'t (ms)', 'FontName','Arial');

    % Append CoV_ISI (if available) to title for this max-rate point
    if isfinite(cov_best(p))
        title(ax2, sprintf('%s  |  CoV_{ISI}=%.3f', tileTitles(p), cov_best(p)), 'FontName','Arial');
    else
        % Try compute directly from this trace as a fallback
        cov_here = cov_from_trace(tr);
        if isfinite(cov_here)
            title(ax2, sprintf('%s  |  CoV_{ISI}=%.3f', tileTitles(p), cov_here), 'FontName','Arial');
        else
            title(ax2, tileTitles(p), 'FontName','Arial');
        end
    end
end

figure(fig(1)); % bring f–I figure to front
end

% --------- helpers ---------
function s = num2str_ifint(x)
if ~isfinite(x)
    s = "NaN";
else
    if abs(x - round(x)) < 1e-9
        s = string(sprintf('%.0f', x));
    else
        s = string(sprintf('%g', x));
    end
end
end

function idx = pick_var(tbl, candidates)
vn = lower(string(tbl.Properties.VariableNames));
c  = lower(string(candidates));
idx = [];
for k = 1:numel(c)
    j = find(vn == c(k), 1);
    if ~isempty(j), idx = j; return; end
end
end

function c = tern(cond,a,b)
if cond, c = a; else, c = b; end
end

function path = find_trace(outdir, diam, m2, tauca, picton, kdrop, I_nA)
% Try exact, then legacy name (without kdrop), then a tolerant numeric print
diam_s = num2str_ifint(diam);
m2_s   = num2str_ifint(m2);
tau_s  = num2str_ifint(tauca);
pic_s  = num2str_ifint(picton);
k_s    = num2str_ifint(kdrop);
I_s    = num2str_ifint(I_nA);

cands = {};
% new pattern
cands{end+1} = fullfile(outdir, sprintf('trace_diam_%s_m2_%s_tauca_%s_picton_%s_kdrop_%s_I_%s.tsv', diam_s, m2_s, tau_s, pic_s, k_s, I_s));
% legacy (no kdrop)
cands{end+1} = fullfile(outdir, sprintf('trace_diam_%s_m2_%s_tauca_%s_picton_%s_I_%s.tsv', diam_s, m2_s, tau_s, pic_s, I_s));
% tolerant I with 2 decimals
cands{end+1} = fullfile(outdir, sprintf('trace_diam_%s_m2_%s_tauca_%s_picton_%s_kdrop_%s_I_%.2f.tsv', diam_s, m2_s, tau_s, pic_s, k_s, round(I_nA,2)));

path = '';
for i = 1:numel(cands)
    if exist(cands{i}, 'file') == 2
        path = cands{i};
        return;
    end
end
end

function cov_val = cov_from_trace(tr)
% Compute CoV_ISI from a trace table:
% 1) Prefer an explicit spike time column if present.
% 2) Else detect upward crossings of V at 0 mV with minimal ISI of 1 ms.
cov_val = NaN;

% Explicit spike time column?
spk_col = pick_var(tr, ["spike_ms","spikes_ms","spike_t_ms","spike","spikes"]);
if ~isempty(spk_col)
    spk = tr{:,spk_col};
    spk = spk(isfinite(spk));
    spk = spk(:);
    spk = unique(spk); % just in case
    if numel(spk) >= 3
        isi = diff(spk);
        mu  = mean(isi);
        sd  = std(isi,0,1);
        if mu > 0, cov_val = sd/mu; end
    end
    return;
end

% Otherwise derive from voltage
tcol = pick_var(tr, ["t_ms","t","time_ms","time"]);
vcol = pick_var(tr, ["Vsom_mV","Vsoma_mV","V_mV","v_mV","Vm_mV","Vm"]);
if isempty(tcol) || isempty(vcol), return; end

t = tr{:,tcol};
v = tr{:,vcol};

if ~isvector(t) || ~isvector(v) || numel(t) ~= numel(v) || numel(t) < 5
    return;
end
t = t(:); v = v(:);

% Simple spike detection: upward crossings of 0 mV with derivative > 0
dv = [0; diff(v)];
cross = v(1:end-1) < 0 & v(2:end) >= 0 & dv(2:end) > 0;
spk_ts = t(find(cross)+1);

% Enforce minimum ISI of 1 ms to avoid double counts on afterpotentials
if numel(spk_ts) >= 2
    dt = diff(spk_ts);
    keep = [true; dt >= 1.0];
    spk_ts = spk_ts(keep);
end

if numel(spk_ts) >= 3
    isi = diff(spk_ts);
    mu  = mean(isi);
    sd  = std(isi,0,1);
    if mu > 0, cov_val = sd/mu; end
end
end
