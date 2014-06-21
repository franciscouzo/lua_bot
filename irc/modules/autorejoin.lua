return function(irc)
	irc:add_hook("autorejoin", "on_cmd_kick", function(irc, state, channel, nick, reason)
		if irc:lower(nick) == irc:lower(irc.nick) then
			require("socket").sleep(irc:get_config("autorejoin_time", channel) or 60)
			irc:join(channel)
		end
	end, true)
end