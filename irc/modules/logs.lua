local function log(irc, state, channel, line)
	if not irc:get_config("log", channel) then
		return
	end
	channel = irc:lower(channel)
	channel = channel:gsub("[%.%/\\%z]", "_") -- channels can't have NUL in them, but just in case
	local file = io.open("logs/" .. channel .. ".log", "a")
	if not file then
		return
	end
	line = irc:strip_color(line)
	
	local time
	if state and state.tags and state.tags.time then
		local year, month, day, hour, minute, second, millisecond = state.tags.time:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)%.(%d+)Z")
		if year then
			time = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second})
		end
	end

	local date = os.date("%X", time)

	file:write("[" .. date .. "] " .. line .. "\n")
	file:close()
end

return function(irc)
	irc:add_hook("logs", "on_cmd_mode", function(irc, state, channel, ...)
		log(irc, state, channel, ("-!- %s sets mode %s"):format(state.nick or state.prefix, table.concat({...}, " ")))
	end)
	irc:add_hook("logs", "on_cmd_join", function(irc, state, channel)
		log(irc, state, channel, ("-!- %s has joined %s"):format(state.nick, channel))
	end)
	irc:add_hook("logs", "on_cmd_nick", function(irc, state, nick)
		for channel, channel_data in pairs(irc.channels) do
			if channel_data.users[irc:lower(nick)] then
				-- search for updated nick
				log(irc, state, channel, ("-!- %s changed his nick to %s"):format(state.nick, nick))
			end
		end
	end)
	irc:add_hook("logs", "on_cmd_part", function(irc, state, channel, msg)
		log(irc, state, channel, ("-!- %s has left %s (%s)"):format(state.nick, channel, msg or ""))
	end)
	irc:add_hook("logs", "on_cmd_kick", function(irc, state, channel, nick, reason)
		log(irc, state, channel, ("-!- %s was kicked by %s (%s)"):format(nick, state.nick or state.prefix, reason or ""))
	end)
	irc:add_hook("logs", "on_cmd", function(irc, cmd, state, channel, msg)
		if cmd == "QUIT" then
			-- use on_cmd instead of on_cmd_quit so we still have the user in irc.channels
			for channel, channel_data in pairs(irc.channels) do
				if channel_data.users[irc:lower(state.nick)] then
					log(irc, state, channel, ("-!- %s has quit (%s)"):format(state.nick, channel or "")) -- channel is msg
				end
			end
		elseif cmd == "PRIVMSG" then
			local ctcp_command, ctcp_msg = msg:match("^\001(.+) (.+)\001$")
			if ctcp_command and ctcp_msg then
				if ctcp_command == "ACTION" then
					log(irc, state, channel, ("* %s %s"):format(state.nick or state.prefix, ctcp_msg))
				end
			else
				log(irc, state, channel, ("<%s> %s"):format(state.nick or state.prefix, msg))
			end
		elseif cmd == "NOTICE" then
			log(irc, state, channel, ("-%s- %s"):format(state.nick or state.prefix, msg))
		end
	end)
	
	irc:add_hook("logs", "on_rpl_topic", function(irc, state, channel, topic)
		log(irc, state, channel, ("Topic for %s is %s"):format(channel, topic))
	end)
	irc:add_hook("logs", "on_cmd_topic", function(irc, state, channel, topic)
		log(irc, state, channel, ("-!- %s changed the topic to %s"):format(state.nick or state.prefix, topic))
	end)

	irc:add_hook("logs", "on_send_privmsg", function(irc, formatted, channel, msg)
		local ctcp_command, ctcp_msg = msg:match("^\001(.+) (.+)\001$")
		if ctcp_command and ctcp_msg then
			if ctcp_command == "ACTION" then
				log(irc, state, channel, ("* %s %s"):format(irc.nick, ctcp_msg))
			end
		else
			log(irc, nil, channel, ("<%s> %s"):format(irc.nick, msg))
		end
	end)
	irc:add_hook("logs", "on_send_notice", function(irc, formatted, channel, msg)
		log(irc, nil, channel, ("-%s- %s"):format(irc.nick, msg))
	end)
end