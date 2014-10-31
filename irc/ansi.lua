local colors = {[0]=15, 0, 4, 2, 9, 1, 5, 3, 11, 10, 6, 14, 12, 13, 8, 7}
local mirc_to_ansi256 = function(c, is_bg)
	c = tonumber(c) or -1
	return "\27[" .. (colors[c] and
		((is_bg and 48 or 38) .. ";5;" .. colors[c]) or
		(is_bg and 49 or 39)) .. "m"
end

local ansi = {}

function ansi.mirc_to_ansi(s)
	local b, u, n = 0, 0, 0
	return tostring(s):gsub("\2", function()
		b = b + 1
		local char = b % 2 == 1 and 1 or 22
		return "\27[" .. char .. "m"
	end):gsub("\31", function()
		u = u + 1
		local char = u % 2 == 1 and 4 or 24
		return "\27[" .. char .. "m"
	end):gsub("\22", function()
		n = n + 1
		local char = n % 2 == 1 and 7 or 27
		return "\27[" .. char .. "m"
	end):gsub("\3(%d?%d?),(%d%d?)", function(fg, bg)
		return mirc_to_ansi256(bg, true) .. (fg ~= "" and mirc_to_ansi256(fg) or "")
	end):gsub("\3(%d%d?)", function(fg)
		return mirc_to_ansi256(fg)
	end):gsub("\3", function()
		return mirc_to_ansi256(-1, true) .. mirc_to_ansi256(-1)
	end) .. "\27[0m"
end

function ansi.strip(s)
	--((\u001b\[)|\u009b)(([0-9]{1,3})?((;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]
	local i, l = 1, #s
	local out = ""
	while i <= l do
		local escape = s:match("^\27%[", i) or s:match("^\155", i)
		if escape then
			i = i + #escape
			--i = i + #(s:match("^%d%d?%d?"), i)
			i = i + #(s:match("^[;%d]+", i) or "")
			i = i + #(s:match("^[A-Mf-m]", i) or "")
		elseif s:match("^\27[A-M]", i) then
			i = i + 2
		else
			out = out .. s:sub(i, i)
			i = i + 1
		end
	end

	return out
end

return ansi