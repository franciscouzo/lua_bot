local function show_board(irc, channel, game)
	local middle = math.ceil(game.size / 2)
	for i, line in ipairs(game.board) do
		irc:privmsg(channel, line .. ((middle == i) and (" it's " .. game.players[game.turn] .. "'s turn") or ""))
	end
end

local function check_win(game, player)
	local diagonal1, diagonal2 = 0, 0
	for i = 1, game.size do
		local count1, count2 = 0, 0
		for j = 1, game.size do
			count1 = count1 + ((game.board[i]:sub(j, j) == player) and 1 or 0)
			count2 = count2 + ((game.board[j]:sub(i, i) == player) and 1 or 0)
		end
		if count1 == game.size or count2 == game.size then
			return true
		end
		local j = game.size + 1 - i
		diagonal1 = diagonal1 + ((game.board[i]:sub(i, i) == player) and 1 or 0)
		diagonal2 = diagonal2 + ((game.board[j]:sub(j, j) == player) and 1 or 0)
	end
	return diagonal1 == game.size or diagonal2 == game.size
end

local function check_tie(game)
	for i, line in ipairs(game.board) do
		if line:find("-", 1, true) then
			return false
		end
	end
	return true
end

return function(irc)
	irc:add_command("tictactoe", "ttt_start", function(irc, state, channel, nick, size)
		channel = irc:lower(channel)
		local nick1 = irc:lower(state.nick)
		local nick2 = irc:lower(nick)

		assert(irc.channels[channel], "Invalid channel")
		assert(irc.channels[channel].users[nick1], "Invalid user")
		assert(irc.channels[channel].users[nick2], "Invalid user")
		assert(nick1 ~= nick2, "You can't play with yourself... Not here anyway")
		assert(nick2 ~= irc:lower(irc.nick), "You can't play with me")

		local games = irc.linda:get("tictactoe.games") or {}

		for _, game in ipairs(games) do
			if game.players[1] == nick1 or game.players[2] == nick1 then
				error("You're already playing")
			elseif game.players[1] == nick2 or game.players[2] == nick2 then
				error(irc.channels[channel].users[nick2] .. " is already playing")
			end
		end

		size = size or 3
		assert(size >= 3 and size <= 7, "Invalid board size")

		local board = {}
		for i = 1, size do
			board[i] = ("-"):rep(size)
		end
		local game = {
			players = math.random(2) == 1 and {nick1, nick2} or {nick2, nick1},
			board = board,
			turn = 1,
			size = size,
			channel = channel
		}

		table.insert(games, game)
		irc.linda:set("tictactoe.games", games)
		show_board(irc, channel, game)
	end, false, "string", "+int...")
	irc:add_command("tictactoe", "ttt", function(irc, state, channel, x, y)
		local games = assert(irc.linda:get("tictactoe.games"), "No games taking place")
		local game, game_i
		local nick = irc:lower(state.nick)
		for i, g in ipairs(games) do
			if g.players[1] == nick or g.players[2] == nick then
				game = g
				game_i = i
				break
			end
		end
		if not game then
			error("You're not playing")
		end

		assert(irc:lower(state.nick) == game.players[game.turn], "It's not your turn")
		assert(irc:lower(channel) == game.channel, "Invalid channel")
		assert(x >= 1 and x <= game.size, "Invalid number: range 1-" .. game.size)
		assert(y >= 1 and y <= game.size, "Invalid number: range 1-" .. game.size)
		assert(game.board[y]:sub(x, x) == "-", "That cell is already occupied")

		local player = game.turn == 1 and "O" or "X"
		game.board[y] = game.board[y]:sub(1, x - 1) .. player .. game.board[y]:sub(x + 1)

		local ret
		if check_win(game, player) then
			table.remove(games, game_i)
			ret = state.nick .. " wins!"
		elseif check_tie(game) then
			table.remove(games, game_i)
			ret = "It's a tie"
		else
			game.turn = game.turn == 1 and 2 or 1
			show_board(irc, channel, game)
		end

		irc.linda:set("tictactoe.games", games)

		return ret
	end, false, "+int", "+int")
end