return function(irc)
	irc:add_hook("shutup", "on_send_privmsg", function(irc, line, channel, msg)
		channel = irc:lower(channel)
		local shutup = irc.linda:get("shutup.shutup." .. channel)
		if not shutup then
			return
		end

		local socket = require("socket")
		if shutup - socket.gettime() < 0 then
			irc.linda:set("shutup.shutup." .. channel, nil)
			return
		end
		return true
	end)
	
	irc:add_command("shutup", "shut", function(irc, state, channel, msg, seconds)
		if msg ~= "up" then
			return
		end
		local socket = require("socket")

		channel = irc:lower(channel)
		seconds = seconds or (irc:get_config("shutup_time", channel) or 180)
		irc.linda:set("shutup.shutup." .. channel, socket.gettime() + seconds)
	end, false, "string", "+float...")
end