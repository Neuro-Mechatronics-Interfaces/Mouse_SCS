function [saga, intan, T] = loadData(SUBJ, YYYY, MM, DD, SWEEP, options)
%LOADDATA Load all data associated with a single sweep.
%
% Syntax:
%   [saga, intan, T] = loadData(SUBJ, YYYY, MM, DD, SWEEP, 'Name', value, ...);
%
% Inputs: 
%     SUBJ {mustBeTextScalar}
%     YYYY (1,1) double {mustBeInteger, mustBePositive}
%     MM (1,1) double {mustBeInteger, mustBePositive}
%     DD (1,1) double {mustBeInteger, mustBePositive}
%     SWEEP (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(SWEEP, 0)}
%     options.LoadIntan (1,1) logical = true;
%     options.LoadSAGA (1,1) logical = true;
%     options.LoadSpreadsheet (1,1) logical = true;
%     options.SAGA (1,:) string = ["A", "B"];
%     options.SAGA_Tag {mustBeTextScalar} = "STIM";
%     options.RawDataRoot {mustBeTextScalar} = "";
%     options.Verbose (1,1) logical = true;
%
% Output:
%   saga - Struct containing 'A' and 'B' fields by default, corresponding
%           to each SAGA. Each field is an array of structs of loaded SAGA
%           data.
%   intan - Array struct containing the recording data from INTAN for each
%               block in the sweep.
%   T - Metadata table indicating which sweep parameters associate with the
%           corresponding element in `saga.A`, `saga.B`, or `intan` arrays.
%
% See also: Contents

arguments
    SUBJ {mustBeTextScalar}
    YYYY (1,1) double {mustBeInteger, mustBePositive}
    MM (1,1) double {mustBeInteger, mustBePositive}
    DD (1,1) double {mustBeInteger, mustBePositive}
    SWEEP (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(SWEEP, 0)}
    options.LoadIntan (1,1) logical = true;
    options.LoadSAGA (1,1) logical = true;
    options.LoadSpreadsheet (1,1) logical = true;
    options.SAGA (1,:) string = ["A", "B"];
    options.SAGA_Tag {mustBeTextScalar} = "STIM";
    options.RawDataRoot {mustBeTextScalar} = "";
    options.Verbose (1,1) logical = true;
end

if strlength(options.RawDataRoot) == 0
    raw_root = parameters('raw_data_folder_root');
else
    raw_root = options.RawDataRoot;
end
tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
sweep = sprintf('%s_%d', tank, SWEEP);

if options.LoadIntan
    if options.Verbose
        fprintf(1,'Loading Intan sweeps...\n');
    end
    intan_expr = fullfile(raw_root, SUBJ, tank, sweep, sprintf('%s_*_*_*', tank));
    F = dir(intan_expr);
    intan = cell(size(F));
    for iF = 1:numel(F)
        if ~F(iF).isdir
            continue;
        end
        Ff = dir(fullfile(F(iF).folder, F(iF).name, sprintf('%s_*.rhd', tank)));
        if numel(Ff)~=1
            error("%d elements in sub-folder (%s). Should only be 1.\n", numel(Ff), fullfile(F(iF).folder, F(iF).name));
        end
        fname = fullfile(Ff(1).folder, Ff(1).name);
        intan{iF} = io.read_Intan_RHD2000_file(fname);
    end
    intan = vertcat(intan{:});
else
    intan = [];
end

if options.LoadSAGA
    saga = struct;
    for ii = 1:numel(options.SAGA)
        if options.Verbose
            fprintf(1, 'Loading SAGA %s sweeps...\n', options.SAGA(ii));
        end
        saga_expr = fullfile(raw_root, SUBJ, tank, sweep, sprintf('%s_%s_%s_*.mat', ...
            tank, options.SAGA_Tag, options.SAGA(ii)));
        F = dir(saga_expr);
        saga.(options.SAGA(ii)) = cell(size(F));
        saga_block = nan(size(F));
        for iF = 1:numel(F)
            [~,f,~] = fileparts(F(iF).name);
            finfo = strsplit(f, '_');
            saga_block(iF) = str2double(finfo{7});
            saga.(options.SAGA(ii)){iF} = load(fullfile(F(iF).folder, F(iF).name));
        end
        [~,idx] = sort(saga_block, 'ascend');
        saga.(options.SAGA(ii)) = saga.(options.SAGA(ii))(idx);
        saga.(options.SAGA(ii)) = vertcat(saga.(options.SAGA(ii)){:});
    end
else
    saga = [];
end


if options.LoadSpreadsheet
    if options.Verbose
        fprintf(1,'Loading sweep spreadsheet...\n');
    end
    T = loadSweepSpreadsheet(raw_root, SUBJ, tank, sweep);
else
    T = [];
end
end