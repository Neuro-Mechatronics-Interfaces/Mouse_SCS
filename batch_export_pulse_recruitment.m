function batch_export_pulse_recruitment(intensity, frequency, muscle, T, response, options)
%BATCH_EXPORT_PULSE_RECRUITMENT  Batch routine to export pulse recruitment scatter plots for multiple intensities, frequencies, and muscle recordings.
arguments
    intensity
    frequency
    muscle
    T
    response
    options.ExportFolder = fullfile(pwd,"export");
    options.CData (:,3) double {mustBeInRange(options.CData,0,1)} = [0 0 0];
    options.Marker (1,:) char {mustBeMember(options.Marker, {'o','.','s','h','*'})} = 'o';
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.75;
    options.ExportAs (1,:) cell = {'.png'};
    options.SaveFigure (1,1) logical = false;
end

out_folder = fullfile(options.ExportFolder,T.Properties.UserData.Subject,'Pulse-Recruitment');
if exist(out_folder,'dir')==0
    mkdir(out_folder);
end

if (size(options.CData,1) == 1) && (numel(muscle) > 1)
    colorData = repmat(options.CData,numel(muscle),1);
else
    colorData = options.CData;
end

if isscalar(options.Marker) && (numel(muscle) > 1)
    markerData = repmat(options.Marker,1,numel(muscle));
else
    markerData = options.Marker;
end

if isempty(frequency)
    uF = unique(T.frequency);
else
    uF = unique(frequency);
end
if isempty(intensity)
    uI = unique(T.intensity);
else
    uI = unique(intensity);
end
for iFreq = 1:numel(uF)
    for iIntensity = 1:numel(uI)
        for iChannel = 1:numel(muscle) 
            fig = plotPulseRecruitment(uI(iIntensity), uF(iFreq), iChannel, T, response, ...
                'ChannelName', muscle(iChannel), ...
                'CData', colorData(iChannel,:), ...
                'Marker', markerData(iChannel), ...
                'Alpha', options.Alpha);
            utils.save_figure(fig,out_folder,sprintf('%s_%duA_%dHz_%s_Pulse-Recruitment', ...
                T.Properties.UserData.Sweep, ...
                uI(iIntensity), uF(iFreq), muscle(iChannel)), ...
                'ExportAs', options.ExportAs, ...
                'SaveFigure', options.SaveFigure);

        end
    end
end

end