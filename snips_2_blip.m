function [blip,trend] = snips_2_blip(snips, iStart, iStop, options)
%SNIPS_2_BLIP  Extract blips from the response snips.
%
% Syntax:
%   [blip,trend] = snips_2_blip(snips, iStart, iStop, 'Name', value, ...);
%
% Inputs:
%   snips - The full response snippets (nTimeSamples x nChannels x nReps)
%   iStart - Start index for the blip time epoch  (positive integer)
%   iStop  - End index for the blip time epoch (positive integer)
%   
% Options:
%   'DetrendMode' - Must be 'poly' (default) or 'exp' 
%   'PolyOrder' (default: 1) - Used with 'poly' DetrendMode option to fit
%                               subtracted polynomial. If PolyOrder is 1, 
%                               just uses linspace.
%
% Output:
%   blip - nResponseTimeSamples x nChannels x nRepetitions double
%   trend - nResponseTimeSamples x nChannels x nRepetitions double -- Part
%               that was removed in order to produce the blip.
%
% See also: Contents, estimate_recruitment, blip_2_recruitment

arguments
    snips double
    iStart (1,1) {mustBePositive, mustBeInteger}
    iStop (1,1) {mustBePositive, mustBeInteger}
    options.DetrendMode {mustBeMember(options.DetrendMode, {'poly', 'exp'})} = 'poly';
    options.PolyOrder (1,1) {mustBePositive, mustBeInteger} = 1;
    options.IStartExponential (1,1) {mustBePositive, mustBeInteger} = 51;
    options.IStopExponential (1,1) {mustBePositive, mustBeInteger} = 160;
end
vec = iStart:iStop;
nSamples = numel(vec);
blip = nan(numel(vec),size(snips,3),size(snips,2));
trend = nan(size(blip));
switch options.DetrendMode
    case 'poly'
        if options.PolyOrder == 1
            for ii = 1:size(snips,3)
                for iCh = 1:size(snips,2)
                    trend(:,ii,iCh) = linspace(snips(iStart,iCh,ii),snips(iStop,iCh,ii),nSamples)';
                    blip(:,ii,iCh) = snips(vec,iCh,ii) - trend(:,ii,iCh);
                end
            end
        else
            for ii = 1:size(snips,3)
                for iCh = 1:size(snips,2)
                    blip(:,ii,iCh) = detrend(snips(vec,iCh,ii),options.PolyOrder);
                    trend(:,ii,iCh) = snips(vec,iCh,ii) - blip(:,ii,iCh);
                end
            end
        end
    case 'exp'
        vecExp = options.IStartExponential:options.IStopExponential;
        vecPolyStart = find(vecExp==iStart,1,'first');
        vecPolyStop = find(vecExp==iStop,1,'first');
        vec = vecPolyStart:vecPolyStop;
        tVec = (0:(numel(vecExp)-1))';
        for ii = 1:size(snips,3)
            for iCh = 1:size(snips,2)
                [blipTmp, trendTmp] = exponential_detrend(tVec,snips(vecExp,iCh,ii));
                blip(:,ii,iCh) = detrend(blipTmp(vec), options.PolyOrder);
                trend(:,ii,iCh) = trendTmp(vec) + (blipTmp(vec) - blip(:,ii,iCh));
            end
        end
end
end