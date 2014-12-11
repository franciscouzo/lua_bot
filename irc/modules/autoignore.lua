return function(irc)
	local ignoring = {}

	local send_times = {}

	irc:add_hook("autoignore", "on_cmd_privmsg", function(irc, state, channel, msg)
		if irc:admin_user_mode(state.nick, "v") then
			return
		end

		local socket = require("socket")
		local time = socket.gettime()

		if ignoring[state.host] then
			if ignoring[state.host] < time then
				ignoring[state.host] = nil
			else
				return true -- we're ignoring you
			end
		end

		local config = irc:get_config("autoignore") or {}
		
		if not send_times[state.host] then
			send_times[state.host] = {}
			for i = 1, config.messages or 5 do
				send_times[state.host][i] = 0
			end
		end

		table.insert(send_times[state.host], time)
		if table.remove(send_times[state.host], 1) - (time - config.wait_time or 15) > 0 then
			ignoring[state.host] = time + config.ignore_time or 60
		end
	end, false, 1)
end