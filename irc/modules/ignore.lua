local glob = require("glob")
local utils = require("irc.utils")

return function(irc)
	local ignoring = {}
	local file = io.open("data/ignoring")
	if file then
		ignoring = utils.unpickle(file:read("*a"))
		file:close()
	end

	irc:add_hook("ignore", "on_quit", function(irc)
		local file = io.open("data/ignoring", "w")
		if file then
			file:write(utils.pickle(ignoring))
			file:close()
		end
	end)

	irc:add_command("ignore", "ignore", function(irc, state, channel, mask)
		assert(mask:match(".+!.+@.+"), "Invalid mask")
		local pattern = glob.globtopattern(mask)
		ignoring[pattern] = true
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("ignore", "unignore", function(irc, state, channel, mask)
		assert(mask:match(".+!.+@.+"), "Invalid mask")
		local pattern = glob.globtopattern(mask)
		ignoring[pattern] = nil
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("ignore", "ignore_list", function(irc, state, channel)
		local l = {}
		for ignore_pattern in pairs(ignoring) do
			table.insert(l, ignore_pattern)
		end
		return utils.escape_list(l)
	end, false)
	
	irc:add_hook("ignore", "on_cmd_privmsg", function(irc, state, channel, msg)
		if irc:admin_user_mode(state.nick, "v") then
			return
		end
		for ignore_pattern in pairs(ignoring) do
			if state.prefix:match(ignore_pattern) then
				return true
			end
		end
	end, false, 1)
end