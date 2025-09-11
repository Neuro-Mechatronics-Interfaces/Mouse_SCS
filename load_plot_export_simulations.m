function [sweep_data, simdata] = load_plot_export_simulations(SimulationName, options)

arguments
    SimulationName {mustBeMember(SimulationName,["m2","leak"])} = "leak";
    options.APThreshold (1,1) double = -10; % mV
    options.CloseExisting (1,1) logical = true;
    options.ClearCommandWindow (1,1) logical = true;
    options.SaveFolder {mustBeTextScalar} = 'export/NEURON';
    options.DeckName {mustBeTextScalar} = '%s-Modulation';
    options.SimulationOutputFolder = fullfile(pwd,"NEURON/MotorNeuron/out_%s");
end
if contains(string(options.SimulationOutputFolder),"_%s")
    options.SimulationOutputFolder = sprintf(strrep(options.SimulationOutputFolder,"\","/"),SimulationName);
end
if options.CloseExisting, close all force; end
if options.ClearCommandWindow, clc; end
if contains(string(options.DeckName),"%s-")
    ProperName = char(SimulationName);
    ProperName(1) = upper(ProperName(1));
    ProperName(2:end) = lower(ProperName(2:end));
    options.DeckName = sprintf(options.DeckName,ProperName);
end

% Deck
pptx = exportToPPTX('', 'Dimensions',[10,7.5], ...
    'Title',sprintf('%s MOTONEURON Simulations',options.DeckName), ...
    'Author','Max Murphy (MATLAB Auto-gen)', ...
    'Subject',sprintf('%s MOTONEURON Simulations',options.DeckName), ...
    'Comments','Frequency-vs-Rate sweeps under different conditions.');
pptx.addSlide();
pptx.addTextbox(sprintf('%s (NEURON Simulated)',options.DeckName), ...
        'Position',[0 3.5 10 1.5], 'FontName','Arial', ...
        'HorizontalAlignment','center','FontSize',36);

[~,deck_name,~] = fileparts(options.DeckName);
sweep_data = [];

% 1) Load ALL simulated data (weights discovered via weights.tsv)
simdata = load_simulated_data( ...
    'APThreshold', options.APThreshold, ...
    'SimulationOutputFolder', options.SimulationOutputFolder);

% 2) Loop by sequence type (E3, IIE, …)
uSeq = unique(simdata.SeqAbbr,'stable');
for s = 1:numel(uSeq)
    thisSeq = uSeq(s);
    sd = simdata(simdata.SeqAbbr == thisSeq, :);

    % choose synapse marker styles once per sequence (for per-trace tiles)
    pulseTypeAuto = seqabbr_to_pulsetype(thisSeq);

    % Plot tiles per (M2, Leak, SweepName) group and compute rates
    [fig, tmp] = plot_simulations(sd, 'PulseType', pulseTypeAuto);
    % keep sequence tag in aggregate table for overlay plot
    if ~ismember('SeqAbbr', tmp.Properties.VariableNames)
        tmp.SeqAbbr = repmat(thisSeq, height(tmp), 1);
    else
        tmp.SeqAbbr(:) = thisSeq;
    end
    sweep_data = [sweep_data; tmp]; %#ok<AGROW>

    % Slides for this sequence
    seqLabel = sprintf('Sequence: %s', thisSeq);
    pptx.addSlide();
    pptx.addTextbox(seqLabel, 'Position',[0 3.5 10 0.8], ...
        'HorizontalAlignment','center','FontSize',20,'FontAngle','italic');

    % Export/save each figure immediately; then close it
    for iFig = 1:numel(fig)
        slideId = pptx.addSlide();
        pptx.addTextbox(num2str(slideId), 'Position',[9.5 7 0.5 0.5], ...
            'VerticalAlignment','bottom','HorizontalAlignment','right', ...
            'FontSize',10,'FontName','Consolas');

        % Small guidance legend (sequence-level)
        if contains(upper(thisSeq),'I')
            pptx.addTextbox('Blue = synaptic IPSP onset (stimuli)', ...
                'Position',[0 7.0 4.5 0.5],'FontWeight','bold', ...
                'Color',[0 0 1],'FontSize',10,'FontName','Arial');
        end
        pptx.addTextbox('Red = synaptic EPSP onset (stimuli)', ...
            'Position',[0 6.75 4.5 0.5],'FontWeight','bold', ...
            'Color',[1 0 0],'FontSize',10,'FontName','Arial');
        pptx.addTextbox('Black = membrane voltage at soma', ...
            'Position',[0 6.5 4.5 0.5],'FontWeight','bold', ...
            'FontSize',10,'FontName','Arial');

        % Add the figure
        pptx.addPicture(fig(iFig),'Position',[0.5 0 9 6.5]);

        % Save to disk; use the *actual* sweep name from UserData (set in plot_simulations)
        ud = fig(iFig).UserData;
        fn = sprintf("Recruitment_Vsoma_%s_%ggl_%gm2_%gblending", ...
            string(ud.SweepName), ud.Leak, ud.M2_Level, ud.Blending_Level);
        utils.save_figure(fig(iFig), sprintf('%s/%s',options.SaveFolder,deck_name), fn, ...
            'ExportAs',{'.png','.svg'}, 'SaveFigure', true);
    end
end

% 3) Overlay plot: EPSP-only vs IPSP-containing, style by SweepBase
fig = plot_simulation_sweeps(simdata); 
slideId = pptx.addSlide();
pptx.addTextbox(num2str(slideId), 'Position',[9.5 7 0.5 0.5], ...
    'VerticalAlignment','bottom','HorizontalAlignment','right', ...
    'FontSize',10,'FontName','Arial');
pptx.addTextbox('RESULT: Pre- and Post-Synaptic Frequency Curves', ...
    'Position',[0 0 10 1],'VerticalAlignment','middle', ...
    'HorizontalAlignment','left','FontSize',20,...
    'FontName','Arial','FontWeight','bold');
pptx.addPicture(fig, 'Position',[0 1 10 5]);
utils.save_figure(fig, options.SaveFolder, 'All_Pre-vs-Post_Synaptic_Frequency_Curves');

% 4) Save deck
pptx.save(fullfile(options.SaveFolder, deck_name));
warning('on','signal:findpeaks:largeMinPeakHeight');
end

function pulseType = seqabbr_to_pulsetype(seqabbr)
% Red dashed = EPSP (E), Blue dash-dot = IPSP (I)
seqabbr = upper(string(seqabbr));
switch seqabbr
    case "E3",  pulseType = {'r--','r--','r--'};
    case "I3",  pulseType = {'b-.','b-.','b-.'};
    case "IIE", pulseType = {'b-.','b-.','r--'};
    case "IEE", pulseType = {'b-.','r--','r--'};
    case "EIE", pulseType = {'r--','b-.','r--'};
    otherwise,  pulseType = {'k-','k-','k-'}; % neutral fallback
end
end
