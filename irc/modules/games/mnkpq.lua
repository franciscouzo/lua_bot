-- http://www.connect6.org/k-in-a-row.pdf

local utils = require("irc.utils")

local function whos_turn(game)
	local turn = game.turn - game.q
	local t = true
	while true do
		if turn <= 0 then
			return game.players[t and 1 or 2]
		end
		t = not t
		turn = turn - game.p
	end
end

local function show_board(irc, channel, game)
	local middle = math.ceil(game.n / 2)
	for i, line in ipairs(game.board) do
		irc:privmsg(channel, line .. ((middle == i) and (" it's " .. whos_turn(game) .. "'s turn") or ""))
	end
end

local function check_win(game, player)
	assert(
		player == "X" or player == "O" or
		player:match("%[%%%-[XO]%]") or player:match("%[[XO]%%%-%]"), -- for ties
		"Invalid player"
	)
	for x = 0, game.m - game.k do
		for y = 0, game.n - game.k do
			local diagonal1, diagonal2 = 0, 0
			for i = 1, game.k do
				local count1, count2 = 0, 0
				for j = 1, game.k do
					count1 = count1 + ((game.board[y + i]:sub(x + j, x + j):match(player)) and 1 or 0)
					count2 = count2 + ((game.board[y + j]:sub(x + i, x + i):match(player)) and 1 or 0)
				end
				if count1 == game.k or count2 == game.k then
					return true
				end
				
				diagonal1 = diagonal1 + ((game.board[y + i]:sub(y + i, y + i):match(player)) and 1 or 0)
				diagonal2 = diagonal2 + ((game.board[y + i]:sub(game.k - (x + i) + 1, game.k - (x + i) + 1):match(player)) and 1 or 0)
			end
			if diagonal1 == game.k or diagonal2 == game.k then
				return true
			end
		end
	end
	return false
end

local function check_tie(game)
	return not (check_win(game, "[%-X]") or check_win(game, "[%-O]"))
end

