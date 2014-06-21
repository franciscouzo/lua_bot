local utils = require("irc.utils")

return function(irc)
	irc:add_command("multiuser", "multiuser", function(irc, state, channel, msg)
		-- searches for users in the same channel with the same host
		channel = irc:lower(channel)
		assert(irc.channels[channel], "Invalid channel")
		local repeated = {}
		for nick1, user1 in pairs(irc.channels[channel].users) do
			for nick2, user2 in pairs(irc.channels[channel].users) do
				if user1.host == user2.host and nick1 ~= nick2 then
					if not repeated[user1.host] then
						repeated[user1.host] = {}
					end
					repeated[user1.host][nick1] = user1.nick
					repeated[user1.host][nick2] = user2.nick
				end
			end
		end
		local out = {}
		for hosts, nicks_map in pairs(repeated) do
			local nicks = {}
			for _, nick in pairs(nicks_map) do
				nicks[#nicks + 1] = nick
			end
			out[#out + 1] = table.concat(nicks, " = ")
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
