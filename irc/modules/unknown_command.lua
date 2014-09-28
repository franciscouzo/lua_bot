-- https://gist.github.com/Badgerati/3261142

local function levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}

	if len1 == 0 then
		return len2
	elseif len2 == 0 then
		return len1
	elseif str1 == str2 then
		return 0
	end

	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

	return matrix[len1][len2]
end

local function command_recommendation(irc, command)
	local distance = {}
	for cmd in pairs(irc.commands) do
		table.insert(distance, {cmd, levenshtein(command, cmd)})
	end

	table.sort(distance, function(a, b) return a[2] < b[2] end)
	local possible_commands = {}

	for _, cmd in ipairs(distance) do
		if cmd[2] <= (math.log(#cmd[1]) / math.log(2)) then
			table.insert(possible_commands, cmd[1])
		else
			break
		end
	end

	return possible_commands
end

local utils = require("irc.utils")

return function(irc)
	irc:add_command("unknown_command", "command_recommendation", function(irc, state, channel, command)
		return utils.escape_list(command_recommendation(irc, utils.strip(command)))
	end, false)
	irc:add_hook("unknown_command", "on_unknown_user_cmd", function(irc, command, state, channel, str)
		if (self:get_config("error_reporting", channel) or {}).unknown_command then
			local possible_commands = command_recommendation(irc, command)
			if #possible_commands == 0 then
				irc:notice(state.nick, ("Unknown command %q"):format(command))
			else
				irc:notice(state.nick, ("Unknown command %q, possible commands: "):format(command) .. table.concat(possible_commands, ", "))
			end
		end
	end)
end