return function(irc)
	-- Connect(m, n, k, p, q)
	irc:add_command("mnkpq", "mnkpq_start", function(irc, state, channel, nick, gravity, m, n, k, p, q)
		channel = irc:lower(channel)
		local nick1 = irc:lower(state.nick)
		local nick2 = irc:lower(nick)

		assert(irc.channels[channel], "Invalid channel")
		assert(irc.channels[channel].users[nick1], "Invalid user")
		assert(irc.channels[channel].users[nick2], "Invalid user")
		assert(nick1 ~= nick2, "You can't play with yourself... Not here anyway")
		assert(nick2 ~= irc:lower(irc.nick), "You can't play with me")

		local games = irc.linda:get("mnkpq.games") or {}

		for _, game in ipairs(games) do
			if game.players[1] == nick1 or game.players[2] == nick1 then
				error("You're already playing")
			elseif game.players[1] == nick2 or game.players[2] == nick2 then
				error(irc.channels[channel].users[nick2] .. " is already playing")
			end
		end

		-- gravity: `connect four`-like or tictactoe-like
		-- m: width
		-- n: height
		-- k: stones in a row to win
		-- p: non-first's turn stones
		-- q: first turn's stones

		gravity = gravity and gravity >= 1 or false
		
		m = m or 3
		n = n or m

		assert(m >= 3 and m <= 7, "Invalid board width")
		assert(n >= 3 and n <= 7, "Invalid board height")

		k = k or math.min(m, n)
		assert(k >= 2, "You would win on your first turn...")
		assert(k <= m and k <= n, "k must be less than or equal to m and n")

		p = p or 1
		q = q or p

		assert(p >= 1, "First turn must be greater than one")
		assert(q >= 1, "non-first turn must be greater than one")

		assert(p < k, "Second player could win in first turn")
		assert(q < k, "First player could win in first turn")

		local board = {}
		for i = 1, n do
			board[i] = ("-"):rep(m)
		end
		local game = {
			players = math.random(2) == 1 and {nick1, nick2} or {nick2, nick1},
			board = board,
			turn = 1,
			channel = channel,

			gravity = gravity,
			m = m,
			n = n,
			k = k,
			p = p,
			q = q
		}

		table.insert(games, game)
		irc.linda:set("mnkpq.games", games)
		show_board(irc, channel, game)
	end, false, "string", "+int...")
	
	local function mnkpq(irc, state, channel, xy_list)
		local games = assert(irc.linda:get("mnkpq.games"), "No games taking place")
		local game, game_i
		local nick = irc:lower(state.nick)
		for i, g in ipairs(games) do
			if g.players[1] == nick or g.players[2] == nick then
				game = g
				game_i = i
				break
			end
		end
		
		assert(game, "You're not playing")
		assert(irc:lower(channel) == game.channel, "Invalid channel")

		local player = game.players[1] == whos_turn(game) and "O" or "X"
		for x_y in xy_list:gmatch("[^,]+") do
			assert(irc:lower(state.nick) == whos_turn(game), "It's not your turn")

			x_y = utils.strip(x_y)
			local x, y

			if game.gravity then
				x = assert(tonumber(x_y, "Invalid number"))
				assert(x >= 1 and x <= game.m, "Invalid number: range 1-" .. game.m)
				for _y = game.n, 1, -1 do
					if game.board[_y]:sub(x, x) == "-" then
						y = _y
						break
					end
				end
				assert(y, "Column is full")
			else
				x, y = x_y:match("^(%d+)%s+(%d+)$")
				x = assert(tonumber(x), "Invalid number")
				y = assert(tonumber(y), "Invalid number")
				assert(x >= 1 and x <= game.m, "Invalid number: range 1-" .. game.m)
				assert(y >= 1 and y <= game.n, "Invalid number: range 1-" .. game.n)
				assert(game.board[y]:sub(x, x) == "-", "That cell is already occupied")
			end

			game.board[y] = game.board[y]:sub(1, x - 1) .. player .. game.board[y]:sub(x + 1)
			game.turn = game.turn + 1
		end

		local ret
		if check_win(game, player) then
			table.remove(games, game_i)
			ret = state.nick .. " wins!"
		elseif check_tie(game) then
			table.remove(games, game_i)
			ret = "It's a tie"
		else
			show_board(irc, channel, game)
		end

		irc.linda:set("mnkpq.games", games)

		return ret
	end
	
	irc:add_hook("mnkpq", "on_cmd_privmsg", function(irc, state, channel, xy_list)
		msg = utils.strip(xy_list)
		for x_y in xy_list:gmatch("[^,]+") do
			x_y = utils.strip(x_y)
			if not (tonumber(x_y) or x_y:match("^(%d+)%s+(%d+)$")) then
				return
			end
		end
		local success, result = pcall(mnkpq, irc, state, channel, xy_list)
		if sucess then
			irc:privmsg(channel, result)
		end
	end)
	
	irc:add_command("mnkpq", "mnkpq", mnkpq, false)
	irc:add_command("mnkpq", "mnkpq_stop", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		nick = irc:lower(state.nick)

		assert(irc.channels[channel], "Invalid channel")

		local games = irc.linda:get("mnkpq.games")
		assert(games, "No games taking place")

		for i, game in ipairs(games) do
			if game.players[1] == nick or game.players[2] == nick then
				table.remove(games, i)
				irc.linda:set("mnkpq.games", games)
				local other = game.players[game.players[1] == nick and 2 or 1]
				return other .. " wins by default"
			end
		end
		error("You're not playing")
	end, false)
	irc:add_command("mnkpq", "ttt_start", function(irc, state, channel, nick)
		irc:run_command(state, channel, "mnkpq_start " .. nick)
	end, false)
	irc:add_command("mnkpq", "ttt", function(irc, state, channel, msg)
		return irc:run_command(state, channel, "mnkpq " .. msg)
	end, false)
	irc:add_command("mnkpq", "ttt_stop", function(irc, state, channel)
		return irc:run_command(state, channel, "mnkpq_stop")
	end, false)
end
