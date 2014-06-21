local utils = require("irc.utils")

return function(irc)
	irc:add_command("gundraw", "gundraw", function(irc, state, channel, nick)
		channel = irc:lower(channel)
		nick = irc:lower(utils.strip(nick))
		assert(irc.channels[channel], "Invalid channel")
		assert(irc.channels[channel].users[nick], "Invalid nick")
		assert(nick ~= irc:lower(irc.nick), "Go get someone else to play with...")
		assert(not irc.linda:get("gundraw.games." .. channel), "Another game taking place")

		local socket = require("socket")
		local in_seconds = (math.random() + 1) * 2.5 + (math.random() + 1) * 2.5

		irc.linda:set("gundraw.games." .. channel, {
			players = {irc:lower(state.nick), nick},
			at = socket.gettime() + in_seconds
		})
		irc:privmsg(channel, "When I say draw! you type \"draw!\"")
		socket.sleep(in_seconds)
		if irc.linda:get("gundraw.games." .. channel) then
			irc:privmsg(channel, "draw")
		else
			socket.sleep(5)
			local game = irc.linda:set("gundraw.games." .. channel, nil)
		end
	end, true)
	irc:add_hook("gundraw", "on_cmd_privmsg", function(irc, state, channel, msg)
		if irc:lower(utils.strip(msg)) ~= "draw!" then
			return
		end

		local channel = irc:lower(channel)
		local game = irc.linda:get("gundraw.games." .. channel)
		if not game then
			return
		end

		if not (irc:lower(state.nick) == game.players[1] or
		        irc:lower(state.nick) == game.players[2]) then
			return
		end

		local socket = require("socket")
		if socket.gettime() >= game.at then
			local other = game.players[irc:lower(state.nick) == game.players[1] and 2 or 1]
			irc:privmsg(channel, ("%s dies! %s is victorious"):format(other, state.nick))
		else
			irc:privmsg(channel, state.nick .. " loses, because I did not say draw!")
		end
		irc.linda:set("gundraw.games." .. channel, nil)
	end)
end