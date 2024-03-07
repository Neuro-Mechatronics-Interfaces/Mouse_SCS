function [saga, intan, T] = loadMultiData(SUBJ, YYYY, MM, DD, SWEEPS, options)
%LOADMULTIDATA Load multiple sweeps into single sweep table. 
%
% Syntax:
%   [saga, intan, T] = loadMultiData(SUBJ, YYYY, MM, DD, SWEEPS, 'Name', value, ...);

arguments
    SUBJ {mustBeTextScalar}
    YYYY (1,1) double {mustBeInteger, mustBePositive}
    MM (1,1) double {mustBeInteger, mustBePositive}
    DD (1,1) double {mustBeInteger, mustBePositive}
    SWEEPS (1,:) double {mustBeInteger, mustBeGreaterThanOrEqual(SWEEPS, 0)}
    options.LoadIntan (1,1) logical = false;
    options.SAGA (1,:) string = ["A", "B"];
    options.SAGA_Tag {mustBeTextScalar} = "STIM";
    options.RawDataRoot {mustBeTextScalar} = "";
    options.Verbose (1,1) logical = true;
end

saga = [];
intan = [];
T = [];
N = numel(SWEEPS);
if options.Verbose
    fprintf(1,'Loading %d sweeps...%03d%%\n', N);
end
for ii = 1:N
    [saga_tmp, intan_tmp, T_tmp] = loadData(SUBJ, YYYY, MM, DD, SWEEPS(ii), ...
        'SAGA', options.SAGA, 'SAGA_Tag', options.SAGA_Tag, ...
        'RawDataRoot', options.RawDataRoot, 'LoadIntan', options.LoadIntan, ...
        'Verbose', false);
    saga = [saga; saga_tmp]; %#ok<*AGROW> 
    intan = [intan; intan_tmp];
    T = [T; T_tmp];
    if options.Verbose
        fprintf(1,'\b\b\b\b\b%03d%%\n', round(ii*100/N));
    end
end

end