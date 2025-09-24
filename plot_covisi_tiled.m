function fig = plot_covisi_tiled(T, opts)
% PLOT_COVISI_TILED  I_nA vs CoV_ISI, tiled by Diam_um × TauCa_ms.
% Style mapping:
%   Color   -> M2
%   Line    -> PIC_t_ON_ms
%   Marker  -> KDrop
%
% Usage:
%   fig = plot_covisi_tiled(T)
%   fig = plot_covisi_tiled(T, struct('Colors',lines(6),'Markers',{'o','s','^','d','x','+'}))

arguments
    T table
    opts.Colors double = lines(8)             % rows = colors
    opts.LineStyles cell  = {'-','--',':','-.'}
    opts.Markers   cell  = {'o','s','^','d','x','+'}
    opts.LineWidth (1,1) double = 1.5
end

% Ensure needed vars exist
needed = ["Diam_um","TauCa_ms","M2","PIC_t_ON_ms","KDrop","I_nA","CoV_ISI"];
missing = setdiff(needed, string(T.Properties.VariableNames));
if ~isempty(missing)
    error('Table is missing variables: %s', strjoin(missing,", "));
end

% Unique values for tiling axes
uDiam = unique(T.Diam_um(:));
uTau  = unique(T.TauCa_ms(:));

% Unique style categories (stable order for consistency)
uM2   = unique(T.M2(:),'stable');
uPIC  = unique(T.PIC_t_ON_ms(:),'stable');
uDrop = unique(T.KDrop(:),'stable');

% Mapping helpers
cmap = @(val) opts.Colors( 1 + mod(find(uM2==val,1)-1, size(opts.Colors,1)) , :);
lmap = @(val) opts.LineStyles{ 1 + mod(find(uPIC==val,1)-1, numel(opts.LineStyles)) };
mmap = @(val) opts.Markers{    1 + mod(find(uDrop==val,1)-1, numel(opts.Markers))   };

% Figure & layout
fig = figure('Color','w','Units','inches','Position',[1 1 12 7], ...
    'Name','CoV_{ISI} vs I (tiled by Diameter × TauCa)');
L = tiledlayout(numel(uDiam), numel(uTau), 'TileSpacing','compact', 'Padding','compact');

% Actual tiles
tileIdx = 0;
axAll = gobjects(0);
for iD = 1:numel(uDiam)
  for iT = 1:numel(uTau)
    tileIdx = tileIdx + 1;
    ax = nexttile(L, tileIdx);
    hold(ax,'on'); ax.FontName = 'Arial';
    maskTile = T.Diam_um==uDiam(iD) & T.TauCa_ms==uTau(iT);
    S = T(maskTile,:);
    % Group by the three style variables
    if ~isempty(S)
        [G,~,gid] = unique(S(:,["M2","PIC_t_ON_ms","KDrop"]),'rows','stable');
        for g = 1:max(gid)
            R = S(gid==g,:);
            % sort by I for a sensible line
            [x,ord] = sort(R.I_nA);
            y = R.CoV_ISI(ord) * 100;
            c = cmap(G.M2(g));
            ls = lmap(G.PIC_t_ON_ms(g));
            mk = mmap(G.KDrop(g));
            plot(ax, x, y, 'Color', c, 'LineStyle', ls, 'Marker', mk, ...
                'LineWidth', opts.LineWidth, 'MarkerSize', 6, ...
                'DisplayName',sprintf("M2=%g | t_{PIC}=%g ms | KDrop=%g", G.M2(g), G.PIC_t_ON_ms(g), G.KDrop(g)));
        end
    end
    xlabel(ax, 'I (nA)','FontName','Arial','FontSize',9);
    ylabel(ax, 'CoV_{ISI} (%)','FontName','Arial','FontSize',9);
    ylim(ax,[0 100]); 
    title(ax, sprintf('Diam %g µm | TauCa %g ms', uDiam(iD), uTau(iT)), 'FontSize',10);
    grid(ax,'on');
    if (tileIdx == 1) 
        legend(ax,'Location','southeast'); 
    end
    axAll(end+1) = ax; %#ok<AGROW>
  end
end

% Big labels
xlabel(L, sprintf('TauCa (ms): %s', strjoin(string(uTau.')," | ")), 'FontWeight','bold');
ylabel(L, sprintf('Diameter (µm): %s', strjoin(string(flipud(uDiam).')," | ")), 'FontWeight','bold');

% Link axes for comparability
linkaxes(axAll,'xy');
end
