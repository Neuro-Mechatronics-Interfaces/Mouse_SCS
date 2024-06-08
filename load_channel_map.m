function [muscle, channel_index] = load_channel_map(fname)
%LOAD_CHANNEL_MAP Returns channel map of mouse muscles.
arguments
    fname {mustBeTextScalar} = "Default_Mouse_EMG_Channel_Map.txt";
end
fid = fopen(fname,'r');
s = textscan(fid,'%s','Delimiter','\n');
muscle = string(s{1});
fclose(fid);
channel_index = (1:16)';
if numel(muscle) < 16
    muscle = [muscle; repmat("NONE",16-numel(muscle),1)];
end
i_remove = strcmpi(muscle,"NONE");
channel_index(i_remove) = [];
% muscle(i_remove) = [];
end