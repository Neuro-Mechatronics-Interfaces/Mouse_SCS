function log_relay_interaction(src, evt)
%LOG_RELAY_INTERACTION  Callback for UDP port interacting with relays.
sTime = string(evt.AbsoluteTime);
msg = readline(src);
if ~isempty(src.UserData.logger)
    src.UserData.logger.info(sprintf('%s %s\n',sTime, msg));
end

end