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
pars.generated_data_folder = 'G:/Shared drives/NML_Rodent/NeuroMechLab/Mouse_SCS/generated_data';
pars.raw_data_folder_root = 'G:/Shared drives/NML_Rodent/NeuroMechLab/Mouse_SCS/raw_data';
pars.local_export_folder = strrep(fullfile(pwd,'export'),'\','/');

% Frank-specific parameters
pars.frank_valid_uni_channels = struct('A',[], 'B', []);
pars.frank_valid_uni_channels.A = {[7,8,12,13,14,15,16,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,50,51,52,53,54,55,56,60,61,62,63,64]};
pars.frank_valid_uni_channels.B = {[2,3,4,5,6,7,10,11,12,13,14,15,18,19,20,21,22,23,26,27,28,30,31,32]; [33,34,35,36,37,38,39,40,42,43,44,45,46,47,48,49,52,53,54,55]};
pars.frank_saga_channel_ranges = struct('A', struct('UNI',[2,65],'BIP',[66,69],'ACC',[70,72]), 'B', struct('UNI',[2,65],'BIP',[66,69],'ACC',[70,72]));
pars.frank_unipolar_layout = struct('A', "Grid", 'B', "Tex");
pars.frank_bipolar_layout = struct('A', ["ED23"; "APL"; "BIC_s"; "BR"], 'B', ["TRIC_l"; "DELT_m"; "DELT_a"; "PEC"]);

% Baby Yoda specific parameters
pars.babyyoda_valid_uni_channels = struct('A',[], 'B', []);
pars.babyyoda_valid_uni_channels.A = {1:64};
pars.babyyoda_valid_uni_channels.B = {1:32; 33:64};
pars.babyyoda_saga_channel_ranges = struct('A', struct('UNI',[2,65],'BIP',[66,69],'ACC',[70,72]), 'B', struct('UNI',[2,65],'BIP',[66,69],'ACC',[70,72]));
pars.babyyoda_unipolar_layout = struct('A', "Grid", 'B', "Tex");
pars.babyyoda_bipolar_layout = struct('A', ["ED23"; "APL"; "BIC_s"; "BR"], 'B', ["TRIC_l"; "DELT_m"; "DELT_a"; "PEC"]);

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
