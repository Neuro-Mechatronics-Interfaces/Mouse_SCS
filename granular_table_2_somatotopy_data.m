function [data, somatotopicOutput] = granular_table_2_somatotopy_data(T, options)

arguments
    T
    options.Frequency (1,1) double = 1;
    options.Intensity (1,:) double = 2500;
    options.TrainPulseIndex (1,1) double = 1;
    options.Return_Channel {mustBeMember(options.Return_Channel, {'L', 'R', 'X', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'X8'})} = 'L';
    options.Label_LUT (1,:) string = ["L-P-DELTOID", "L-TRICEPS", "L-BICEPS", "L-WRIST-EXT", "L-PARASPINALS", "R-PARASPINALS", "R-WRIST-EXT", "R-BICEPS", "R-TRICEPS", "R-P-DELTOID"];
    options.Label (1,:) string = ["L-P-DELT", "L-TRI", "L-BIC", "L-WEXT", "L-PARA", "R-PARA", "R-WEXT", "R-BIC", "R-TRI", "R-P-DELT"] % Order of muscles as columns in `data`
    options.DefaultPlateauNormalizationValue (1,1) double = 1000000; % For when no stim location/intensity had a significant response curve this will "squash" values to near-zero.
end

if numel(options.Label_LUT) ~= numel(options.Label)
    error("Must have same number of elements in options.Label_LUT (current: %d) and options.Label (current: %d).", numel(options.Label_LUT), numel(options.Label));
end

if isscalar(options.Intensity)
    intensity = ones(1,numel(options.Label)).*options.Intensity;
else
    if numel(options.Intensity) ~= numel(options.Label)
        error("If specifying multiple intensities, must specify one intensity (current: %d elements) per label (current: %d elements).", numel(options.Intensity), numel(options.Label));
    end
    intensity = options.Intensity;
end

lut = string(T.Muscle);
data = cell(8,numel(options.Label));
for iCol = 1:numel(options.Label)
    normdata_idx = (lut == options.Label_LUT(iCol)) & (T.frequency==1);
    tmp = T(normdata_idx,:);
    [G,TID] = findgroups(tmp(:,["channel", "return_channel"]));
    mdl = cell(size(TID,1),1);
    for iGroup = 1:size(TID,1)
        mask = G == iGroup;
        mdl{iGroup} = Somatotopy.fit_sigmoid_response(tmp.intensity(mask), tmp.Response(mask));
    end
    plateau_value = estimate_plateau_from_sigmoid_models(mdl, options.DefaultPlateauNormalizationValue);
    
    data_idx = (lut == options.Label_LUT(iCol)) & strcmpi(T.return_channel, options.Return_Channel) & (T.frequency==options.Frequency) & (T.intensity==intensity(iCol)) & (T.Train_Pulse_Index==options.TrainPulseIndex);
    tmp = T(data_idx,:);
    for iCh = 1:8
        data{iCh,iCol} = tmp.Response(tmp.channel==iCh) ./ plateau_value;
    end
end
somatotopicOutput = options.Label; % In case we want to use it explicitly in Somatotopy constructor
end