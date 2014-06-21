local utils = require("irc.utils")

local function rot13(s)
	local a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local b = "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm"
	return (s:gsub("%a", function(c) return b:sub(a:find(c)) end))
end

return function(irc)
	local encode = {
		rot13 = rot13,
		hex = function(s)
			return ("%02X"):rep(#s):format(s:byte(1, -1))
		end,
		base64 = function(s)
			local mime = require("mime")
			return (mime.b64(s))
		end,
		cipher = function(s)
			local password, s = s:match("^(.-) (.*)$")
			assert(password and s, "Insufficient arguments")
			local mime = require("mime")
			local bit32 = require("bit32")

			local out = {}
			for i = 1, #s do
				local j = (i - 1) % #password + 1
				out[i] = string.char(bit32.bxor(s:sub(i, i):byte(), password:sub(j, j):byte()))
			end

			return (mime.b64(table.concat(out)))
		end,
		bin = function(s)
			local bit32 = require("bit32")
			local out = {}
			for c in s:gmatch(".") do
				local bin_char = {}
				for i = 7, 0, -1 do
					bin_char[#bin_char + 1] = bit32.band(c:byte(), 2^i) == 0 and 0 or 1
				end
				out[#out + 1] = table.concat(bin_char)
			end
			return table.concat(out)
		end,
		byte = function(c)
			return tostring(c:byte())
		end
	}

	local decode = {
		rot13 = rot13,
		hex = function(s)
			if #s % 2 == 1 then
				return nil, "Invalid length"
			end
			return (s:gsub("..", function(c) return string.char(tonumber(c, 16)) end))
		end,
		base64 = function(s)
			local mime = require("mime")
			return (mime.unb64(s))
		end,
		cipher = function(s)
			local password, s = s:match("^(.-) (.*)$")
			assert(password and s, "Insufficient arguments")
			local mime = require("mime")
			local bit32 = require("bit32")

			s = mime.unb64(s)
			if not s then
				return
			end
			local out = {}
			for i = 1, #s do
				local j = (i - 1) % #password + 1
				out[i] = string.char(bit32.bxor(s:sub(i, i):byte(), password:sub(j, j):byte()))
			end

			return table.concat(out)
		end,
		bin = function(s)
			if #s % 8 ~= 0 then
				return nil, "Invalid length"
			end
			return ((s):gsub("........", function(bin) return string.char(tonumber(bin, 2)) end))
		end,
		byte = function(b)
			local n = tonumber(b)
			if not n then
				return nil, "Invalid number"
			end
			if n < 0 or n >= 256 then
				return nil, "Invalid range"
			end
			return string.char(n)
		end
	}

	irc:add_command("encode", "encode", function(irc, state, channel, msg)
		local encoding, msg = msg:match("^(.-) (.+)")
		assert(encoding and msg, "Insufficient arguments")
		assert(encode[encoding], "Invalid encoding")
		local result = assert(encode[encoding](msg), "Invalid string for decoding")
		assert(not result:find("[%z\r\n]"), "Fuck off")
		return result
	end, false)
	irc:add_command("encode", "decode", function(irc, state, channel, msg)
		local encoding, msg = msg:match("^(.-) (.+)")
		assert(encoding and msg, "Insufficient arguments")
		assert(decode[encoding], "Invalid encoding")
		local result = assert(decode[encoding](msg), "Invalid string for encoding")
		assert(not result:find("[%z\r\n]"), "Fuck off")
		return result
	end, false)
	irc:add_command("encode", "encodings", function(irc, state, channel, msg)
		local encodings = {}
		for k in pairs(encode) do
			table.insert(encodings, k)
		end
		return utils.escape_list(encodings)
	end, false)
end