function varargout = parameters(varargin)
%PARAMETERS Return parameters struct, which sets default values for things like epoch durations etc.
%
% Example 1
%   pars = parameters(); % Returns full "default parameters" struct.
%
% Example 2
%   pars = parameters('fc', [3, 30]); % Returns full "default parameters" struct, and changes default fc to [3, 30].
%
% Example 3
%   f = parameters('raw_data_folder'); % Returns raw data folder value
% %
% I tried to pull the key parameters, which are really path information
% from your local mapping to where the raw data is and where any
% auto-exported figures/data objects should go. Both
% `generated_data_folder` and `raw_data_folder` should be the folder that
% contains "animal name" folders (e.g. the folder with `Forrest` in it). 
%
% See also: Contents, io.load_tmsi_raw, plot.emg_averages

pars = struct;
% % % Trying to pull the "relevant" ones to the top ... % % %
% pars.generated_data_folder = '\\192.168.88.100\Data\generated_data'; % Setting this to human or primate, temporary hard code
% pars.raw_data_folder_root = '\\192.168.88.100\Data\raw_data';
pars.generated_data_folder = 'R:/NMLShare/generated_data/primate/DRGS';
pars.raw_data_folder_root = 'R:/NMLShare/raw_data/primate/DRGS';

N = numel(varargin);
if nargout == 1
    if rem(N, 2) == 1
        varargout = {pars.(varargin{end})};
        return;
    else
        f = fieldnames(pars);
        for iV = 1:2:N
            idx = strcmpi(f, varargin{iV});
            if sum(idx) == 1
               pars.(f{idx}) = varargin{iV+1}; 
            end
        end
        varargout = {pars};
        return;
    end
else
    f = fieldnames(pars);
    varargout = cell(1, nargout);
    for iV = 1:numel(varargout)
        idx = strcmpi(f, varargin{iV});
        if sum(idx) == 1
            varargout{iV} = pars.(f{idx}); 
        else
            error('Could not find parameter: %s', varargin{iV}); 
        end
    end
end

end
