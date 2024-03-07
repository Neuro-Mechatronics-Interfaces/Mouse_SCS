function T = loadSweepSpreadsheet(raw_root, sweep)
%LOADSWEEPSPREADSHEET Load spreadsheet for sweeps based on `sweep` folder and raw data root folder.
%
% Syntax:
%   T = loadSweepSpreadsheet(raw_root, sweep);

arguments
    raw_root {mustBeTextScalar, mustBeFolder}
    sweep {mustBeTextScalar}
end

finfo = strsplit(sweep, '_');
SUBJ = finfo{1};
tank = strjoin(finfo(1:4), '_');

sweep_spreadsheet = fullfile(raw_root, SUBJ, tank, sweep, sprintf('%s.xlsx', sweep));
if exist(sweep_spreadsheet, 'file')==0
    T = [];
    warning("No sweep spreadsheet: %s\n", sweep_spreadsheet);
else
    T = readtable(sweep_spreadsheet);
end

end