local utils = require("irc.utils")

return function(irc)
	irc.linda:set("seen.seen", {})
	local file = io.open("data/seen")
	if file then
		irc.linda:set("seen.seen", utils.unpickle(file:read("*a")))
		file:close()
	end

	irc:add_hook("seen", "on_quit", function(irc)
		local file = io.open("data/seen", "w")
		if file then
			file:write(utils.pickle(irc.linda:get("seen.seen")))
			file:close()
		end
	end)
	
	irc:add_hook("seen", "on_cmd_privmsg", function(irc, state, channel, msg)
		local socket = require("socket")
		local seen = irc.linda:get("seen.seen")
		seen[irc:lower(state.nick)] = {at = socket.gettime(), msg = msg}
		irc.linda:set("seen.seen", seen)
	end)
	
	irc:add_command("seen", "seen", function(irc, state, channel, nick)
		local seen = irc.linda:get("seen.seen")
		nick = irc:lower(utils.strip(nick))
		local message = assert(seen[nick], "I've never seen " .. nick)

		local socket = require("socket")

		local ago = math.floor(socket.gettime() - message.at)
		local format_ago = irc:run_command(state, channel, "format_seconds " .. ago)
		ago = format_ago or (math.floor(ago) .. " second" .. (ago == 1 and "" or "s"))
		return ("I've seen %s, %s ago, saying: \"%s\""):format(nick, ago, message.msg)
	end, false)
end