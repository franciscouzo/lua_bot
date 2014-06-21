local utils = require("irc.utils")

local function levenshtein_distance(s1, s2)
	if s1:len() == 0 then return s2:len() end
	if s2:len() == 0 then return s1:len() end

	if s1:sub(-1, -1) == s2:sub(-1, -1) then
		return levenshtein_distance(s1:sub( 1, -2), s2:sub(1, -2 ))
	end

	local a = levenshtein_distance(s1:sub(1, -2), s2:sub(1, -2))
	local b = levenshtein_distance(s1:sub(1, -1), s2:sub(1, -2))
	local c = levenshtein_distance(s1:sub(1, -2), s2:sub(1, -1))

	if a > b then return b + 1 end
	if a > c then return c + 1 end
	return a + 1
end

return function(irc)
	irc:add_command("typo", "typo_start", function(irc, state, channel, word_length, word_dist, num_before_repeat)
		channel = irc:lower(channel)
		local game = irc.linda:get("typo.games." .. channel)
		assert(not game, "Game is taking place")

		word_length = word_length or 4
		word_dist = word_dist or 1
		num_before_repeat = num_before_repeat or 30

		word_length = math.max(3, word_length)
		word_length = math.min(20, word_length)

		word_dist = math.max(1, word_dist)
		word_dist = math.min(word_length - 1, word_dist)

		num_before_repeat = math.max(5, num_before_repeat)
		num_before_repeat = math.min(250, num_before_repeat)
		
		local words = {}

		for line in io.lines("data/word_list") do
			if #line == word_length then
				local word = utils.strip(line):lower()
				words[word] = true
			end
		end

		local word = utils.random_choice_dict(words)

		game = {
			points = {},
			words = words,
			word = word,
			last_words = {word},
			word_dist = word_dist,
			word_length = word_length,
			num_before_repeat = num_before_repeat
		}

		irc.linda:set("typo.games." .. channel, game)
		return ("Starting typo game! Current word: %s " ..
		       "(You have to find a word has up to %i different character%s (with the same length))")
		       :format(irc:color(word, "red"), word_dist, word_dist == 1 and "" or "s")
	end, true, "+int...") -- opening the file could take a while, it's like 15MB
	irc:add_hook("typo", "on_cmd_privmsg", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local game = irc.linda:get("typo.games." .. channel)
		if not game then
			return -- no game in place
		end

		word = utils.strip(msg):lower()

		if word:len() ~= game.word_length then
			return
		end

		if levenshtein_distance(game.word, word) > game.word_dist then
			return -- word is too different
		end

		if not game.words[word] then
			return -- word doesn't exists
		end

		for _, last_word in ipairs(game.last_words) do
			if last_word == word then
				return
			end
		end

		local nick = irc:lower(state.nick)

		game.word = word
		local points = (game.points[nick] or 0) + 1
		game.points[nick] = points

		table.insert(game.last_words, 1, word)
		table.remove(game.last_words, game.num_before_repeat + 1)

		irc.linda:set("typo.games." .. channel, game)

		irc:privmsg(channel, ("New word %s, %s's points: %i"):format(irc:color(word, "red"), state.nick, points))

	end, true)
	irc:add_command("typo", "typo_stop", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local game = irc.linda:get("typo.games." .. channel)
		assert(game, "No game is taking place")

		irc.linda:set("typo.games." .. channel, nil)

		assert(next(game.points), "There's no winner, since nobody played")

		local winner
		local winner_points = -1
		for user, points in pairs(game.points) do
			if points > winner_points then
				winner = user
				winner_points = points
			end
		end

		return ("Game stopped, winner: %s with %i point%s"):format(winner, winner_points, winner_points == 1 and "" or "s")
	end, false)
	irc:add_command("typo", "typo_skip", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local game = irc.linda:get("typo.games." .. channel)
		assert(game, "No game is taking place")

		local word = utils.random_choice_dict(game.words)

		-- remove all last_words or just append?
		-- game.last_words = {word}
		table.insert(game.last_words, 1, word)
		table.remove(game.last_words, game.num_before_repeat + 1)

		irc.linda:set("typo.games." .. channel, game)
		
		return "Last word skipped, new word: " .. irc:color(word, "red")
	end, false)
end