-- http://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=10748
-- Lua Figlet

--[[
  Based on figlet.

  FIGlet Copyright 1991, 1993, 1994 Glenn Chappell and Ian Chai
  FIGlet Copyright 1996, 1997 John Cowan
  Portions written by Paul Burton
  Internet: <ianchai@usa.net>
  FIGlet, along with the various FIGlet fonts and documentation, is
    copyrighted under the provisions of the Artistic License(as listed
    in the file "artistic.license" which is included in this package.
--]]

-- Converted to Lua by Nick Gammon
-- 23 November 2010

local utils = require("irc.utils")

local figlet = {}

function figlet.font(filename)
	local fontfile = assert(io.open(filename, "r"))
	local font = {chars = {}}

	local header = assert(fontfile:read("*l"), "Empty FIGlet file")

	local signature, hardblank, height, baseline, maxlen, old_layout, comment_lines, print_direction, full_layout, code_tag_count =
		header:match("^(flf2a)(.) (%d+) (.-) (.-) (.-) (%d+) ?(.-) ?(.-) ?(.-)")

	assert(signature, "Not a FIGlet 2 font file")

	font.hardblank = hardblank
	font.height = math.max(1, tonumber(height))
	comment_lines = tonumber(comment_lines)

	for i = 1, comment_lines do
		assert(fontfile:read("*l"), "Not enough comment lines")
	end

	local ord = string.byte(" ") - 1
	while true do
		local line = fontfile:read("*l")
		if not line then
			break
		end

		num = line:match("^(%d+)")
		local negative, hex = line:match("^(%-?)0[xX](%x+).*")
		local height = font.height

		local char = {}

		if num or hex then
			if hex then
				ord = tonumber(hex, 16)
				assert(ord, "Unexpected line:" .. line)
				if negative == "-" then
					ord = -ord
				end
			else
				ord = tonumber(num)
			end
			for i = 1, font.height do
				local line = assert(fontfile:read("*l"), "Not enough character lines for character " .. ord)
				line = line:gsub("%s+$", "")
				line = line:gsub(utils.escape_pattern(line:sub(-1)) .. "+", "")
				table.insert(char, line)
			end
		else
			ord = ord + 1
			line = line:gsub("%s+$", "")
			line = line:gsub(utils.escape_pattern(line:sub(-1)) .. "+", "")
			table.insert(char, line)
			for i = 1, font.height - 1 do
				local line = assert(fontfile:read("*l"), "Not enough character lines for character " .. ord)
				line = line:gsub("%s+$", "")
				line = line:gsub(utils.escape_pattern(line:sub(-1)) .. "+", "")
				table.insert(char, line)
			end
		end
		font.chars[ord] = char
	end

	fontfile:close()

	-- remove leading/trailing spaces

	for k, v in pairs(font.chars) do
		-- first see if all lines have a leading space or a trailing space
		local leading_space = true
		local trailing_space = true
		for _, line in ipairs(v) do
			if line:sub(1, 1) ~= " " then
				leading_space = false
			end
			if line:sub(-1) ~= " " then
				trailing_space = false
			end
		end

		-- now remove them if necessary
		for i, line in ipairs(v) do
			if leading_space then
				v[i] = line:sub(2)
			end
			if trailing_space then
				v[i] = line:sub(1, -2)
			end
		end
	end

	return font
end

local function addchar(byte, font, output, kern, smush)
	local c = font.chars[byte]
	if not c then
		return
	end

	for i = 1, font.height do
		if smush and output[i] ~= "" and byte ~= (" "):byte() then
			local lhc = output[i]:sub(-1)
			local rhc = c[i]:sub(1, 1)
			output[i] = output[i]:sub(1, -2)
			if rhc ~= " " then
				output[i] = output[i] .. rhc
			else
				output[i] = output[i] .. lhc
			end
			output[i] = output[i] .. c[i]:sub(2)
		else
			output[i] = output[i] .. c[i]
		end
		if not (kern or smush) or byte == (" "):byte() then
			output[i] = output[i] .. " "
		end
	end
end

function figlet.ascii_art(s, font, kern, smush)
	assert(type(font) == "table", "Invalid font")
	assert(font.height > 0)

	local utf8 = require("utf8")

	local output = {}
	for i = 1, font.height do
		output[i] = ""
	end

	for c in utf8.gmatch(s, ".") do
		addchar(utf8.byte(c), font, output, kern, smush)
	end

	-- fix up blank character so we can do a string.gsub on it
	local fixedblank = string.gsub(font.hardblank, "[%%%]%^%-$().[*+?]", "%%%1")

	for i, line in ipairs(output) do
		output[i] = string.gsub(line, fixedblank, " ")
	end

	return output
end

local fonts_dir = "/usr/share/figlet/"
local fonts = {
	["banner"]   = true, ["big"]      = true, ["block"]    = true, ["bubble"]  = true,
	["digital"]  = true, ["ivrit"]    = true, ["lean"]     = true, ["mini"]    = true,
	["mnemonic"] = true, ["script"]   = true, ["shadow"]   = true, ["slant"]   = true,
	["small"]    = true, ["smscript"] = true, ["smshadow"] = true, ["smslant"] = true,
	["standard"] = true, ["term"]     = true
}

return function(irc)
	irc:add_command("figlet", "figlet", function(irc, state, channel, msg)
		local font = figlet.font(fonts_dir .. "standard.flf")
		print(font)
		for _, line in ipairs(figlet.ascii_art(msg, font, true, true)) do
			if utils.strip(line) ~= "" then
				irc:privmsg(channel, line)
			end
		end
	end, false)
	irc:add_command("figlet", "figlet_font", function(irc, state, channel, msg)
		local font, msg = msg:match("^(.-) (.+)")
		assert(font and msg, "Insufficient arguments")
		assert(fonts[font], "Invalid font")
		
		local font = figlet.font(fonts_dir .. font .. ".flf")
		for _, line in ipairs(figlet.ascii_art(msg, font, true, true)) do
			if utils.strip(line) ~= "" then
				irc:privmsg(channel, line)
			end
		end
	end, false)
end
