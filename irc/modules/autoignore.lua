local glob = require("glob")

return function(irc)
	local ignoring = {}

	local send_times = {}

	irc:add_hook("autoignore", "on_cmd_privmsg", function(irc, state, channel, msg)
		if irc:admin_user_mode(state.nick, "v") then
			return
		end

		local socket = require("socket")
		local time = socket.gettime()

		local config = irc:get_config("autoignore") or {}
		local mask = (config.format or "*!*@{host}"):gsub("{(.-)}", state)

		if ignoring[mask] then
			if ignoring[mask] < time then
				ignoring[mask] = nil
			else
				return true -- we're ignoring you
			end
		end

		if not send_times[mask] then
			send_times[mask] = {}
			for i = 1, config.messages or 5 do
				send_times[mask][i] = 0
			end
		end

		table.insert(send_times[mask], time)
		if table.remove(send_times[mask], 1) - (time - config.wait_time or 15) > 0 then
			ignoring[mask] = time + config.ignore_time or 60
		end
	end, false, 1)
end