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
	end, false) -- not threaded
	
	irc:add_command("commands", "del_cmd", function(irc, state, channel, command)
		assert(not irc.threaded, "This command can't be run on threaded mode")
		assert(irc.commands[command], "Nonexistent command")
		assert(irc.commands[command].module == "user_commands", "Non-deletable command")
		assert(irc:del_command(command))
		commands[command:lower()] = nil
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
end