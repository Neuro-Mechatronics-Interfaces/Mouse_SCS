function [fig, T] = plot_fi_curves(outdir)
%PLOT_FI_CURVES Plot f–I curves saved by the NEURON sweep. [fig,T] = plot_fI_curves(outdir)
%
% Supports files named like:
%   - fI_diam_<DIAM>_m2_<M2>_tauca_<TAU>.tsv
%
% Returns:
%   fig : figure handle
%   T   : concatenated table with I_nA, Rate_Hz, M2, Diam_um, TauCa_ms, File

if nargin < 1
    outdir = fullfile(pwd, "NEURON","MotorNeuron","out_pbr");
end

files = [ ...
    dir(fullfile(outdir, 'fI_diam_*_m2_*_tauca_*.tsv'));
    ];

if isempty(files)
    error('No f–I TSV files found in: %s', outdir);
end

% Regex (case-insensitive) for new names; tauca optional
rx = '^[fF][iI]_diam_(?<diam>[0-9]+(?:\.[0-9]+)?)_m2_(?<m2>[0-9]+(?:\.[0-9]+)?)_tauca_(?<tauca>[0-9]+(?:\.[0-9]+)?)_picton_(?<picton>[0-9]+(?:\.[0-9]+)?)_kdrop_(?<kdrop>[0-9]+(?:\.[0-9]+)?)?\.tsv$';
rx_old = '^[fF][iI]_diam_(?<diam>[0-9]+(?:\.[0-9]+)?)_m2_(?<m2>[0-9]+(?:\.[0-9]+)?)_tauca_(?<tauca>[0-9]+(?:\.[0-9]+)?)_picton_(?<picton>[0-9]+(?:\.[0-9]+)?)?\.tsv$';

T = table();
for k = 1:numel(files)
    fname = files(k).name;
    fpath = fullfile(outdir, fname);

    % Parse tokens
    tok = regexp(fname, rx, 'names');
    if isempty(tok)
        tok = regexp(fname, rx_old, 'names');
    end
    Diam_um  = str2double(tok.diam);
    M2       = str2double(tok.m2);
    PIC_t_ON_ms = str2double(tok.picton);
    TauCa_ms = str2double(tok.tauca);
    kdrop = 0;
    if isfield(tok,'kdrop')
        kdrop = str2double(tok.kdrop);
    end
    % Read table (writer uses exact headers I_nA, Rate_Hz)
    t = readtable(fpath, 'FileType','text', 'Delimiter','\t');
    % Be tolerant to header case/variants
    vn = lower(string(t.Properties.VariableNames));
    i_col = find(vn=="i_na", 1);
    r_col = find(vn=="rate_hz" | vn=="rate" | vn=="hz", 1);
    if isempty(i_col), i_col = find(strcmp(t.Properties.VariableNames,'I_nA'),1); end
    if isempty(r_col), r_col = find(strcmp(t.Properties.VariableNames,'Rate_Hz'),1); end
    if isempty(i_col) || isempty(r_col)
        error('File %s: could not find I_nA / Rate_Hz columns.', fname);
    end

    ti = table(t{:,i_col}, t{:,r_col}, ...
        'VariableNames', {'I_nA','Rate_Hz'});
    good = isfinite(ti.I_nA) & isfinite(ti.Rate_Hz);
    ti = sortrows(ti(good,:), 'I_nA');

    ti.M2        = repmat(M2, height(ti), 1);
    ti.Diam_um   = repmat(Diam_um, height(ti), 1);
    ti.TauCa_ms  = repmat(TauCa_ms, height(ti), 1);
    ti.PIC_t_ON_ms = repmat(PIC_t_ON_ms, height(ti), 1);
    ti.KDrop     = repmat(kdrop, height(ti), 1);
    ti.File      = repmat(string(fname), height(ti), 1);

    T = [T; ti]; %#ok<AGROW>
end

