function [fig_inf, fig_tau, TT] = plot_gate_curves(outdir)
% Plot gate curves saved by your NEURON script.
% Supports files:
%   gate_curves_m2_<M2>.tsv
%   gate_curves_diam_<DIAM>_m2_<M2>.tsv

if nargin < 1
    outdir = fullfile(pwd,"NEURON","MotorNeuron","out_m2qa");
end

files = [ ...
    dir(fullfile(outdir,'gate_curves_diam_*_m2_*.tsv')); ...
    dir(fullfile(outdir,'gate_curves_m2_*.tsv')) ...
];
assert(~isempty(files), 'No gate TSV files found in %s', outdir);

rx_new = '^gate_curves_diam_(?<diam>[\d.]+)_m2_(?<m2>[\d.]+)\.tsv$';
rx_old = '^gate_curves_m2_(?<m2>[\d.]+)\.tsv$';

C = struct('V',[],'minf',[],'hinf',[],'ninf',[],'taum',[],'tauh',[],'taun',[], ...
           'diam',NaN,'m2',NaN,'label','', 'file','');
for k = 1:numel(files)
    fn = files(k).name; fp = fullfile(outdir,fn);
    tok = regexp(fn,rx_new,'names');
    diam = NaN; m2 = NaN;
    if ~isempty(tok)
        diam = str2double(tok.diam);
        m2   = str2double(tok.m2);
    else
        tok = regexp(fn,rx_old,'names');
        if isempty(tok), warning('Skip unrecognized filename: %s', fn); continue; end
        m2   = str2double(tok.m2);
    end

    T = readtable(fp,'FileType','text','Delimiter','\t');
    % Normalize var names
    vn = lower(string(T.Properties.VariableNames));
    V  = T{:, find(vn=="v_mv",1)};
    mi = T{:, find(vn=="m_inf",1)};
    hi = T{:, find(vn=="h_inf",1)};
    ni = T{:, find(vn=="n_inf",1)};
    tm = T{:, find(vn=="tau_m_ms",1)};
    th = T{:, find(vn=="tau_h_ms",1)};
    tn = T{:, find(vn=="tau_n_ms",1)};

    % Optional: clamp crazy V (> 60 mV) for plotting focus
    keep = isfinite(V) & V>=-90 & V<=60;
    V=V(keep); mi=mi(keep); hi=hi(keep); ni=ni(keep); tm=tm(keep); th=th(keep); tn=tn(keep);

    C(end+1) = struct('V',V,'minf',mi,'hinf',hi,'ninf',ni, ...
                      'taum',tm,'tauh',th,'taun',tn, ...
                      'diam',diam,'m2',m2, ...
                      'label', label_of(diam,m2), 'file', fn); %#ok<AGROW>
end
C = C(2:end);  % drop empty first

% Concatenate to a table for downstream work
TT = table();
for k = 1:numel(C)
    n = numel(C(k).V);
    TT = [TT; table( ...
        C(k).V, C(k).minf, C(k).hinf, C(k).ninf, ...
        C(k).taum, C(k).tauh, C(k).taun, ...
        repmat(C(k).diam,n,1), repmat(C(k).m2,n,1), repmat(string(C(k).file),n,1), ...
        'VariableNames',{'V_mV','m_inf','h_inf','n_inf','Tau_m_ms','Tau_h_ms','Tau_n_ms','Diam_um','M2','File'})]; %#ok<AGROW>
end

% Unique condition labels
labels = unique(string(arrayfun(@(s) s.label, C, 'uni', false)));

% ----- Plot steady-state gates -----
fig_inf = figure('Color','w');
ax1 = axes(fig_inf); hold(ax1,'on'); grid(ax1,'on'); set(ax1,'FontName','Arial');
co = lines(numel(labels));
for i = 1:numel(labels)
    idx = find(strcmp(string({C.label}), labels(i)), 1, 'first');
    plot(ax1,C(idx).V, C(idx).minf, '-', 'Color',co(i,:), 'LineWidth',1.6, 'DisplayName', labels(i)+"  m∞");
    plot(ax1,C(idx).V, C(idx).hinf, '--', 'Color',co(i,:), 'LineWidth',1.2, 'HandleVisibility','off');
    plot(ax1,C(idx).V, C(idx).ninf, ':', 'Color',co(i,:), 'LineWidth',1.4, 'HandleVisibility','off');
end
xlabel(ax1,'V (mV)'); ylabel(ax1,'Steady-state (–)');
title(ax1,'m∞ (solid), h∞ (dashed), n∞ (dotted)');
legend(ax1,'Location','eastoutside'); xlim(ax1,[-90 60]); ylim(ax1,[0 1]);

% ----- Plot time constants (log-y) -----
fig_tau = figure('Color','w');
ax2 = axes(fig_tau); hold(ax2,'on'); grid(ax2,'on'); set(ax2,'YScale','log','FontName','Arial');
for i = 1:numel(labels)
    idx = find(strcmp(string({C.label}), labels(i)), 1, 'first');
    plot(ax2,C(idx).V, max(C(idx).taum,1e-6), '-',  'Color',co(i,:), 'LineWidth',1.6, 'DisplayName', labels(i)+"  \tau_m");
    plot(ax2,C(idx).V, max(C(idx).tauh,1e-6), '--', 'Color',co(i,:), 'LineWidth',1.2, 'HandleVisibility','off');
    plot(ax2,C(idx).V, max(C(idx).taun,1e-6), ':',  'Color',co(i,:), 'LineWidth',1.4, 'HandleVisibility','off');
end
xlabel(ax2,'V (mV)'); ylabel(ax2,'Time constant (ms, log)');
title(ax2,'\tau_m (solid), \tau_h (dashed), \tau_n (dotted)');
xlim(ax2,[-90 60]);

end

function s = label_of(diam,m2)
if ~isnan(diam)
    s = sprintf('diam=%.0fµm, M2=%.2f', diam, m2);
else
    s = sprintf('M2=%.2f', m2);
end
end
