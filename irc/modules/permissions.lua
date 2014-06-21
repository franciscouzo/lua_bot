local utils = require("irc.utils")

local function has_permissions(config_key, irc, module_command, channel, nick)
	local needs_mode = (irc:get_config(config_key, channel) or {})[module_command]
	if not needs_mode then
		return true
	end
	local admin = false
	if type(needs_mode) == "table" then
		admin, needs_mode = unpack(needs_mode)
	end

	if irc:admin_user_mode(nick, needs_mode) then
		return true
	end
	if admin then
		return false
	end
	if irc:user_mode(channel, nick, needs_mode) then
		return true
	end
end

return function(irc)
	irc:add_hook("permissions", "on_user_cmd", function(irc, command, state, channel, ...)
		if not has_permissions("command_permissions", irc, command, channel, state.nick) then
			irc:error(state.nick, "You don't have permissions to run the command " .. command)
			return true
		end

		if not irc.commands[command] then
			return
		end
		local module = irc.commands[command].module
		if not has_permissions("module_permissions", irc, module, channel, state.nick) then
			irc:error(state.nick, "You don't have permissions to run commands from the module " .. module)
			return true
		end
	end)
end