local utils = require("irc.utils")

return function(irc)
	local commands = {}
	local file = io.open("data/commands")
	if file then
		commands = utils.unpickle(file:read("*a"))
		for cmd, command in pairs(commands) do
			irc:add_command("user_commands", cmd, function(irc, state, channel, msg)
				return assert(irc:run_command(state, channel, command .. msg))
			end, true)
		end
		file:close()
	end

	irc:add_hook("commands", "on_quit", function(irc)
		local file = io.open("data/commands", "w")
		if file then
			file:write(utils.pickle(commands))
			file:close()
		end
	end)

	irc:add_command("commands", "add_cmd", function(irc, state, channel, msg)
		assert(not irc.threaded, "This command can't be run on threaded mode")
		local cmd, command = unpack(utils.split(msg, " ", 1))
		assert(cmd and command, "Insufficient parameters")
		-- add them to the user_commands module
		assert(irc:add_command("user_commands", cmd, function(irc, state, channel, msg)
			return assert(irc:run_command(state, channel, command .. msg))
		end, true))
		commands[cmd:lower()] = command
		irc:notice(state.nick, "ok " .. state.nick)
	end, false) -- not threaded

	irc:add_command("commands", "del_cmd", function(irc, state, channel, command)
		command = utils.strip(command)

		assert(not irc.threaded, "This command can't be run on threaded mode")
		assert(irc.commands[command], "Nonexistent command")
		assert(irc.commands[command].module == "user_commands", "Non-deletable command")
		assert(irc:del_command(command))
		commands[command:lower()] = nil
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("commands", "commands", function(irc, state, channel, msg)
		local module = utils.strip(msg)
		if module == "" then
			local modules = {}
			for module_name in pairs(irc.module_list) do
				table.insert(modules, module_name)
			end
			return utils.escape_list(modules)
		end
		assert(irc.module_list[module], "Nonexistent module")

		local commands = {}
		for _, command in pairs(irc.module_list[module]) do
			table.insert(commands, command)
		end
		return utils.escape_list(commands)
	end, false)

	local source = "https://github.com/franciscouzo/lua_bot/blob/master/"
	irc:add_command("commands", "cmd_info", function(irc, state, channel, command)
		command = utils.strip(command)
		assert(irc.commands[command], "Nonexistent command")

		local debug = require("debug")

		local info = debug.getinfo(irc.commands[command].func, "S")
		local module = irc.commands[command].module

		if info.source:sub(1, 1) == "@" then
			 local url = source .. info.source:sub(4) .. "#L" .. info.linedefined -- assumes relative directory
			 return ("%s -> %s | %s"):format(module, command, url)
		end

		return ("%s -> %s"):format(module, command)
	end, false)
end
