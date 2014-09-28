local utils = require("irc.utils")

local timer = {}

local second_types = {
	millisecond=0.001, milliseconds=0.001, ms=0.001,
	second=1,      seconds=1,      sec=1,  secs=1,  s=1,
	minute=60,     minutes=60,     min=60, mins=60, m=60,
	hour=3600,     hours=3600,     h=3600,
	day=86400,     days=86400,     d=86400,
	week=604800,   weeks=604800,   w=604800,
	month=2629800, months=2629800,
	year=31557600, years=31557600, yr=31557600, y=31557600 -- 365.25 days in a year
}

return function(irc)
	irc:add_command("timer", "seconds", function(irc, state, channel, msg)
		local seconds = 0
		local new_msg, h, m, s = msg:match("(.-)(%d+):(%d+):(%d+.?%d*)$")
		msg = new_msg or msg
		if h and m and s then
			seconds = seconds + h * 3600 + m * 60 + s
		end
		for n, type in msg:gmatch("(%d+%.?%d*)(%D+)") do
			type = utils.strip(type):lower()
			assert(second_types[type], "Invalid date type " .. type)
			n = assert(tonumber(n), "Invalid number")
			seconds = seconds + n * second_types[type]
		end
		return tostring(seconds)
	end, false)
	irc:add_command("timer", "timer", function(irc, state, channel, command)
		local socket = require("socket")
		local seconds, command = command:match("^(.-) (.+)$")
		assert(seconds and command, "Insufficient arguments")
		seconds = tonumber(seconds) or irc:run_command(state, channel, "seconds " .. seconds)
		irc:notice(state.nick, "ok " .. state.nick)
		socket.sleep(seconds)
		return irc:run_command(state, channel, command)
	end, true)
	irc:add_command("timer", "reminder", function(irc, state, channel, msg)
		local socket = require("socket")
		local seconds, msg = msg:match("^(.-) (.+)$")
		assert(seconds and msg, "Insufficient arguments")
		seconds = tonumber(seconds) or irc:run_command(state, channel, "seconds " .. seconds)
		irc:notice(state.nick, "ok " .. state.nick)
		socket.sleep(seconds)
		return state.nick .. ", " .. msg
	end, true)
	irc:add_command("timer", "timeit", function(irc, state, channel, command)
		local socket = require("socket")
		local t = socket.gettime()
		local _ = pcall(irc.run_command, irc, state, channel, command)
		return tostring(socket.gettime() - t)
	end, true)
	irc:add_command("timer", "sleep", function(irc, state, channel, seconds)
		local socket = require("socket")
		socket.sleep(seconds)
	end, true, "+float")
	irc:add_command("timer", "format_seconds", function(irc, state, channel, seconds)
		local out = ""
		local years,   seconds = math.floor(seconds / 31557600), seconds % 31557600
		local days,    seconds = math.floor(seconds / 86400), seconds % 86400
		local hours,   seconds = math.floor(seconds / 3600), seconds % 3600
		local minutes, seconds = math.floor(seconds / 60), seconds % 60
		local seconds, milliseconds = math.floor(seconds), math.floor((seconds % 1) * 1000)
		
		if years >= 1 then
			out = out .. ("%i year%s "):format(years, years == 1 and "" or "s")
		end
		if days >= 1 then
			out = out .. ("%i day%s "):format(days, days == 1 and "" or "s")
		end
		out = out .. ("%i:%02i:%02i"):format(hours, minutes, seconds)
		if milliseconds >= 1 then
			out = out .. "." .. milliseconds
		end
		return out
	end, false, "+float")
	irc:add_command("timer", "date", function(irc, state, channel, date)
		return (date == "*t" or data == "!*t") and date or os.date(date)
	end, false)
end