if isempty(T)
    error('No valid data parsed from files in %s', outdir);
end

% ---- Plot: one tile per (Diam, TauCa) combo ----
pairs = unique([T.Diam_um, T.TauCa_ms], 'rows', 'stable'); % includes NaNs
nP = size(pairs,1);
nRows = ceil(sqrt(nP));
nCols = ceil(nP/nRows);
panelMaxRows = nan(nP, 1);     % store (row index in T) for max-rate per panel

fig = gobjects(2,1);
fig(1) = figure('Color','w','WindowState','maximized');
tl = tiledlayout(fig(1), nRows, nCols, 'Padding','compact','TileSpacing','compact');
title(tl, 'f–I curves by Diameter × \tau_{Ca}', 'FontName','Arial');

% Consistent colors for M2 across tiles
m2_all = unique(T.M2);
pic_all = unique(T.PIC_t_ON_ms);
kdrop_all = unique(T.KDrop);

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

tileTitles = strings(nP,1);                % store for reuse in traces figure
i_nA_best = nan(nP,1);
m2_best = nan(nP,1);
tauca_best = nan(nP,1);
diam_best = nan(nP,1);
pic_t_on_best = nan(nP,1);
kdrop_best = nan(nP,1);
axs = gobjects(nP,1);
for p = 1:nP
    d = pairs(p,1);  tau = pairs(p,2);
    maskD = (isnan(d)  & isnan(T.Diam_um)) | (~isnan(d)  & T.Diam_um==d);
    maskT = (isnan(tau)& isnan(T.TauCa_ms))| (~isnan(tau)& T.TauCa_ms==tau);
    Tp = T(maskD & maskT, :);
    if isempty(Tp), continue; end

    ax = nexttile(tl); axs(p) = ax;
    hold(ax,'on'); grid(ax,'on'); set(ax,'FontName','Arial');
    c = 0;
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
                c = c + 1;
                plot(ax, Ti.I_nA, Ti.Rate_Hz, tern(kdropval==0,':','-'), ...
                    'DisplayName', sprintf('M2 = %.2f | %s (kdrop=%.1f)', m2val, pic_lab, kdropval), ...
                    'LineWidth', 1.5, ... 'MarkerSize', 5, ...
                    'Color', cols{k,i,j});
            end
        end
    end

    xlabel(ax,'Injected current (nA)','FontName','Arial');
    ylabel(ax,'Firing rate (Hz)','FontName','Arial');

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
        legend(ax,'Location','southeast','FontName','Arial','Box','off', ...
            'FontSize',6,'NumColumns',1);
    end
    % pick the single point with maximum rate in this panel
    [~, localIdx] = max(Tp.Rate_Hz);
    pic_t_on_best(p) = Tp.PIC_t_ON_ms(localIdx);
    pic_lab = tern(pic_t_on_best(p) < 1000,sprintf("PIC_{ON} = %d ms",pic_t_on_best(p)),"PIC_{OFF}");
    m2_best(p) = Tp.M2(localIdx);
    m2_lab = sprintf("M2 = %.2f", m2_best(p));
    kdrop_best(p) = Tp.KDrop(localIdx);
    tileTitles(p) = sprintf("%s [%s | %s (kdrop=%.1f)]", string(ttl), m2_lab, pic_lab, kdrop_best(p));
    i_nA_best(p) = Tp.I_nA(localIdx);
    diam_best(p) = Tp.Diam_um(localIdx);
    tauca_best(p) = Tp.TauCa_ms(localIdx);
    panelMaxRows(p) = find(maskD & maskT, 1, 'first');
end

% Link axes for fair visual comparison
try
    linkaxes(axs(isgraphics(axs)),'xy');
catch
end

fig(2) = figure('Color','w', 'WindowState','maximized');
tl2 = tiledlayout(fig(2), nRows, nCols, 'Padding','compact','TileSpacing','compact');
title(tl2, 'Time traces at panel''s max-rate point (V: black, [Ca^{2+}]: blue)', 'FontName','Arial');

