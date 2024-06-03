function short_name = full_subj_name_2_short_name(full_name)
%FULL_SUBJ_NAME_2_SHORT_NAME Returns shortened version of full subject name
%
% Syntax:
%   short_name = full_subj_name_2_short_name(full_name);
%
% Inputs:
%   full_name {mustBeTextScalar} - Full subject name (e.g. 'Pilot_SCS_N_CEJ_02')
%
% Output:
%   short_name - e.g. For Pilot_SCS_N_CEJ_02 becomes "INTACT-02"
arguments
    full_name {mustBeTextScalar}
end

name_info= strsplit(full_name,'_');
if strcmpi(name_info{3},'N')
    short_name = strcat("INTACT-", name_info{end});
else
    short_name = strcat("LESION-", name_info{end});
end

end