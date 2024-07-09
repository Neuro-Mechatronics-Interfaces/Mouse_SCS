function batch_export_pulse_recruitment(intensity, frequency, muscle, T, response, options)
arguments
    intensity
    frequency
    muscle
    T
    response
    options.ExportFolder = fullfile(pwd,"export");
end

out_folder = fullfile(options.ExportFolder,T.Properties.UserData.Subject,'Pulse-Recruitment');
if exist(out_folder,'dir')==0
    mkdir(out_folder);
end

for iChannel = 1:numel(muscle) 
    fig = plotPulseRecruitment(intensity, frequency, iChannel, T, response, ...
        'ChannelName', muscle(iChannel));
    utils.save_figure(fig,out_folder,sprintf('%s_%duA_%dHz_%s_Pulse-Recruitment', ...
        T.Properties.UserData.Sweep, ...
        intensity, frequency, muscle(iChannel)));

end

end