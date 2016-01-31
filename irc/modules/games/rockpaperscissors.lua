local utils = require("irc.utils")

return function(irc)
	irc:add_command("rps", "rps_start", function(irc, state, channel, nick, gravity, m, n, k, p, q)
		channel = irc:lower(channel)
		local nick1 = irc:lower(state.nick)
		local nick2 = irc:lower(nick)

		assert(irc.channels[channel], "Invalid channel")
		assert(irc.channels[channel].users[nick1], "Invalid user")
		assert(irc.channels[channel].users[nick2], "Invalid user")
		assert(nick1 ~= nick2, "You can't play with yourself... Not here anyway")
		assert(nick2 ~= irc:lower(irc.nick), "You can't play with me!")

		local games = irc.linda:get("rps.games") or {}

		for _, game in ipairs(games) do
			if game.players[1] == nick1 or game.players[2] == nick1 then
				error("You're already playing")
			elseif game.players[1] == nick2 or game.players[2] == nick2 then
				error(nick2 .. " is already playing")
			end
		end

		local game = {
			players = {nick1, nick2},
			channel = channel
		}

		table.insert(games, game)
		irc.linda:set("rps.games", games)

		return "Starting rock paper scissors game"
	end, false, "string")

	local function rps(irc, state, channel, msg)
		local games = assert(irc.linda:get("rps.games"), "No games taking place")
		local game, game_i
		local nick = irc:lower(state.nick)
		msg = utils.strip(msg):lower()
		for i, g in ipairs(games) do
			if g.players[1] == nick or g.players[2] == nick then
				game = g
				game_i = i
				break
			end
		end

		if msg ~= "rock" and msg ~= "paper" and msg ~= "scissors" then
			error("rock/paper/scissors")
		end

		assert(game, "You're not playing")

		if game.players[1] == nick then
			game.player1_move = msg
		else
			game.player2_move = msg
		end

		local ret

		if game.player1_move and game.player2_move then
			if game.player1_move == "rock" and game.player2_move == "rock" then
				ret = "It's a tie!"
			elseif game.player1_move == "rock" and game.player2_move == "paper" then
				ret = game.players[2] .. " wins!"
			elseif game.player1_move == "rock" and game.player2_move == "scissors" then
				ret = game.players[1] .. " wins!"
			elseif game.player1_move == "paper" and game.player2_move == "rock" then
				ret = game.players[1] .. " wins!"
			elseif game.player1_move == "paper" and game.player2_move == "paper" then
				ret = "It's a tie!"
			elseif game.player1_move == "paper" and game.player2_move == "scissors" then
				ret = game.players[2] .. " wins!"
			elseif game.player1_move == "scissors" and game.player2_move == "rock" then
				ret = game.players[2] .. " wins!"
			elseif game.player1_move == "scissors" and game.player2_move == "paper" then
				ret = game.players[1] .. " wins!"
			elseif game.player1_move == "scissors" and game.player2_move == "scissors" then
				ret = "It's a tie!"
			end

			table.remove(games, game_i)
		end

		irc.linda:set("rps.games", games)

		irc:privmsg(game.channel, ret)
	end

	irc:add_hook("rps", "on_cmd_privmsg", function(irc, state, channel, msg)
		msg = utils.strip(msg):lower()
		if msg == "rock" or msg == "paper" or msg == "scissors" then
			local success, result = pcall(rps, irc, state, channel, msg)
			if success then
				irc:privmsg(channel, result)
			end
		end
	end)

	irc:add_command("rps", "rps", rps, false)
end
