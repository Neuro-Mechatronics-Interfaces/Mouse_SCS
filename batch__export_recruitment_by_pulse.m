function recruitmentFigure = batch__export_recruitment_by_pulse(T, response, channel, muscle, pptx, options)
%BATCH__EXPORT_RECRUITMENT_BY_PULSE  Exports recruitment curves, by pulse index, en masse.
arguments
    T
    response
    channel (:,1) double
    muscle (:,1) string
    pptx = [];
    options.CData (1,3) double = [0 0 0];
    options.MaxPulseIndex (1,1) {mustBeInteger, mustBePositive} = 10;
end

if numel(channel) ~= numel(muscle)
    error("Must have same number of `channel` (indices) as `muscle` (string) elements!");
end
vec = 1:min(max(T.n_pulses),options.MaxPulseIndex);
recruitmentFigure = gobjects(size(channel),numel(vec));
for iCh = 1:numel(channel)
    for iPulse = 1:numel(vec)
        recruitmentFigure(iCh,iPulse) = plotRecruitment(T, response, ...
            channel(iCh), muscle(iCh), ...
            'Color', options.CData, ...
            'PulseIndex', vec(iPulse));
        if ~isempty(pptx)
            slideId = pptx.addSlide();
            pptx.addTextbox(num2str(slideId), ...
                'Position',[4 7 0.5 0.5], ...
                'VerticalAlignment','bottom', ...
                'HorizontalAlignment','center', ...
                'FontSize', 10);
            pptx.addTextbox(strrep(recruitmentFigure(iCh,iPulse).UserData.Channel,'\mu','μ'), ...
                'Position',[0 0 10 1], ...
                'FontName', 'Tahoma', ...
                'FontSize', 24);
            pptx.addPicture(recruitmentFigure(iCh,iPulse),'Position',[0 1 10 6.5]);
        end
    end
end
end