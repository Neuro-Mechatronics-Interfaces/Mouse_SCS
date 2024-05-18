function RELAYS_turnOffChannel(relay_pi, channel)
%RELAYS_TURNOFFCHANNEL  Turn specific relay channel OFF
arguments
    relay_pi
    channel (1,1) {mustBeMember(channel, 1:8)}
end

msg_out = sprintf("%d 0", channel);
if ~isempty(relay_pi.UserData.logger)
    relay_pi.UserData.logger.info(sprintf('%s 0',msg_out));
end
write(relay_pi, msg_out, relay_pi.UserData.address, relay_pi.UserData.port);

end