function RELAYS_turnOffAll(relay_pi)
%RELAYS_TURNOFFALL  Turn all relays OFF
arguments
    relay_pi
end

for channel = 1:8
    RELAYS_turnOffChannel(relay_pi, channel);
end

end