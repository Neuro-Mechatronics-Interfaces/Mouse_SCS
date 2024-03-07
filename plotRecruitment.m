function fig = plotRecruitment(T, data, options)
%PLOTRECRUITMENT Plot recruitment summary figure

arguments
    T (:,3) table % Table with sweep metadata from loadData.
    data (:, 1) % Either: intan, saga.A, or saga.B (as returned by loadData)
    options.DataType {mustBeTextScalar, mustBeMember(options.DataType, ["Intan", "TMSi"])}
end

if size(T,1) ~= size(data,1)
    error("Must have same number of table rows as data structure elements.");
end

switch options.DataType
    case "Intan"
    
    case "TMSi"
        
    otherwise
        error("Unhandled DataType: %s", options.DataType);
end

end