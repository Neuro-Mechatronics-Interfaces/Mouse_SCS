function fsamples = applyFilters(samples, channel, options)
%APPLYFILTERS  Apply filters to sample data in array where rows are channels and columns are time samples.
%
% Syntax:
%   fsamples = applyFitlers(samples, channel, 'Name', value, ...);
%
% Inputs:
%   samples - nChannels x nSamples array
%   channel - Index into rows of samples, for the output data.
%
% Options:
%     ApplyCAR (1,1) logical = true;
%     Fc (1,:) double = 5;  % Cutoff frequency (Hz); follows following rule: [] == no filter; 1 element: HPF; (Fc_low) 2 elements: BPF (Fc_low, Fc_high)
%     PlotCARRMS (1,1) logical = true;
%     RMSTitle {mustBeTextScalar} = "Filtering";
%     SampleRate (1,1) double {mustBePositive} = 4000;
%     ValidCARChannels (1,:) = 2:65;
%
% See also: Contents, plotSagaRecruitmentRaw

arguments
    samples
    channel
    options.ApplyCAR (1,1) logical = true;
    options.Fc (1,:) double = 5;  % Cutoff frequency (Hz); follows following rule: [] == no filter; 1 element: HPF; (Fc_low) 2 elements: BPF (Fc_low, Fc_high)
    options.PlotCARRMS (1,1) logical = true;
    options.RMSTitle {mustBeTextScalar} = "Filtering";
    options.SampleRate (1,1) double {mustBePositive} = 4000;
    options.ValidCARChannels (1,:) = 2:65;
end

if numel(options.Fc) == 1
    [b,a] = butter(2,options.Fc/(options.SampleRate/2),'high');
    ApplyFrequencyFilter = true;
elseif numel(options.Fc) == 2
    [b,a] = butter(2,options.Fc./(options.SampleRate/2), 'bandpass');
    ApplyFrequencyFilter = true;
else
    ApplyFrequencyFilter = false;
end

if options.ApplyCAR && options.PlotCARRMS
    close all force;
end

if options.ApplyCAR
    car_data = samples(channel,:) - median(samples(channel,:),2);
    if (channel > 1) && (channel <= 65)
        car_channels = samples(options.ValidCARChannels,:) - median(samples(options.ValidCARChannels,:),2);
        mu = median(car_channels, 1);
        car_data = car_data - mu;
        if options.PlotCARRMS
            rms_fig = figure(...
                'Color', 'w', ...
                'Name', sprintf('RMS: %s', options.RMSTitle)); 
            rms_ax = axes(rms_fig, 'NextPlot','add','FontName','Tahoma');

            yyaxis(rms_ax,'left');
            bar(rms_ax, options.ValidCARChannels-1.25, rms(car_channels,2), 0.5);
            ylabel(rms_ax, 'RMS (\muV)', 'FontName','Tahoma','Color','k');

            yyaxis(rms_ax,'right');
            bar(rms_ax, options.ValidCARChannels-0.75, rms(car_channels - mu, 2), 0.5);
            ylabel(rms_ax, 'Post-CAR RMS (\muV)', 'FontName','Tahoma','Color','k');

            title(rms_ax, options.RMSTitle, 'FontName', 'Tahoma','Color','k');
            xlabel(rms_ax, 'UNI Channel', 'FontName','Tahoma','Color','k');
        end
    end
else
    car_data = samples(channel,:);
end
if ApplyFrequencyFilter
    fsamples = filter(b,a,car_data);
else
    fsamples = car_data;
end

end