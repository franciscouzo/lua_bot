local utils = require("irc.utils")

return function(irc)
	local active = {}
	irc:add_hook("active", "on_cmd_privmsg", function(irc, state, channel, msg)
		local socket = require("socket")
		channel = irc:lower(channel)
		if not active[channel] then
			active[channel] = {}
		end
		local time = socket.gettime()
		active[channel][state.nick] = time
		
		for user, user_time in pairs(active[channel]) do
			if time - user_time > irc:get_config("remove_unactive_after", channel) or 3600 then
				active[channel][user] = nil
			end
		end
	end)
	irc:add_command("active", "active", function(irc, state, channel, seconds)
		local socket = require("socket")
		channel = irc:lower(channel)
		assert(active[channel], "Unactive channel")
		seconds = seconds or 120

		local time = socket.gettime()
		local active_users = {}

		for user, user_time in pairs(active[channel]) do
			if time - user_time <= seconds then
				table.insert(active_users, {user, time - user_time})
			end
		end
		table.sort(active_users, function(a, b) return a[2] < b[2] end)

		local users = {}
		for i, user_time in ipairs(active_users) do
			local user, time = unpack(user_time)
			users[i] = user
		end
		return utils.escape_list(users)
	end, false, "+float...")
end