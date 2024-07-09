function T = loadSweepSpreadsheet(raw_root, SUBJ, TANK, sweep)
%LOADSWEEPSPREADSHEET Load spreadsheet for sweeps based on `sweep` folder and raw data root folder.
%
% Syntax:
%   T = loadSweepSpreadsheet(raw_root, SUBJ, TANK, sweep);

arguments
    raw_root {mustBeTextScalar, mustBeFolder}
    SUBJ {mustBeTextScalar}
    TANK {mustBeTextScalar}
    sweep {mustBeTextScalar}
end
sweep_spreadsheet = fullfile(raw_root, SUBJ, TANK, sweep, sprintf('%s.xlsx', sweep));
if exist(sweep_spreadsheet, 'file')==0
    T = [];
    warning("No sweep spreadsheet: %s\n", sweep_spreadsheet);
else
    T = readtable(sweep_spreadsheet);
    T.Properties.UserData = struct;
    T.Properties.UserData.Subject = SUBJ;
    T.Properties.UserData.Tank = TANK;
    T.Properties.UserData.Sweep = sweep;
    T.Properties.UserData.RootFolder = raw_root;
end

end