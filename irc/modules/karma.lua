local utils = require("irc.utils")

return function(irc)
	local karma = {}
	local file = io.open("data/karma")
	if file then
		karma = utils.unpickle(file:read("*a"))
		file:close()
	end

	local function save_karma()
		os.rename("data/karma", "data/karma.backup")
		local file = assert(io.open("data/karma", "w"))
		file:write(utils.pickle(karma))
		file:close()
	end
	
	irc:add_hook("karma", "on_cmd_privmsg", function(irc, state, channel, msg)
		local nick, plus_or_minus = msg:sub(1, -3), msg:sub(-2)
		nick = irc:lower(nick)
		if nick == irc:lower(state.nick) then
			return
		end
		if plus_or_minus == "--" then
			karma[nick] = (karma[nick] or 0) - 1
			save_karma()
		elseif plus_or_minus == "++" then
			karma[nick] = (karma[nick] or 0) + 1
			save_karma()
		end
	end)
	irc:add_command("karma", "karma", function(irc, state, channel, msg)
		local nick = state.nick
		if utils.strip(msg) ~= "" then
			nick = utils.strip(msg)
		end
		nick = irc:lower(nick)
		return tostring(karma[nick] or 0)
	end, false)
end