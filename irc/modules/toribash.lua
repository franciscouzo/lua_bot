local json = require("json")
local utils = require("irc.utils")

local function stats(username)
	username = utils.strip(username)
	local http = require("socket.http")
	http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

	local response, response_code = http.request("http://forum.toribash.com/toi_stats.php?format=json&username=" .. username)

	assert(response_code == 200, "Error requesting page")

	local data, pos, err = json.decode(response)
	assert(not err, err)

	return data
end

return function(irc)
	irc:add_command("toribash", "tb_stats", function(irc, state, channel, username)
		local user = stats(username)
		return ("%s's stats: %i qi, %i tc"):format(user.username, user.qi, user.tc)
	end, true)

	irc:add_command("toribash", "tb_qi", function(irc, state, channel, username)
		local user = stats(username)
		return tostring(user.qi)
	end, true)

	irc:add_command("toribash", "tb_tc", function(irc, state, channel, username)
		local user = stats(username)
		return tostring(user.tc)
	end, true)

	local irc_colors = {
		[0]  = 1,  [1]  = 85, [2]  = 86, [3]  = 36, [4]  = 2,  [5]  = 3,
		[6]  = 32, [7]  = 61, [8]  = 9,  [9]  = 10, [10] = 64, [11] = 38,
		[12] = 4,  [13] = 6,  [14] = 8,  [15] = 37
	}
	local tb_colors = {
		[0]   = 0,  [1]   = 0,  [2]   = 4,  [3]   = 5,  [4]   = 12, [5]   = 10,
		[6]   = 13, [7]   = 1,  [8]   = 14, [9]   = 8,  [10]  = 9,  [11]  = 11,
		[12]  = 11, [13]  = 8,  [14]  = 6,  [15]  = 6,  [16]  = 7,  [17]  = 15,
		[18]  = 8,  [19]  = 5,  [20]  = 5,  [21]  = 15, [22]  = 0,  [23]  = 7,
		[24]  = 7,  [25]  = 14, [26]  = 8,  [27]  = 13, [28]  = 10, [29]  = 7,
		[30]  = 3,  [31]  = 13, [32]  = 6,  [33]  = 8,  [34]  = 12, [35]  = 8,
		[36]  = 3,  [37]  = 15, [38]  = 11, [39]  = 15, [40]  = 9,  [41]  = 4,
		[42]  = 15, [43]  = 14, [44]  = 14, [45]  = 14, [46]  = 0,  [47]  = 0,
		[48]  = 14, [49]  = 0,  [50]  = 0,  [57]  = 4,  [58]  = 6,  [59]  = 14,
		[61]  = 7,  [62]  = 3,  [64]  = 10, [65]  = 5,  [71]  = 4,  [75]  = 10,
		[85]  = 1,  [86]  = 2,  [87]  = 14, [89]  = 5,  [92]  = 5,  [95]  = 1,
		[97]  = 15, [100] = 5,  [101] = 3,  [102] = 14, [104] = 3,  [105] = 2,
		[106] = 10, [107] = 14, [108] = 14, [109] = 15, [110] = 2,  [113] = 6,
		[114] = 14, [115] = 13, [116] = 14, [118] = 4,  [120] = 14, [121] = 14,
		[123] = 15, [124] = 14
	}
	irc:add_command("toribash", "irc_to_tb_colors", function(irc, state, channel, msg)
		msg = irc:strip_background_color(msg)
		msg = msg:gsub("\3(%d%d?)", function(n) return ("^%02d"):format(irc_colors[tonumber(n)]) end)
		return msg
	end, false)
	irc:add_command("toribash", "irc_to_tb_colors2", function(irc, state, channel, msg)
		msg = irc:strip_background_color(msg)
		msg = msg:gsub("\3(%d%d?)", function(n) return ("%%%03d"):format(irc_colors[tonumber(n)]) end)
		return msg
	end, false)
	irc:add_command("toribash", "tb_to_irc_colors", function(irc, state, channel, msg)
		msg = msg:gsub("%^(%d%d)", function(n) return "\3" .. tb_colors[tonumber(n)] end)
		msg = msg:gsub("%%(%d%d%d)", function(n) return "\3" .. tb_colors[tonumber(n)] end)
		return msg
	end, false)
end