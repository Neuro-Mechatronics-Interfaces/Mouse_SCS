function S = parseSummarySpreadsheet(SUBJ, YYYY, MM, DD, options)
arguments
    SUBJ {mustBeTextScalar}
    YYYY (1,1) double {mustBeInteger, mustBePositive}
    MM (1,1) double {mustBeInteger, mustBePositive}
    DD (1,1) double {mustBeInteger, mustBePositive}
    options.SAGA (1,:) string = ["A", "B"];
    options.SAGA_Tag {mustBeTextScalar} = "STIM";
    options.RawDataRoot {mustBeTextScalar} = "";
    options.Verbose (1,1) logical = true;
end
if strlength(options.RawDataRoot) == 0
    raw_root = parameters('raw_data_folder_root');
else
    raw_root = options.RawDataRoot;
end
tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);

s = [];
F = dir(fullfile(raw_root,SUBJ,tank,sprintf('%s*',tank)));
if options.Verbose
    fprintf(1,'Please wait, parsing %d sweeps...000%%\n', numel(F));
end
for iF = 1:numel(F)
    sweep = F(iF).name;
    T = loadSweepSpreadsheet(raw_root, SUBJ, tank, sweep);
    if ~ismember('is_monophasic',T.Properties.VariableNames)
        T.is_monophasic = false(size(T,1),1);
    end
    if ~ismember('is_cathodal_leading',T.Properties.VariableNames)
        T.is_cathodal_leading = true(size(T,1),1);
    end
    if ~ismember('return_channel',T.Properties.VariableNames)
        sweepNum = strsplit(sweep,'_');
        sweepNum = str2double(sweepNum{end});
        ret_ch = inputdlg(sprintf('What is the return channel for Sweep-%d?', sweepNum),'Input Return Channel');
        if isempty(ret_ch)
            disp("Canceled parsing.");
            S = [];
            return;
        end
        T.return_channel = repmat(ret_ch,size(T,1),1);
        T = movevars(T,"return_channel","After","channel");
    end
    writetable(T, fullfile(raw_root, SUBJ, tank, sweep, sprintf('%s.xlsx', sweep)));
    save(fullfile(raw_root, SUBJ, tank, sweep, sprintf('%s_Table.mat', sweep)));
    s = [s; T]; %#ok<AGROW>
    if options.Verbose
        fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*iF/numel(F)));
    end
end
s = sortrows(s,'sweep','ascend');

[G,S] = findgroups(s(:,"sweep"));
S.Properties.VariableNames{1} = 'Sweep';
S.Stim_Channel = splitapply(@(v)v(1),s.channel,G);
S.Return_Channel = splitapply(@(v)string(v{1}),s.return_channel,G);
S.Monophasic = splitapply(@(v)v(1),s.is_monophasic,G);
S.CathodalLeading = splitapply(@(v)v(1),s.is_cathodal_leading,G);
S.Min_Intensity = splitapply(@(v)min(v),s.intensity,G);
S.Max_Intensity = splitapply(@(v)max(v),s.intensity,G);
S.Intensity_Step = splitapply(@(v)parse_intensity_step(v),s.intensity,G);
S.Min_Frequency = splitapply(@(v)min(v),s.frequency,G);
S.Max_Frequency = splitapply(@(v)max(v),s.frequency,G);
S.Notes = strings(size(S,1),1);
    function stepVal = parse_intensity_step(v)
        u = unique(v);
        if isscalar(u)
            stepVal = nan;
            return;
        else
            tmp = sort(u,'ascend');
            stepVal = mode(diff(tmp));
            return;
        end
    end

end