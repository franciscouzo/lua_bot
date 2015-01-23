local utils = require("irc.utils")

local patterns = {
	rainbow = {4, 7, 8, 9, 11, 12, 13, 12, 11, 9, 8, 7},
	ar =      {11, 11, 0, 8, 0, 11, 11},
	fade =    {1, 14, 15, 0, 15, 14}
}

return function(irc)
	for color, color_code in pairs(irc.colors) do
		irc:add_command("style", color, function(irc, state, channel, msg)
			return irc:color(irc:strip_color(msg), color)
		end, false)
		irc:add_command("style", color .. "_background", function(irc, state, channel, msg)
			return irc:color(irc:strip_color(msg), color)
		end, false)
	end

	local styles = {{"bold", "\2"}, {"reverse", "\22"}, {"italics", "\29"}, {"underline", "\31"}}
	for _, style in ipairs(styles) do
		local style, style_code = unpack(style)
		irc:add_command("style", style, function(irc, state, channel, msg)
			return style_code .. msg .. style_code
		end, false)
	end

	irc:add_command("style", "strip_style", function(irc, state, channel, msg)
		return irc:strip_style(msg)
	end, false)
	irc:add_command("style", "strip_color", function(irc, state, channel, msg)
		return irc:strip_color(msg)
	end, false)

	irc:add_command("style", "random_color", function(irc, state, channel, msg)
		local out = ""
		for c in msg:gmatch(".") do
			out = out .. "\003" .. irc:fix_color(math.random(0, 16), c)
		end
		return out
	end, false)

	irc:add_command("style", "pattern_list", function(irc, state, channel, msg)
		local patts = {}
		for pattern in pairs(patterns) do
			patts[#patts + 1] = pattern
		end
		return utils.escape_list(patts)
	end, false)

	irc:add_command("style", "pattern", function(irc, state, channel, msg)
		if not msg:find(" ") then
			assert(patterns[msg:lower()], "Invalid pattern")
			local pattern = patterns[msg:lower()]
			return utils.escape_list(pattern)
		end
		
		local step, offset, pat, str = msg:match("(%d*) ?(%d*) ?(.-) (.+)")
		
		local step = tonumber(step) or 1
		local offset = tonumber(offset) or 0
		
		assert(pat and str, "Insufficient arguments")
		assert(str ~= "", "Empty string")
		assert(step >= 0 and step <= #str, "Invalid step value")

		local pattern
		if patterns[pat:lower()] then
			pattern = patterns[pat:lower()]
		elseif pat:sub(1, 1) == "p" and pat:find(":") then
			pattern = {}
			for _, pat in ipairs(utils.split(pat:sub(2), ":")) do
				local color, background = unpack(utils.split(pat, ",", 1))

				assert((color:match("^%d%d?$")), "Invalid color pattern")

				if background then
					assert((background:match("^%d%d?$")), "Invalid background pattern")
					pattern[#pattern + 1] = color .. "," .. background
				else
					pattern[#pattern + 1] = color
				end
			end
		else
			error("Invalid pattern")
		end

		str = irc:strip_color(str)

		local out
		if step == 0 then
			out = {}
			for i, word in ipairs(utils.split(str, " ")) do
				local color = pattern[(offset + i - 1) % #pattern + 1]
				out[#out + 1] = "\003" .. irc:fix_color(color, word)
			end
			out = table.concat(out, " ")
		else
			out = ""
			local i = 0
			local utf8 = require("utf8")
			for chars in utf8.gmatch(str, (".?"):rep(step)) do
				i = i + 1
				local color = pattern[(offset + i - 1) % #pattern + 1]
				out = out .. "\003" .. irc:fix_color(color, chars)
			end
		end
		return out
	end, false)

	irc:add_command("style", "rainbow", function(irc, state, channel, msg)
		return irc:run_command(state, channel, "pattern 2 rainbow " .. msg)
	end, false)
end