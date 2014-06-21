local utils = require("irc.utils")

return function(irc)
	irc.linda:set("tell.tell", {})
	local file = io.open("data/tell")
	if file then
		irc.linda:set("tell.tell", utils.unpickle(file:read("*a")))
		file:close()
	end

	irc:add_hook("tell", "on_quit", function(irc)
		local file = io.open("data/tell", "w")
		if file then
			file:write(utils.pickle(irc.linda:get("tell.tell")))
			file:close()
		end
	end)

	local function tell_message(irc, state, channel)
		local nick = irc:lower(state.nick)
		local tell = irc.linda:get("tell.tell")
		if not tell[nick] then
			return
		end
		local socket = require("socket")
		for i, message in ipairs(tell[nick]) do
			local ago = math.floor(socket.gettime() - message.at) -- milliseconds look ugly
			local format_ago = irc:run_command(state, channel, "format_seconds " .. ago)
			ago = format_ago or (math.floor(ago) .. " second" .. (ago == 1 and "" or "s"))
			irc:notice(nick, ("%s said: \"%s\" %s ago"):format(message.by, message.msg, ago))
		end
		tell[nick] = nil
		irc.linda:set("tell.tell", tell)
	end
	
	irc:add_hook("tell", "on_cmd_join", tell_message)
	irc:add_hook("tell", "on_cmd_privmsg", tell_message)
	
	irc:add_command("tell", "tell", function(irc, state, channel, msg)
		local nick, msg = msg:match("^(.-) (.+)$")
		assert(nick and msg, "Insufficient arguments")
		nick = irc:lower(nick)
		local tell = irc.linda:get("tell.tell")
		if not tell[nick] then
			tell[nick] = {}
		end
		local socket = require("socket")
		table.insert(tell[nick], {by=state.nick, msg=msg, at=socket.gettime()})
		irc.linda:set("tell.tell", tell)
	end, false)
end