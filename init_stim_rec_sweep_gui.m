function fig = init_stim_rec_sweep_gui(client, am4100, logger, options)

arguments
    client
    am4100
    logger
    options.BLOCK (1,1) {mustBeInteger} = 0;
    options.SWEEP (1,1) {mustBeInteger} = 0;
    options.STIM_CHANNEL (1,1) {mustBeInteger} = 1;
    options.STIM_RETURN (1,1) {mustBeMember(options.STIM_RETURN,["X","L","R"])} = "X";
    options.INTENSITIES (1,:) double = 30:30:300;
    options.FREQUENCIES (1,:) double = [1, 10, 40, 100];
    options.BURST_DURATION (1,1) double = 0.2;
    options.BURST_REPETITIONS (1,1) {mustBeInteger} = 5;
    options.RAW_DATA_ROOT = "";
end


fig = uifigure('Name', 'Mouse SCS Stim/Rec Controller', ...
    'Color', 'k', 'Units', 'inches', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Position',[0.5 0.5 5 8]);
fig.UserData = struct();
fig.UserData.client = client;
fig.UserData.am4100 = am4100;
fig.UserData.logger = logger;

if strlength(options.RAW_DATA_ROOT) < 1
    raw_root = parameters('raw_data_folder_root');
else
    raw_root = options.RAW_DATA_ROOT;
end

L = uigridlayout(fig,[12,2],'BackgroundColor','k','ColumnWidth',{'1x','4x'});
lab = uilabel(L,"Text","SWEEP",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 1;
lab.Layout.Column = 1;
fig.UserData.SweepSpinBox = uispinner(L,  ...
    "RoundFractionalValues", "on", ...
    "Step", 1, ...
    "FontName","Consolas",...
    "Value",options.SWEEP);
fig.UserData.SweepSpinBox.Layout.Row = 1;
fig.UserData.SweepSpinBox.Layout.Column = 2;

lab = uilabel(L,"Text","BLOCK",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 2;
lab.Layout.Column = 1;
fig.UserData.BlockSpinBox = uispinner(L,  ...
    "RoundFractionalValues", "on", ...
    "Step", 1, ...
    "FontName","Consolas",...
    "Value",options.BLOCK);
fig.UserData.BlockSpinBox.Layout.Row = 2;
fig.UserData.BlockSpinBox.Layout.Column = 2;

lab = uilabel(L,"Text","CHANNEL",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 3;
lab.Layout.Column = 1;
fig.UserData.ChannelSpinBox = uispinner(L, ...
    "Limits",[1,8], ...
    "LowerLimitInclusive","on",...
    "UpperLimitInclusive","on",...
    "Step",1,...
    "RoundFractionalValues","on",...
    "FontName","Consolas",...
    "Value",options.STIM_CHANNEL);
fig.UserData.ChannelSpinBox.Layout.Row = 3;
fig.UserData.ChannelSpinBox.Layout.Column = 2;

lab = uilabel(L,"Text","RETURN",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 1;
fig.UserData.ReturnDropDown = uidropdown(L,  ...
    "FontName","Consolas",...
    "Items", ["X","L","R"], ...
    "Value",options.STIM_RETURN);
fig.UserData.ReturnDropDown.Layout.Row = 4;
fig.UserData.ReturnDropDown.Layout.Column = 2;

lab = uilabel(L,"Text","Amplitudes (μA)",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 1;
fig.UserData.IntensityEditField = uieditfield(L, 'text', ...
    "FontName","Consolas",...
    "Value",num2str(options.INTENSITIES));
fig.UserData.IntensityEditField.Layout.Row = 5;
fig.UserData.IntensityEditField.Layout.Column = 2;

lab = uilabel(L,"Text","Frequencies (Hz)",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 6;
lab.Layout.Column = 1;
fig.UserData.FrequencyEditField = uieditfield(L, 'text', ...
    "FontName","Consolas",...
    "Value",num2str(options.FREQUENCIES));
fig.UserData.FrequencyEditField.Layout.Row = 6;
fig.UserData.FrequencyEditField.Layout.Column = 2;

lab = uilabel(L,"Text","Duration (s)",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 7;
lab.Layout.Column = 1;
fig.UserData.BurstDurationEditField = uieditfield(L, 'numeric', ...
    "FontName","Consolas",...
    "Value",options.BURST_DURATION);
fig.UserData.BurstDurationEditField.Layout.Row = 7;
fig.UserData.BurstDurationEditField.Layout.Column = 2;

lab = uilabel(L,"Text","Repetitions",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 8;
lab.Layout.Column = 1;
fig.UserData.RepetitionsSpinBox = uispinner(L, ...
    "FontName","Consolas",...
    "Value",options.BURST_REPETITIONS, ...
    "LowerLimitInclusive","on",...
    "UpperLimitInclusive","on",...
    "Step",1,...
    "RoundFractionalValues","on",...
    "Limits",[1,20]);
fig.UserData.RepetitionsSpinBox.Layout.Row = 8;
fig.UserData.RepetitionsSpinBox.Layout.Column = 2;

lab = uilabel(L,"Text","Save Folder",'FontName','Tahoma','FontColor','w','HorizontalAlignment','right');
lab.Layout.Row = 9;
lab.Layout.Column = 1;
fig.UserData.SaveFolderEditField = uieditfield(L, 'text', ...
    "FontName","Consolas",...
    "Value",raw_root);
fig.UserData.SaveFolderEditField.Layout.Row = 9;
fig.UserData.SaveFolderEditField.Layout.Column = 2;

fig.UserData.RunButton = uibutton(L,"BackgroundColor",'r',"FontColor",'w',"FontWeight",'bold',"FontName","Tahoma","Text","RUN",'ButtonPushedFcn',@execute_stim_rec_sweep);
fig.UserData.RunButton.Layout.Row = 12;
fig.UserData.RunButton.Layout.Column = 2;

    function execute_stim_rec_sweep(src,~)
        u = src.Parent.Parent.UserData;
        u.client.UserData.sweep = u.SweepSpinBox.Value;
        u.client.UserData.block = u.BlockSpinBox.Value;
        iTxt = u.IntensityEditField.Value;
        iVal = eval(sprintf('[%s]',iTxt));
        fTxt = u.FrequencyEditField.Value;
        fVal = eval(sprintf('[%s]',fTxt));
        d = uiprogressdlg(src.Parent.Parent, ...
            'Title', "Running Stim Sweep...");
        T = runStimRecSweep(u.client, u.am4100, u.logger, ...
            'Channel', u.ChannelSpinBox.Value, ...
            'Return', u.ReturnDropDown.Value, ...
            'Intensity', iVal, ...
            'Frequency', fVal, ...
            'BurstDuration', u.BurstDurationEditField.Value, ...
            'NBursts', u.RepetitionsSpinBox.Value, ...
            'RawDataRoot', u.SaveFolderEditField.Value, ...
            'BlockUpdateHandle', u.BlockSpinBox, ...
            'ProgressDialogBar', d, ...
            'UDP', udpport());
        u.SweepSpinBox.Value = u.SweepSpinBox.Value + 1;
        u.BlockSpinBox.Value = 0;
        close(d);
        disp(T);
    end

end