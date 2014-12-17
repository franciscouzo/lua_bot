local utils = require("irc.utils")

return function(irc)
	local factoids = {}
	local file = io.open("data/factoids")
	if file then
		factoids = utils.unpickle(file:read("*a"))
		file:close()
	end

	local function save_factoids()
		os.rename("data/factoids", "data/factoids.backup")
		local file = assert(io.open("data/factoids", "w"))
		file:write(utils.pickle(factoids))
		file:close()
	end

	irc:add_hook("factoids", "on_cmd_privmsg", function(irc, state, channel, msg)
		msg_no_prefix = msg:match("^%s*" .. utils.escape_pattern(irc.nick) .. "[:,]%s*(.+)%s*")

		local reply = not not msg:find("<reply>")
		local action = not not msg:find("<action>")

		if reply ~= action then
			if not msg_no_prefix then
				return
			end
			
			local trigger, response = unpack(utils.split(msg_no_prefix, reply and "<reply>" or "<action>"))
			trigger = utils.strip(trigger:gsub("[^%w]", ""):lower())
			response = utils.strip(response)

			if #response > 300 then
				irc:notice(state.nick, "reply is too long")
				return
			end

			if not factoids[trigger] then
				factoids[trigger] = {}
			end

			for _, factoid in ipairs(factoids[trigger]) do
				if factoid == response then
					irc:notice(state.nick, "I already know that")
					return
				end
			end

			table.insert(factoids[trigger], response)
			save_factoids()
			irc:notice(state.nick, "ok " .. state.nick)
		else
			msg = msg_no_prefix or msg
			local trigger = utils.strip(msg:gsub("[^%w]", ""):lower())
			if factoids[trigger] and #trigger * (1 / 30) > math.random() then
				irc:privmsg(channel, utils.random_choice(factoids[trigger]))
			end
		end
	end)
end