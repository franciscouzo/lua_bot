local utils = require"irc.utils"
return function(irc)
	irc:add_command("vote", "vote", function(irc, state, channel, n)
		channel = irc:lower(channel)
		local votes = irc.linda:get("vote.votes." .. channel)
		assert(votes, "No voting in place")
		assert(n >= 1 and n <= #votes.options, "Invalid vote")

		if votes.hosts[state.host] then
			votes.votes[votes.hosts[state.host]] = votes.votes[votes.hosts[state.host]] - 1
			irc:notice(state.nick, "Vote updated")
		else
			irc:notice(state.nick, "Vote registered")
		end
		votes.hosts[state.host] = n
		votes.votes[n] = (votes.votes[n] or 0) + 1

		irc.linda:set("vote.votes." .. channel, votes)
	end, false, "+int")
	irc:add_command("vote", "vote_start", function(irc, state, channel, question, ...)
		channel = irc:lower(channel)
		local votes = irc.linda:get("vote.votes." .. channel)
		assert(not votes, "Vote already taking place")

		local options = {...}
		votes = {
			question = question,
			options = options,
			votes = {},
			hosts = {}
		}

		local options_t = {}
		for i, option in ipairs(options) do
			options_t[i] = ("(%i) %s"):format(i, option)
		end

		irc.linda:set("vote.votes." .. channel, votes)

		return ("Vote for \"%s\": %s, vote <n>"):format(question, table.concat(options_t, ", "))
	end, false, "string", "string...")
	irc:add_command("vote", "vote_end", function(irc, state, channel)
		channel = irc:lower(channel)
		local votes = irc.linda:get("vote.votes." .. channel)
		assert(votes, "No voting in place")

		irc.linda:set("vote.votes." .. channel, nil)
		local sorted_votes = {}
		for i = 1, #votes.options do
			local vote_count = votes.votes[i] or 0
			if vote_count > 0 then
				sorted_votes[#sorted_votes + 1] = {i, vote_count}
			end
		end

		table.sort(sorted_votes, function(a, b) return a[2] > b[2] end)

		assert(#sorted_votes >= 1, "No votes were cast")

		local output = {}

		for i, vote in ipairs(sorted_votes) do
			local option = votes.options[vote[1]]
			local votes = vote[2]
			output[i] = ("%s = %s vote%s"):format(option, votes, votes == 1 and "" or "s")
		end

		return 'Results for "' .. votes.question .. '": ' .. table.concat(output, ", ")
	end, false)
end