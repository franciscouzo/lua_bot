local utils = require("irc.utils")

return function(irc)
	local ayy = {}
	local file = io.open("data/ayy")
	if file then
		ayy = utils.unpickle(file:read("*a"))
		file:close()
	end

	local function save_ayy()
		os.rename("data/ayy", "data/ayy.backup")
		local file = assert(io.open("data/ayy", "w"))
		file:write(utils.pickle(ayy))
		file:close()
	end

	irc:add_command("ayy", "ayy_start", function(irc, state, channel, nick)
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		assert(not irc.linda:get("ayy." .. channel), "Another game taking place")

		irc.linda:set("ayy." .. channel, true)
		irc.linda:set("ayy.active." .. channel, false)

		irc:privmsg(channel, "ayy lmao!")

		local socket = require("socket")

		while irc.linda:get("ayy." .. channel) do
			socket.sleep(math.random(10 * 60, 45 * 60)) -- 10-45 minutes
			if not irc.linda:get("ayy.active." .. channel) then
				irc.linda:set("ayy.active." .. channel, true)
				irc:privmsg(channel, "ayy")
			end
		end
	end, true)

	irc:add_command("ayy", "ayy_stop", function(irc, state, channel, nick)
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		assert(irc.linda:get("ayy." .. channel), "No game taking place")

		irc.linda:set("ayy." .. channel, false)
		irc.linda:set("ayy.active." .. channel, false)

		return "ayy lmao :/"
	end, false)

	irc:add_command("ayy", "ayy", function(irc, state, channel, msg)
		local nick = state.nick
		if utils.strip(msg) ~= "" then
			nick = utils.strip(msg)
		end
		nick = irc:lower(nick)
		return tostring(ayy[nick] or 0)
	end, false)

	irc:add_hook("ayy", "on_cmd_privmsg", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		if not irc.linda:get("ayy.active." .. channel) or utils.strip(msg) ~= "lmao" then
			return
		end

		irc.linda:set("ayy.active." .. channel, false)

		local nick = irc:lower(state.nick)
		ayy[nick] = (ayy[nick] or 0) + 1

		save_ayy()

		irc:privmsg(channel, "ayy lmao!")
	end)
end
