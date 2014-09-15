local utils = require("irc.utils")

return function(irc)
	irc:add_command("honeycomb", "honeycomb_start", function(irc, state, channel, ...)
		local players = {[irc:lower(state.nick)] = true}
		local order_players = {state.nick}
		
		channel = irc:lower(channel)

		local games = irc.linda:get("games.honeycomb.games." .. channel) or {}

		local chan = assert(irc.channels[channel], "Invalid channel")
		for _, player in ipairs({...}) do
			assert(chan.users[irc:lower(player)], player .. " is not in this channel")
			for _, game in ipairs(games) do
				assert(not game.players[irc:lower(player)], player .. " is already playing")
			end
			if not players[irc:lower(player)] then
				table.insert(order_players, player)
				players[irc:lower(player)] = true
			end
		end

		--assert(next(players, next(players)), "You can't play alone")
		-- little hack to check if there are atleast two keys in the table
		assert(#order_players >= 2, "You can't play alone")

		assert(not players[irc:lower(irc.nick)], "You can't play with me")

		order_players = utils.shuffled(order_players)
		local log = math.ceil(math.log(#order_players) / math.log(1.1))
		local stack = math.random(log, log * 2)
		local game = {
			order_players = order_players,
			turn = 1,
			players = players, -- to check if it's playing
			stack = stack
		}
		table.insert(games, game)
		irc.linda:set("games.honeycomb.games." .. channel, games)
		return ("Stack: %i, it's %s's turn"):format(stack, order_players[1])
	end, false, "string...")
	
	local function honeycomb(irc, state, channel, s)
		channel = irc:lower(channel)
		local games = irc.linda:get("games.honeycomb.games." .. channel)
		assert(games, "No games taking place")

		local nick = irc:lower(state.nick)

		local game, i
		for j, _game in ipairs(games) do
			if _game.players[nick] then
				game, i = _game, j
			end
		end

		if not game then
			error("You're not playing")
		end

		s = utils.strip(s)
		local n = assert(tonumber(s), "Invalid number")
		assert(n == 1 or n == 2, "Valid numbers: 1, 2")
		assert(irc:lower(game.order_players[game.turn]) == nick, "It's not your turn")
		game.stack = game.stack - n

		if game.stack <= 0 and #game.order_players == 2 then
			-- game finished
			table.remove(games, i)
			irc.linda:set("games.honeycomb.games." .. channel, games)
			table.remove(game.order_players, game.turn)
			return ("%s wins, %s loses"):format(game.order_players[1], state.nick)
		elseif game.stack <= 0 then
			game.players[nick] = nil
			table.remove(game.order_players, game.turn)
			local log = math.ceil(math.log(#game.order_players) / math.log(1.1))
			game.stack = math.random(log, log * 2)
			irc.linda:set("games.honeycomb.games." .. channel, games)
			return ("Stack: %i, %s's turn, %s loses"):format(game.stack, game.order_players[game.turn], state.nick)
		else
			game.turn = game.turn % #game.order_players + 1
			irc.linda:set("games.honeycomb.games." .. channel, games)
			return ("Stack: %i, %s's turn"):format(game.stack, game.order_players[game.turn])
		end
	end
	irc:add_hook("honeycomb", "on_cmd_privmsg", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		if msg == "1" or msg == "2" then
			local status, result = pcall(honeycomb, irc, state, channel, msg)
			if status then
				irc:privmsg(channel, result)
			end
		end
	end)
	irc:add_command("honeycomb", "honeycomb", honeycomb, false)
	
	irc:add_command("honeycomb", "honeycomb_stop", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local games = irc.linda:get("games.honeycomb.games." .. channel)
		assert(games, "No games taking place")

		local nick = irc:lower(state.nick)

		for i, game in ipairs(games) do
			if game.players[nick] then
				table.remove(games, i)
				irc.linda:set("games.honeycomb.games." .. channel, games)
				return
			end
		end

		if not game then
			error("You're not playing")
		end
	end, false)
end
