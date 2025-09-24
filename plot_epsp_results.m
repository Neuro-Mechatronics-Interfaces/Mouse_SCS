function fig = plot_epsp_results(R, opts)
% PLOT_EPSP_RESULTS  Plot firing rate vs DC, color-keyed by rate_Hz.
% If table has CoV_ISI, also plot CoV on a right Y-axis (same colors).
%
% Inputs
%   R : table with columns:
%       required: rate_Hz, DC_nA, firing_rate_Hz
%       optional: weight_uS, CoV_ISI
%   opts.LineWidth  (default 1.5)
%   opts.MarkerFR   (default 'o')   % marker for firing-rate lines
%   opts.LineStyleCoV (default '--')% style for CoV lines
%   opts.Colormap   (default @lines)
%   opts.Title      (default 'EPSP Poisson rate sweep')
%   opts.ShowLegend (default true)
%
% Output
%   fig : figure handle

if nargin < 2, opts = struct(); end
if ~isfield(opts,'LineWidth'),     opts.LineWidth = 1.5; end
if ~isfield(opts,'MarkerFR'),      opts.MarkerFR = 'o';  end
if ~isfield(opts,'LineStyleCoV'),  opts.LineStyleCoV = '--'; end
if ~isfield(opts,'Colormap'),      opts.Colormap = @lines; end
if ~isfield(opts,'Title'),         opts.Title = 'EPSP Poisson rate sweep'; end
if ~isfield(opts,'ShowLegend'),    opts.ShowLegend = true; end

% --- required columns
req = {'rate_Hz','DC_nA','firing_rate_Hz'};
assert(all(ismember(req, R.Properties.VariableNames)), ...
  'R must have variables: %s', strjoin(req, ', '));

hasWeight = ismember('weight_uS', R.Properties.VariableNames);
hasCoV    = ismember('CoV_ISI',   R.Properties.VariableNames);

% unique weights → subplots
if hasWeight
    uW = unique(R.weight_uS);
else
    uW = 0;
end
nW = numel(uW);

% color per rate
uRate = unique(R.rate_Hz);
uRate = sort(uRate(:));
C = opts.Colormap(max(numel(uRate),3));
C = C(1:numel(uRate),:);

fig = figure('Name','EPSP sweep','Color','w','Units','inches','Position',[2 2 9 4+2*(nW>1)]);
t = tiledlayout(fig, nW, tern(hasCoV,2,1), 'TileSpacing','compact','Padding','compact');
title(t, opts.Title, 'FontWeight','bold');

for iW = 1:nW
    if hasWeight
        Ri = R(R.weight_uS == uW(iW), :);
    else
        Ri = R;
    end

    ax = nexttile(t); 
    hold(ax,'on'); box(ax,'on'); grid(ax,'on');
    ax.YColor = [0 0 0];
    legFR = gobjects(0,1);
    if hasCoV
        axC = nexttile(t); 
        hold(axC,'on'); box(axC,'on'); grid(axC,'on');
        axC.YAxisLocation = 'right'; 
        axC.YColor = [0 0 0];
    end

    for k = 1:numel(uRate)
        rk = uRate(k);
        rows = Ri.rate_Hz == rk;
        if ~any(rows), continue; end
        Si = Ri(rows, :);
        % sort by DC for nice lines
        [dc, idx] = sort(Si.DC_nA, 'ascend');
        fr = Si.firing_rate_Hz(idx);
        fr = sgolayfilt(fr,2,51);

        h = plot(ax, dc, fr, ...
            'Color', C(k,:), ...
            'LineWidth', opts.LineWidth, ...
            'Marker', opts.MarkerFR, ...
            'DisplayName', sprintf('%g Hz (FR)', rk));
        legFR(end+1) = h; %#ok<AGROW>

        % Right axis: CoV (if present)
        if hasCoV
            covv = Si.CoV_ISI(idx);
            mask = ~isnan(covv);
            covv(mask) = sgolayfilt(covv(mask),2,51); 
            plot(axC, dc(mask), covv(mask), ...
                'Color', C(k,:), ...
                'LineStyle', opts.LineStyleCoV, ...
                'LineWidth', max(1, opts.LineWidth-0.5), ...
                'Marker', 'none', ...
                'HandleVisibility','off'); % keep legend clean
        end
    end

    xlabel(ax, 'DC clamp (nA)');
    ylabel(ax, 'Firing rate (spikes/sec)');
    if hasCoV
        xlabel(axC, 'DC clamp (nA)');
        ylabel(axC, 'CoV_{ISI}');
    end
    if hasWeight
        title(ax, sprintf('weight = %g \\muS', uW(iW)));
    end

    if opts.ShowLegend && iW == nW
        lgd = legend(ax, legFR, 'Location','northoutside','Orientation','horizontal');
        lgd.Box = 'off';
        title(lgd, "Pre-Synaptic Rate (spikes/sec)"); 
    end
end
end
