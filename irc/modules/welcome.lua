local utils = require("irc.utils")

return function(irc)
	irc.linda:set("welcome.welcomes", {})
	local file = io.open("data/welcome")
	if file then
		irc.linda:set("welcome.welcomes", utils.unpickle(file:read("*a")))
		file:close()
	end

	local function save_welcome(welcomes)
		os.rename("data/welcome", "data/welcome.backup")
		local file = assert(io.open("data/welcome", "w"))
		file:write(utils.pickle(welcomes))
		file:close()
	end

	irc:add_hook("welcome", "on_cmd_join", function(irc, state, channel)
		channel = irc:lower(channel)
		if irc:lower(state.nick) ~= irc:lower(irc.nick) then -- we don't want to welcome ourselves
			local welcomes = irc.linda:get("welcome.welcomes")
			if welcomes[channel] then
				irc:notice(state.nick, irc:run_command(state, channel, welcomes[channel]))
				--irc:notice(state.nick, welcomes[channel])
			end
		end
	end, true)

	irc:add_command("welcome", "welcome", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local welcomes = irc.linda:get("welcome.welcomes")
		if utils.strip(msg) == "" then
			welcomes[channel] = nil
		else
			welcomes[channel] = msg
		end
		irc.linda:set("welcome.welcomes", welcomes)
		save_welcome(welcomes)
		irc:notice(state.nick, "ok " .. state.nick)
	end, false) -- non-async
end
