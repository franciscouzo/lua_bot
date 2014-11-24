local json = require("json")
local utils = require("irc.utils")

return function(irc)
	irc:add_command("json", "json", function(irc, state, channel, s)
		local s, json_data = s:match("^(.-) (.+)$")
		s = s:gsub("%s", "")
		local data, pos, err = json.decode(json_data)
		assert(not err, err)
		while s ~= "" do
			local match, last = s:match("^%.?([^%.]+)()")
			s = s:sub(last)
			if tonumber(match) then
				data = data[tonumber(match)] or data[match]
			else
				data = data[match]
			end
		end
		return tostring(data)
	end, false)
end