for p = 1:nP
    if ismissing(panelMaxRows(p)), nexttile(tl2); axis off; continue; end
    ax2 = nexttile(tl2); set(ax2,'FontName','Arial'); grid(ax2,'on'); hold(ax2,'on');

    % Build a robust search pattern for the trace file
    diam_s = num2str_ifint(diam_best(p));
    m2_s   = num2str_ifint(m2_best(p));
    I_s    = num2str_ifint(i_nA_best(p));
    tau_s = num2str_ifint(tauca_best(p));
    pic_t_on_s = num2str_ifint(pic_t_on_best(p));
    kdrop_s = num2str_ifint(kdrop_best(p));
    pat_new = sprintf('trace_diam_%s_m2_%s_tauca_%s_picton_%s_kdrop_%s_I_%s.tsv', diam_s, m2_s, tau_s, pic_t_on_s, kdrop_s, I_s);
    if kdrop_best(p) == 0
        pat_old = sprintf('trace_diam_%s_m2_%s_tauca_%s_picton_%s_I_%s.tsv', diam_s, m2_s, tau_s, pic_t_on_s, I_s);
        if exist(pat_new,'file')~=0
            pat_glob     = pat_new; % exact first
        else
            pat_glob = pat_old;
        end
    else
        pat_glob = pat_new;
    end
    tr_files = dir(fullfile(outdir, pat_glob));

    if isempty(tr_files)
        % nothing found; annotate tile
        title(ax2, tileTitles(p) + " — (no trace found)");
        xlabel(ax2,'t (ms)'); ylabel(ax2,'V (mV)');
        continue;
    end

    tr = readtable(fullfile(outdir, tr_files(1).name), 'FileType','text', 'Delimiter','\t');

    % tolerant column detection for time, V, and Ca
    tcol = pick_var(tr, ["t_ms","t","time_ms","time"]);
    vcol = pick_var(tr, ["Vsom_mV","Vsoma_mV","V_mV","v_mV","Vm_mV","Vm"]);
    ccol = pick_var(tr, ["cai_mM","cai","Ca_mM","Ca","[Ca]_mM"]);

    if isempty(tcol) || isempty(vcol) || isempty(ccol)
        title(ax2, tileTitles(p) + " — (trace columns missing)");
        xlabel(ax2,'t (ms)'); ylabel(ax2,'V (mV)');
        continue;
    end

    t_ms   = tr{:,tcol};
    v_mV   = tr{:,vcol};
    cai_mM = tr{:,ccol};

    % Left axis: V (black), Right axis: Ca (blue)
    yyaxis(ax2,'left');  
    set(ax2,'YColor','k'); 
    plot(ax2, t_ms, v_mV, 'k-', 'LineWidth', 1.2);
    ylabel(ax2,'V (mV)', 'FontName','Arial', 'Color', 'k');
    yyaxis(ax2,'right'); 
    set(ax2, 'YColor', 'b'); 
    plot(ax2, t_ms, cai_mM, 'b-', 'LineWidth', 1.2);
    ylabel(ax2,'[Ca^{2+}] (mM)', 'FontName','Arial', 'Color', 'b');
    xlabel(ax2,'t (ms)', 'FontName','Arial');
    title(ax2, tileTitles(p), 'FontName','Arial');
end


figure(fig(1));
end

% --------- helpers ---------
function s = num2str_ifint(x)
% Use integer formatting if x is effectively an integer, otherwise %g
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
% Return first matching column index from a list of candidate names (case-insensitive)
vn = lower(string(tbl.Properties.VariableNames));
c  = lower(string(candidates));
idx = [];
for k = 1:numel(c)
    j = find(vn == c(k), 1);
    if ~isempty(j), idx = j; return; end
end
end

function c = tern(cond,a,b)
    if (cond)
        c = a;
    else
        c = b;
    end
end