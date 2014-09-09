-- http://www.vidarholen.net/~vidar/generatemaze.py

return function(irc)
	irc:add_command("maze", "maze", function(irc, state, channel, width, height, rounded)
		assert(width  >= 5 and width  <= 80, "invalid width")
		assert(height >= 5 and height <= 30, "invalid height")

		rounded = rounded and rounded >= 1 or false

		local map = {}
		for i = 1, width do
			local n = {}
			for j = 1, height do
				n[j] = {right=true, bottom=true, captured=false, backtrack=0}
				--n[j] = {1, 1, 0, 0, 0} -- right, bottom, captured, backtrack, color
			end
			table.insert(map, n)
		end

		for y = 1, height do
			map[1][y]     = {right=true, bottom=false, captured=true, backtrack=0}
			map[width][y] = {right=true, bottom=false, captured=true, backtrack=0}
		end

		for x = 1, width do
			map[x][1]      = {right=false, bottom=true, captured=true, backtrack=0}
			map[x][height] = {right=false, bottom=true, captured=true, backtrack=0}
		end

		map[1][1]     = {right=false, bottom=false, captured=true, backtrack=0}
		map[width][1] = {right=false, bottom=false, captured=true, backtrack=0}

		local playerstart = {2, 2}
		local playerexit  = {width, height}

		local x, y = unpack(playerstart)
		local backtrack = 1
		local captures = 0
		local solutiontrack = 0

		while true do
			if playerexit[1] == x and playerexit[2] == y then
				solutiontrack = backtrack
			end

			if solutiontrack > 0 and solutiontrack == map[x][y].backtrack then
				solutiontrack = solutiontrack - 1
			end

			print(map[x], x, y)
			print(map[x][y])
			print(map[x][y].captured)
			if not map[x][y].captured then
				map[x][y].captured = true
				captures = captures + 1
			end

			map[x][y].backtrack = backtrack
			local possibilities = {}
			for i, a_b in ipairs{{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}} do
				local a, b = unpack(a_b)
				if a > 0 and a <= width and b > 0 and b <= height then
					if not map[a][b].captured then
						possibilities[#possibilities + 1] = {a, b}
					end
				end
			end

			if #possibilities == 0 then
				map[x][y].backtrack = 0
				backtrack = backtrack - 1
				if backtrack == 0 then
					break
				end
				for i, a_b in ipairs{{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}, {0, 0}} do
					local a, b = unpack(a_b)
					if a > 0 and a <= width and b > 0 and b <= height then
						if map[a][b].backtrack == backtrack then
							x = a
							y = b
							break
						end
					end
				end
			else
				local pos = math.random(1, #possibilities)
				local a, b = unpack(possibilities[pos])
				if a < x then map[a][b].right = false end
				if a > x then map[x][y].right = false end
				if b < y then map[a][b].bottom = false end
				if b > y then map[x][y].bottom = false end
				x = a
				y = b
				backtrack = backtrack + 1
			end
		end

		local chars
		if rounded then
			chars = {' ', '╶', '╷', '╭', '╴', '─', '╮', '┬', '╵', '╰', '│', '├', '╯', '┴', '┤', '┼'}
		else
			chars = {' ', '╶', '╷', '┌', '╴', '─', '┐', '┬', '╵', '└', '│', '├', '┘', '┴', '┤', '┼'}
		end

		for y = 1, height - 1 do
			local line = {}
			for x = 1, width - 1 do
				local char =
					(map[x][y].right      and 1 or 0) * 8 +
					(map[x][y].bottom     and 1 or 0) * 4 +
					(map[x][y + 1].right  and 1 or 0) * 2 +
					(map[x + 1][y].bottom and 1 or 0)

				line[#line + 1] = chars[char + 1]
				line[#line + 1] = chars[(not map[x + 1][y].bottom) and 1 or 6]
			end
			irc:privmsg(channel, line)
		end
	end, false, "+int", "+int", "+int...")
end