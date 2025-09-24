function simdata = load_simulated_data(options)
%LOAD_SIMULATED_DATA  Discover W1/W2/W3 from weights.tsv and load all data.
arguments
    options.APThreshold (1,1) double = 10; % mV
    options.SimulationOutputFolder = fullfile(pwd,"NEURON/MotorNeuron/out_leak")
    options.FrequenciesFile = "frequencies.dat"
    options.M2LevelsFile = "m2_levels.dat"
    options.LeakLevelsFile = "leak_levels.dat"
    options.BlendingLevelsFile = "blending_levels.dat"
    options.SeqModesFile = "syn_sequence_modes.tsv"
    options.PulseIntensitiesFile = "pulse_intensities.tsv"
    options.IncludeSeqModes double = []
    options.IncludeIntensityRows double = []
    options.IncludeWeightRows double = [] 
    options.WeightsFile = "weights.tsv";
    options.MissingOK (1,1) logical = false
end

outdir = options.SimulationOutputFolder;

% Read weights.tsv (row, W1, W2, W3)
wT = readtable(fullfile(outdir,"weights.tsv"), ...
    'FileType','text','Delimiter','\t','ReadVariableNames',true);
wantRows = 1:height(wT);
if ~isempty(options.IncludeWeightRows)
    wantRows = intersect(wantRows, options.IncludeWeightRows);
end
wT = wT(wantRows,:);

% Accumulate simdata across weight rows
simdata = table();
for r = 1:height(wT)
    W1 = wT.W1(r); W2 = wT.W2(r); W3 = wT.W3(r);
    simr = load_simulated_data_one(W1, W2, W3, ...
        'APThreshold',options.APThreshold, ...
        'SimulationOutputFolder', options.SimulationOutputFolder, ...
        'FrequenciesFile', options.FrequenciesFile, ...
        'M2LevelsFile', options.M2LevelsFile, ...
        'LeakLevelsFile', options.LeakLevelsFile, ...
        'BlendingLevelsFile', options.BlendingLevelsFile, ...
        'SeqModesFile', options.SeqModesFile, ...
        'PulseIntensitiesFile', options.PulseIntensitiesFile, ...
        'IncludeSeqModes', options.IncludeSeqModes, ...
        'IncludeIntensityRows', options.IncludeIntensityRows, ...
        'WeightsFile', options.WeightsFile, ...
        'MissingOK', options.MissingOK);
    simdata = [simdata; simr]; %#ok<AGROW>
end
end
