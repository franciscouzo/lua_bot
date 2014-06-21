return function(irc)
	irc:add_hook("output_command", "on_send_privmsg", function(irc, state, channel, msg)
		local output_command = irc:get_config("output_command", channel)
		if output_command then
			local ret = irc:run_command(state, channel, output_command .. " " .. msg)
			table.insert(irc.queue, irc:format_msg("PRIVMSG", channel, ret))
			-- not using :privmsg to avoid calling its hook
			return true
		end
	end, true)
end