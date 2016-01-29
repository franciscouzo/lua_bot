local glob = require("glob")
local utils = require("irc.utils")

return function(irc)
	local ignoring = {}
	local file = io.open("data/ignoring")
	if file then
		ignoring = utils.unpickle(file:read("*a"))
		file:close()
	end

	local function save_ignoring()
		os.rename("data/ignoring", "data/ignoring.backup")
		local file = assert(io.open("data/ignoring", "w"))
		file:write(utils.pickle(ignoring))
		file:close()
	end

	irc:add_command("ignore", "ignore", function(irc, state, channel, mask)
		assert(mask:match(".+!.+@.+"), "Invalid mask")
		local pattern = glob.globtopattern(mask)
		ignoring[mask] = pattern
		save_ignoring()
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("ignore", "unignore", function(irc, state, channel, mask)
		assert(ignoring[mask], "Unknown mask")
		assert(mask:match(".+!.+@.+"), "Invalid mask")
		ignoring[mask] = nil
		save_ignoring()
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("ignore", "ignore_list", function(irc, state, channel)
		local l = {}
		for mask in pairs(ignoring) do
			table.insert(l, mask)
		end
		return utils.escape_list(l)
	end, false)

	irc:add_hook("ignore", "on_cmd_privmsg", function(irc, state, channel, msg)
		if irc:admin_user_mode(state.nick, "v") then
			return
		end
		for _, ignore_pattern in pairs(ignoring) do
			if state.prefix:match(ignore_pattern) then
				return true
			end
		end
	end, false, 1)
end