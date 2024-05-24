function muscle = load_channel_map(fname)
%LOAD_CHANNEL_MAP Returns channel map of mouse muscles.
arguments
    fname {mustBeTextScalar} = "Default_Mouse_EMG_Channel_Map.txt";
end
fid = fopen(fname,'r');
s = textscan(fid,'%s','Delimiter','\n');
muscle = string(s{1});
fclose(fid);
end