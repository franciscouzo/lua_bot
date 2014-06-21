local utils = require("irc.utils")

return function(irc)
	irc:add_command("highlight", "highlight", function(irc, state, channel, msg)
		assert(irc.channels[irc:lower(channel)], "Invalid channel")

		msg = utils.strip(msg)

		local min = msg:match("%+([^-])")
		local max = msg:match("%-([^+])")

		assert(#msg == (min and 2 or 0) + (max and 2 or 0), "Invalid modes")

		local found_min, found_max
		for i, mode in ipairs(irc.isupport.PREFIX) do
			if min == mode[1] then
				found_min = true
			end
			if max == mode[1] then
				found_max = true
			end
		end
		assert(min == nil and true or found_min, "Invalid mode " .. tostring(min))
		assert(max == nil and true or found_max, "Invalid mode " .. tostring(max))

		local users = {}
		for nick, user in pairs(irc.channels[irc:lower(channel)].users) do
			if not (min and not irc:user_mode(channel, nick, min)) and not (max and irc:user_mode(channel, nick, max)) then
				table.insert(users, user.nick)
			end
		end

		assert(#users >= 1, "No users to highlight")

		return utils.escape_list(users)
	end, false)
end
