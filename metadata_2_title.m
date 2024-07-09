function [longName, shortName] = metadata_2_title(T)
%METADATA_2_TITLE Convert table metadata row to string

longName = strings(size(T,1),1);
shortName = strings(size(T,1),1);
for ii = 1:size(T,1)
    if T.is_monophasic(ii)
        if T.is_cathodal_leading(ii)
            pulseString = 'Mono-Cathodal';
        else
            pulseString = 'Mono-Anodal';
        end
    else
        if T.is_cathodal_leading(ii)
            pulseString = 'Bi-Cathodal';
        else
            pulseString = 'Bi-Anodal';
        end
    end
    longName(ii) = string(sprintf("Sweep-%d A%d C%s %dμs %dμA %s %dHz",T.sweep(ii),T.channel(ii),T.return_channel{ii},T.pulse_width(ii),T.intensity(ii),pulseString,T.frequency(ii)));
    shortName(ii) = string(sprintf("A%d C%s %dμA %dHz",T.channel(ii),T.return_channel{ii},T.intensity(ii),T.frequency(ii)));
end

end