local utils = require("irc.utils")
return function(irc)
	irc:add_hook("fake_message", "on_cmd_privmsg", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		local response = irc.linda:get("fake_message.messages." .. irc:lower(state.nick) .. "." .. msg)
		if response then
			irc.linda:set("fake_message.messages." .. irc:lower(state.nick) .. "." .. msg, nil)
			irc:privmsg(channel, response)
		end
	end)
	irc:add_command("fake_message", "fake_message", function(irc, state, channel, msg)
		local msg, response = msg:match("^(.-)=(.+)$")
		assert(msg and response, "Insufficient arguments")
		msg, response = utils.strip(msg), utils.strip(response)
		irc.linda:set("fake_message.messages." .. irc:lower(state.nick) .. "." .. msg, response)
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)
end
