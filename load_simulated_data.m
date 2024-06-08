function simdata = load_simulated_data(W1, W2, W3, options)
%LOAD_SIMULATED_DATA  Load data simulated using NEURON tool
arguments
    W1 (1,1) double
    W2 (1,1) double
    W3 (1,1) double
    options.SimulationFolder = fullfile(pwd,"NEURON/MotorNeuron/out");
    options.FrequenciesFile = "frequencies.dat";
    options.M2LevelsFile = "m2_levels.dat";
    options.LeakLevelsFile = "leak_levels.dat";
end
Frequency = load(fullfile(options.SimulationFolder, options.FrequenciesFile));
nFreq = numel(Frequency);
Frequency = reshape(Frequency,nFreq,1);
M2_Level = load(fullfile(options.SimulationFolder, options.M2LevelsFile));
nM2 = numel(M2_Level);
M2_Level = reshape(M2_Level,nM2,1);
M2_Level = repelem(M2_Level,nFreq,1);
Frequency = repmat(Frequency,nM2,1);
Leak = load(fullfile(options.SimulationFolder, options.LeakLevelsFile));
nLeak = numel(Leak);
Leak = reshape(Leak, nLeak, 1);
Frequency = repmat(Frequency, nLeak, 1);
M2_Level = repmat(M2_Level, nLeak, 1);
Leak = repelem(Leak, nM2*nFreq, 1);

nTotal = nM2 * nFreq * nLeak;

Time = cell(nTotal,1);
Voltage = cell(nTotal,1);
for iF = 1:nTotal
    Time{iF} = load(fullfile(options.SimulationFolder,sprintf("time_%g_%g_%g_%ggl_%gm2_%dHz.dat",W1,W2,W3,Leak(iF),M2_Level(iF),Frequency(iF))));
    Voltage{iF} = load(fullfile(options.SimulationFolder,sprintf("voltage_%g_%g_%g_%ggl_%gm2_%dHz.dat",W1,W2,W3,Leak(iF),M2_Level(iF),Frequency(iF))));
end
W1 = ones(nTotal,1).*W1;
W2 = ones(nTotal,1).*W2;
W3 = ones(nTotal,1).*W3;
simdata = table(M2_Level, Leak, W1, W2, W3, Frequency, Time, Voltage);
end