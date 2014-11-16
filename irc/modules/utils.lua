local utils = require("irc.utils")

return function(irc)
	irc:add_command("utils", "users", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		local users = {}
		for _, user in pairs(irc.channels[channel].users) do
			table.insert(users, user.nick)
		end
		return utils.escape_list(users)
	end, false)
	irc:add_command("utils", "tochannel", function(irc, state, channel, msg)
		local chan, msg = unpack(utils.split(msg, " ", 1))
		assert(chan and msg, "Insufficient arguments")
		irc:privmsg(chan, irc:run_command(state, channel, msg))
	end, true)
	irc:add_command("utils", "aschannel", function(irc, state, channel, msg)
		local chan, msg = unpack(utils.split(msg, " ", 1))
		assert(chan and msg, "Insufficient arguments")
		return irc:run_command(state, chan, msg)
	end, true)
	irc:add_command("utils", "runas", function(irc, state, channel, msg)
		local nick, msg = unpack(utils.split(msg, " ", 1))
		assert(nick and msg, "Insufficient arguments")
		state.nick = nick
		return irc:run_command(state, channel, msg)
	end, true)
	irc:add_command("utils", "clear_buffer", function(irc, state, channel, msg)
		assert(not irc.threaded, "This command can't be run on threaded mode")
		irc.queue = {}
	end, false)
	irc:add_command("utils", "raw", function(irc, state, channel, msg)
		irc:send(msg)
	end, false)
	irc:add_command("utils", "lag", function(irc, state, channel, msg)
		return tostring(irc.lag)
	end, false)
	irc:add_command("utils", "join", function(irc, state, channel, msg)
		local channels, keys = unpack(utils.split(msg, " ", 1))
		assert(irc:join(channels, keys))
	end, false)
	irc:add_command("utils", "rejoin", function(irc, state, channel, msg)
		assert(irc.channels[irc:lower(channel)], "Invalid channel")
		irc:send("PART", channel)
		irc:send("JOIN", channel)
	end, false)
	irc:add_hook("utils", "on_cmd_invite", function(irc, state, nick, channel)
		if irc:admin_user_mode(state.nick, "o") then
			irc:join(channel)
		end
	end)
	irc:add_command("utils", "part", function(irc, state, channel, msg)
		local channels = {}
		if utils.strip(msg) == "" then
			channels = {channel}
		else
			for channel in msg:gmatch("[^ ,]+") do
				assert(irc.channels[irc:lower(channel)], "Can't part a channel I'm not in (" .. channel .. ")")
				table.insert(channels, channel)
			end
			assert(#channels >= 1, "Empty channel list")
		end
		irc:send("PART", table.concat(channels, ","))
	end, false)
	irc:add_command("utils", "change_nick", function(irc, state, channel, nick)
		irc:send("NICK", nick)
	end, false)
	irc:add_command("utils", "change_topic", function(irc, state, channel, topic)
		irc:send("TOPIC", channel, topic)
	end, false)
	--[[irc:add_command("utils", "reload", function(irc, state, channel, module)
		assert(not irc.threaded, "This command can't be run on threaded mode")

		local add_hook = irc.add_hook
		local add_command = irc.add_command

		function irc:add_hook(hook, hook_name, ...)
			self:del_command(hook, hook_name)
			self:add_command(hook, hook_name, ...)
		end
		function irc:add_command(module, command, ...)
			irc:del_command(command)
			irc:add_command(module, command, ...)
		end

		assert(package.loaded[module_name], "Inexistent module or is not loaded")
		package.loaded[module_name] = nil

		local success, module = pcall(require, "irc.modules." .. module_name)
		assert(success, "Module " .. module_name .. " not found")
		assert(type(module) == "function", "module must return a function (" .. module_name .. ")")
		module(irc)

		irc.add_hook = add_hook
		irc.add_command = add_command
	end, false)]]
	irc:add_command("utils", "reload_config", function(irc, state, channel, config_name)
		assert(not irc.threaded, "This command can't be run on threaded mode")
		config_name = config_name ~= "" and config_name or arg[1]
		irc.config = dofile(config_name)
	end, false)
	
	local function multimode_format(plus_or_minus, mode, n, users)
		plus_or_minus = plus_or_minus and "+" or "-"
		
		local result = {}
		for i, block in ipairs(utils.blocks(users, n)) do
			result[i] = plus_or_minus .. mode:rep(#block) .. " " .. table.concat(block, " ")
		end
		return result
	end
	
	local modes = {
		op      = {true,  "o"},
		deop    = {false, "o"},
		voice   = {true,  "v"},
		devoice = {false, "v"}
	}
	
	for cmd, mode in pairs(modes) do
		irc:add_command("utils", cmd, function(irc, state, channel, ...)
			channel = irc:lower(channel)
			assert(irc.channels[channel], "Invalid channel")

			local users = {}
			local invalid_users = {}

			if select("#", ...) == 0 then
				table.insert(users, state.nick)
			end
			for i, user in ipairs({...}) do
				user = irc:lower(user)
				if irc:user_mode(channel, user, mode[2]) ~= mode[1] and irc:lower(user) ~= irc:lower(irc.nick) then
					table.insert(irc.channels[channel].users[user] and users or invalid_users, user)
				end
			end

			local modes = multimode_format(mode[1], mode[2], irc.isupport.MODES, users)
			for i, mode in ipairs(modes) do
				irc:send("MODE " .. channel .. " " .. mode)
			end

			if #invalid_users >= 1 then
				error(("Invalid user%s: %s"):format(#invalid_users == 1 and "" or "s", table.concat(invalid_users, ", ")))
			end
		end, false, "string...")
		irc:add_command("utils", cmd .. "all", function(irc, state, channel, msg)
			channel = irc:lower(channel)
			assert(irc.channels[channel], "Invalid channel")

			local users = {}
			for user in pairs(irc.channels[channel].users) do
				if irc:user_mode(channel, user, mode[2]) ~= mode[1] and irc:lower(user) ~= irc:lower(irc.nick) then
					table.insert(users, user)
				end
			end
			local modes = multimode_format(mode[1], mode[2], irc.isupport.MODES, users)
			for i, mode in ipairs(modes) do
				irc:send("MODE " .. channel .. " " .. mode)
			end
		end, false)
	end
	
	irc:add_command("utils", "kick", function(irc, state, channel, args)
		channel = irc:lower(channel)
		local nick, reason = unpack(utils.split(args, " ", 1))
		nick = irc:lower(nick)
		assert(irc.channels[channel], "Invalid channel")
		assert(irc.channels[channel].users[nick], "Invalid nick")
		assert(nick ~= irc:lower(irc.nick), "Haha... No!")
		irc:send("KICK", channel, nick, reason)
	end, false)
	irc:add_command("utils", "kickall", function(irc, state, channel, reason)
		assert(irc.channels[irc:lower(channel)], "Invalid channel")
		for user in pairs(irc.channels[irc:lower(channel)].users) do
			if user ~= irc:lower(irc.nick) then
				irc:send("KICK", channel, user, reason)
			end
		end
	end, false)
end
