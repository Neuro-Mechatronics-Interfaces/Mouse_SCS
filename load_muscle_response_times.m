function [tResponse, detrendPolynomialOrder] = load_muscle_response_times(muscle,options)
%LOAD_MUSCLE_RESPONSE_TIMES  Loads muscle expected response times from calibration file.
arguments
    muscle (:,1) string
    options.CalibrationFile = "Muscle_Response_Times.xlsx";
end

T = readtable(options.CalibrationFile);
T.Muscle = string(T.Muscle);

tResponse = nan(numel(muscle),2);
detrendPolynomialOrder = nan(numel(muscle),1);
for ii = 1:numel(muscle)
    idx = find(T.Muscle == muscle(ii),1,'first');
    if isempty(idx)
        error("Missing MUSCLE entry: %s--check muscle map or lookup table for typo?",muscle(ii));
    end
    tResponse(ii,:) = [T.tStart(idx), T.tStop(idx)];
    detrendPolynomialOrder(ii) = T.PolynomialOrder(idx);
end

end