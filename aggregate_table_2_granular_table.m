function T = aggregate_table_2_granular_table(S, options)
%AGGREGATE_TABLE_2_GRANULAR_TABLE Converts aggregate cross-sweep response table to granular table breakdown by channel, repetition.

arguments
    S
    options.Verbose (1,1) logical = true;
end

T = [];

M = S.Properties.UserData.Muscle;
if options.Verbose
    fprintf(1,'Please wait, exporting granular table...000%%\n');
end
for ii = 1:size(S,1)
    s = S(ii,["sweep","block","channel","return_channel","intensity","frequency","pulse_width","n_pulses","is_monophasic","is_cathodal_leading","short_name"]);
    data = S.Response_Curve_Value_By_Channel{ii};
    nRep = size(data,2);
    for iCh = 1:numel(M)
        s.Muscle = M(iCh);
        for iRep = 1:nRep
            s.Train = ceil(iRep / s.n_pulses);
            s.Train_Pulse_Index = rem(iRep-1,s.n_pulses)+1;
            s.Overall_Pulse_Index = iRep;
            s.Response = data(iCh,iRep);
            T = [T; s]; %#ok<AGROW>
        end
    end
    if options.Verbose
        fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*ii/size(S,1)));
    end
end
T.Subject = repmat(S.Properties.UserData.Subject, size(T,1),1);
T = movevars(T,"Subject",'before','sweep');
T.Date = repmat(datetime(S.Properties.UserData.Year, S.Properties.UserData.Month, S.Properties.UserData.Day), size(T,1),1);
T = movevars(T,"Date",'before','sweep');
end