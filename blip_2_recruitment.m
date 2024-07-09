function recruitment = blip_2_recruitment(blip, options)
%BLIP_2_RECRUITMENT Estimate recruitment value from de-trended response blips.
%
% Syntax:
%   recruitment = blip_2_recruitment(blip, "Name", value, ...);
%
% Inputs:
%   blip - nResponseTimeSamples x nChannels x nResponseRepetitions double
%
% Options:
%   'Metric' (default: 'pk2pk') - Currently only 'pk2pk' is supported.
%
% Output:
%   recruitment - nChannels x nResponseRepetitions double
arguments
    blip double
    options.Metric {mustBeMember(options.Metric,{'pk2pk'})} = 'pk2pk';
end
recruitment = nan(size(blip,2),size(blip,3));
switch options.Metric
    case 'pk2pk'
        for ii = 1:size(blip,2)
            for iCh = 1:size(blip,3)
                recruitment(ii,iCh) = max(blip(:,ii,iCh)) - min(blip(:,ii,iCh));
            end
        end
end

end