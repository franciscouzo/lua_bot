local socket = require("socket")
return function(irc)
	local forbidden_bots = {nickserv=true, chanserv=true, memoserv=true, botserv=true, gameserv=true, groupserv=true, q=true}
	local timeout = 30
	irc:add_command("communicate", "communicate", function(irc, state, channel, msg)
		local bots_nick, command = msg:match("^(.+) (.+)$")
		assert(bots_nick and command, "Insufficient arguments")
		bots_nick = irc:lower(bots_nick)
		assert(not forbidden_bots[bots_nick], "Forbidden bot")
		assert(not irc.linda:get("communicate." .. bots_nick), "This bot has a job running already")

		irc:privmsg(bots_nick, command)

		irc.linda:set("communicate." .. bots_nick, true)
		local key, response = irc.linda:receive(timeout, "communicate.response." .. bots_nick)
		assert(key and response, bots_nick .. " timeout")
		return response
	end, true)

	irc:add_hook("communicate", "on_cmd_privmsg", function(irc, state, channel, msg)
		local nick = irc:lower(state.nick)
		local communicate = irc.linda:receive(0, "communicate." .. nick)

		if communicate then
			irc.linda:set("communicate.response." .. nick, msg)
		end
	end, true)
end