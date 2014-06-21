local utils = require("irc.utils")

return function(irc)
	local last_messages = {}
	local max_history = 10
	irc:add_hook("sed_replace", "on_send_privmsg", function(irc, channel, msg)
		table.insert(last_messages, 1, msg)
		table.remove(last_messages, max_history + 1)
	end)
	irc:add_hook("sed_replace", "on_cmd_privmsg", function(irc, state, channel, msg)
		local search, replace, flags = msg:match("^s/([^/]*)/([^/]*)/?(.*)$")

		if not (search and replace and flags) then
			table.insert(last_messages, 1, msg)
			table.remove(last_messages, max_history + 1)
			return
		end

		local case_insensitive = false

		local n, new_flags = flags:match("^(%d+)(.*)$")
		flags = new_flags or flags
		local max_replaces = n or 1

		if flags:find("i") then
			case_insensitive = true
			search = search:lower()
		end
		if flags:find("g") then
			max_replaces = nil -- no max
		end
		for _, message in ipairs(last_messages) do
			local start, finish = (case_insensitive and message:lower() or message):find(search, 1, true)
			if start and finish then
				local out = (case_insensitive and utils.gisub or string.gsub)(
					message,
					utils.escape_pattern(search),
					n and (function(s) n = n - 1; return n <= 0 and replace or s end) or utils.escape_pattern(replace),
					max_replaces
				)
				irc:privmsg(channel, out)
				return
			end
		end
	end)
end