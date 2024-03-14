function [channel_str, channel_id, channel_type] = saga_channel_2_str_id(channel, options)
%SAGA_CHANNE_2_STR_ID  Convert SAGA samples row index into relative ID and string identifier
%
% Syntax:
%   [channel_str, channel_id, channel_type] = saga_channel_2_str_id(channel, 'Name', value, ...);
%
% Example 1- Get ID for channel 67 (a Bipolar) on Frank SAGA-B:
%   [channel_str, channel_id, channel_type] = saga_channel_2_str_id(67, 'Subject', 'Frank', 'Saga', 'B');
%   assert(channel_type == "BIP");
%   assert(channel_id == 2);
%   assert(channel_str == "DELT_m"; % See parameters.m for specifics
%
% Example 2- Get ID for channel 36 (a Textile) on Frank SAGA-B:
%   [channel_str, channel_id, channel_type] = saga_channel_2_str_id(36, 'Subject', 'Frank', 'Saga', 'B');
%   assert(channel_type == "UNI-Tex");
%   assert(channel_id == 3);
%   assert(channel_str == "Tex-B2-03");
%
% Inputs:       
%   channel - 1-indexed row index into saga.samples data array.
%
% Options:
%   Subject - Name of subject
%   Saga - ["A" or "B"]
%   ChannelRange - Structure with fields 'Frank' (for Frank ranges) and 
%                         'BabyYoda' (for Baby Yoda layout). Each has 
%                          sub-field 'A' and 'B' to refer to SAGA. Each
%                          sub-sub-field has two-element vectors as the
%                          min/max channel index associated with each 
%                          field name: 'UNI', 'BIP', and 'ACC'
%   BipolarLayout - Structure with fields 'Frank' (for Frank layout) and
%                       'BabyYoda' (for Baby Yoda layout). Each has
%                       sub-field 'A' and 'B' to refer to SAGA
%   
%
% See also: Contents

arguments
    channel
    options.Subject {mustBeTextScalar, mustBeMember(options.Subject, ["Frank", "BabyYoda"])} = "Frank";
    options.Saga {mustBeTextScalar, mustBeMember(options.Saga, ["A", "B"])} = "A";
    options.ChannelRange (1,1) struct = struct('Frank', parameters('frank_saga_channel_ranges'), ...
                                               'BabyYoda', parameters('babyyoda_saga_channel_ranges'));
    options.UnipolarLayout (1,1) struct = struct('Frank', parameters('frank_unipolar_layout'), ...
                                                'BabyYoda', parameters('babyyoda_unipolar_layout'));
    options.BipolarLayout (1,1) struct  = struct('Frank', parameters('frank_bipolar_layout'), ...
                                               'BabyYoda', parameters('babyyoda_bipolar_layout'));
end 

uni_layout = options.UnipolarLayout.(options.Subject).(options.Saga);
bip_layout = options.BipolarLayout.(options.Subject).(options.Saga);
channel_range = options.ChannelRange.(options.Subject).(options.Saga);

switch channel
    case num2cell(channel_range.UNI(1):channel_range.UNI(2))
        channel_id = channel - channel_range.UNI(1) + 1;
        channel_type = sprintf("UNI-%s", uni_layout);
        if strcmp(uni_layout, "Tex")
            grid_num = ceil(channel_id/32);
            channel_str = sprintf("%s-%s%d-%02d", uni_layout, options.Saga, grid_num, channel_id);
        else
            channel_str = sprintf("%s-%s-%02d", uni_layout, options.Saga, channel_id);
        end
    case num2cell(channel_range.BIP(1):channel_range.BIP(2))
        channel_id = channel - channel_range.BIP(1) + 1;
        channel_type = "BIP";
        channel_str = sprintf("%s_%s-%02d-%s", channel_type, options.Saga, channel_id, bip_layout(channel_id));
        
    case num2cell(channel_range.ACC(1):channel_range.ACC(2))
        channel_id = channel - channel_range.ACC(1) + 1;
        channel_type = "ACC";
        channel_str = sprintf("%s_%s-%02d", channel_type, options.Saga, channel_id);
end

end