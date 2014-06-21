return function(irc)
	irc:add_hook("module_management", "on_user_cmd", function(irc, command, state, channel, ...)
		local whitelist = irc:get_config("whitelist", channel) or {}
		local blacklist = irc:get_config("blacklist", channel) or {}
		if #whitelist >= 1 and #blacklist >= 1 then
			print("There's both whitelist and blacklist on channel " .. channel)
			return
		end
		if not irc.commands[command] then
			return
		end
		local module = irc.commands[command].module
		if #whitelist >= 1 then
			for _, whitelisted in ipairs(whitelist) do
				if module == whitelisted then
					return nil
				end
			end
			return true
		elseif #blacklist >= 1 then
			for _, blacklisted in ipairs(blacklist) do
				if module == blacklisted then
					return true
				end
			end
		end
	end)
end