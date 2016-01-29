local utils = require("irc.utils")

return function(irc)
	irc:add_command("multiuser", "multiuser", function(irc, state, channel, msg)
		-- searches for users in the same channel with the same host

		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")

		local users_by_host = {}
		for _, user in pairs(irc.channels[channel].users) do
			users_by_host[user.host] = users_by_host[user.host] or {}
			table.insert(users_by_host[user.host], user.nick)
		end

		local out = {}
		for host, nicks in pairs(users_by_host) do
			if #nicks >= 2 then
				table.insert(out, table.concat(nicks, " = "))
			end
		end

		return utils.escape_list(out)
	end, false)

	irc:add_command("multiuser", "multichannel", function(irc, state, channel, ...)
		-- Users that are in atleast `atleast_channels` channels
		-- If you put a channel twice, it will count as the user is in two channels
		local channels_ = {...}
		assert(#channels_ >= 1, "Insufficient arguments")
		if #channels_ == 1 then
			channels_[2] = channel
		end
		local atleast_channels
		local channels = {}
		for i, channel in ipairs(channels_) do
			local channel_l = irc:lower(channel)
			if irc.channels[channel_l] then
				table.insert(channels, channel_l)
			elseif tonumber(channel) then
				atleast_channels = math.floor(tonumber(channel))
				assert(atleast_channels >= 2, "`atleast_channels` must be greater than or equal to 2")
			else
				error("Invalid channel " .. channel)
			end
		end
		atleast_channels = atleast_channels or #channels
		local nicks = {}
		for _, channel in pairs(channels) do
			for _, nick in pairs(irc.channels[channel].users) do
				nicks[nick.nick] = (nicks[nick.nick] or 0) + 1
			end
		end
		local format_nicks = {}
		for nick, count in pairs(nicks) do
			if count >= atleast_channels then
				table.insert(format_nicks, nick)
			end
		end
		assert(#format_nicks >= 1, ("No users in atleast %i those channels"):format(atleast_channels))
		return utils.escape_list(format_nicks)
	end, false, "string...")
end
