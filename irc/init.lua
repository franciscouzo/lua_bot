--[[
	relevant documents:

	http://tools.ietf.org/html/rfc1459.html
	https://tools.ietf.org/html/rfc2812
	http://tools.ietf.org/html/draft-brocklesby-irc-isupport-03
	https://github.com/ircv3/ircv3-specifications
	http://www.irchelp.org/irchelp/rfc/ctcpspec.html

	https://github.com/myano/jenni/wiki/IRC-String-Formatting
]]

local lanes = require("lanes").configure()

local socket = require("socket")
local ssl_success, ssl = pcall(require, "ssl")

local replies = require("irc.replies")
local utils = require("irc.utils")
local hooks = require("irc.hooks")

for i = 1, 10 do
	math.randomseed(os.time() + os.clock() * 1000000 + math.random(2^16))
end

local irc = {
	supported_capabilities = {
		["multi-prefix"] = true, ["sasl"] = true, -- base ircv3.1
		["account-notify"] = true, ["away-notify"] = true, ["extended-join"] = true, --[tls] = true -- optional ircv3.1
		--["intents"] = true, -- base ircv3.2
		["account-tag"] = true, --[[["batch"] = true,]] ["cap-notify"] = true, -- optional ircv3.2
		["chghost"] = true, ["invite-notify"] = true, ["userhost-in-names"] = true,
		["self-message"] = true, ["server-time"] = true
	},
	isupport_default = {
		CASEMAPPING = "rfc1459",
		CHANMODES = {"b", "k", "l", "imnpst"},
		CHANNELLEN = 200,
		CHANTYPES = "#&",
		EXCEPTS = "+e",
		INVEX = "+I",
		MODES = 3,
		NICKLEN = 9,
		PREFIX = {{"o", "@"}, {"v", "+"}}
	}
}

function irc:new(config)
	self.config = config

	assert(not (self.config.ssl and not ssl_success), "config.ssl is true, but luasec is not installed")

	self.nick = assert(config.nick, "Invalid nick")
	self.username = config.username or self.nick
	self.realname = config.realname or self.nick

	self.hook_order = {}
	self.hooks = {}

	self.commands = {}
	self.module_list = {}

	self.queue = {}
	if self.config.flood_control then
		self.queue_time = {}
		for i = 1, self.config.flood_control.length do
			self.queue_time[i] = 0
		end
	end
	self.threads = {}
	self.linda = lanes.linda()

	self.connected = false

	hooks(irc)

	self:call_hook("on_init")

	return self
end

function irc:is_valid_channel(channel)
	if channel == "" then
		return nil, "Channel is empty"
	elseif not self.isupport.CHANTYPES:find(channel:sub(1, 1), 1, false) then
		return nil, "Invalid channel type"
	elseif #channel > self.isupport.CHANNELLEN then
		return nil, "Invalid channel length"
	elseif channel:match(" ,\007") then
		return nil, "Channel can't have ' ', ',' or '\\007'"
	end
	return true
end

function irc:get_config(key, channel)
	channel = channel and self:lower(channel) or nil
	if channel then
		for channel_ in pairs(self.config.channels) do
			if self:lower(channel_) == channel then
				if self.config.channels[channel_][key] ~= nil then
					return self.config.channels[channel_][key]
				end
			end
		end
	end
	return self.config[key]
end

function irc:connect()
	local servers = utils.listify(self.config.servers)
	assert(#servers > 0, "Server list is empty")

	for _, server in ipairs(servers) do
		local port = self.config.ssl and 6697 or 6667
		if type(server) == "table" then
			server, port = unpack(server)
		end

		local status, sock, err = pcall(socket.connect, server, port)
		if not (status and sock) then
			print(("%s (%s:%i)"):format(err, server, port))
			return
		end

		sock:setoption("tcp-nodelay", true)
		sock:setoption("keepalive", true)

		if self.config.ssl then
			local params = utils.deepcopy(self.config.ssl)
			params.mode = "client"

			local sock_, err = ssl.wrap(sock, params)
			sock = sock_

			if not sock then
				(self.config.ssl.exit_on_error and error or print)(err)
				return
			end

			local success, err = sock:dohandshake()

			if not success then
				(self.config.ssl.exit_on_error and error or print)(err)
				return
			end
		end

		sock:settimeout(0)
		self.connected = true
		return sock
	end
end

function irc:main_loop()
	xpcall(function()
		self:true_main_loop()
	end,
	function(err)
		self:call_hook("on_quit")
		if self.sock then
			self.sock:close()
		end
		print(err)
		print(require("debug").traceback())
	end)
end

function irc:true_main_loop()
	self.running = true
	while self.running do
		local try = 0
		repeat
			try = try + 1
			self.socket = self:connect()
			if not self.socket then
				socket.sleep(math.min(600, 2 ^ try))
			end
		until self.socket

		self:call_hook("on_connect")

		local last_response = socket.gettime()

		local timeout = (self.config.timeout or 300)

		while self.connected do
			repeat
				local line, status = self.socket:receive("*l")
				if socket.gettime() - last_response > timeout then
					self.connected = false
				elseif status and status ~= "timeout" then
					self.connected = false
				else
					if line and utils.strip(line) ~= "" then
						last_response = socket.gettime()
						self:run_line(line)
					end
					self:manage_queue()
					self:call_hook("on_tick")
				end
			until not line
			socket.sleep(0.02)
		end
	end
end

function irc:manage_queue()
	for i = 1, #self.threads do
		local thread = self.threads[i]
		if thread.status == "done" or thread.status == "error" then
			if thread.status == "done" then
				local state, channel, result = thread[2], thread[3], thread[4]
				if (state and channel and result) and not self:call_hook("on_msg", channel, result) then
					self:privmsg(channel, result)
				end
			elseif thread.status == "error" then
				local _, err = pcall(function() return thread[1] end)
				print(err)
			end
			table.remove(self.threads, i)
			break
		end
	end

	local k, v = self.linda:receive(0, "send")
	if k then
		self:send(unpack(v))
	end
	local message = self.queue[1]
	if message then
		if not self.config.flood_control then
			self.socket:send(message .. "\r\n")
			table.remove(self.queue, 1)
		elseif self.queue_time[1] + self.config.flood_control.time < socket.gettime() then
			table.insert(self.queue_time, socket.gettime())
			table.remove(self.queue_time, 1)
			self.socket:send(message .. "\r\n")
			table.remove(self.queue, 1)
		end
	end
end

function irc:run_line(line)
	local tags, prefix, command, args = self:parse_line(line)
	if not prefix then
		return
	end

	local time
	if tags.time then
		local year, month, day, hour, minute, second, millisecond = tags.time:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)%.(%d+)Z")
		if year then
			time = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second}) + millisecond / 1000
		end
	else
		time = os.time()
	end

	local nick, user, host = prefix:match("(.+)!(.+)@(.+)")
	local state = {tags = tags, prefix = prefix, nick = nick, user = user, host = host, line = line, time = time}

	if (nick and user and host) then
		if args[1] and self:lower(args[1]) == self:lower(self.nick) then
			args[1] = nick
		end
	end

	if not self:call_hook("on_cmd", command:upper(), utils.deepcopy(state), unpack(args)) then
		self:call_hook("on_cmd_" .. command:lower(), utils.deepcopy(state), unpack(args))
	end

	if tonumber(command) then
		local rpl = replies[tonumber(command)]
		if rpl then
			if not self:call_hook("on_rpl", rpl:upper(), utils.deepcopy(state), unpack(args)) then
				self:call_hook("on_" .. rpl:lower(), utils.deepcopy(state), unpack(args))
			end
		else
			self:call_hook("on_unknown_rpl", tonumber(command), utils.deepcopy(state), unpack(args))
		end
	end
end

function irc:call_hook(hook_name, ...)
	if not self.hooks[hook_name] then
		return nil, "Unknown hook " .. hook_name
	end
	for _, hook_id in pairs(self.hook_order[hook_name]) do
		local hook = self.hooks[hook_name][hook_id]
		if hook.threaded then
			-- threaded hooks can't stop other hooks
			-- but they can be stopped
			self:hook_thread(hook.func, ...)
		else
			local args = {...}
			local status, ret = xpcall(function() return hook.func(self, unpack(args)) end, debug.traceback)
			if status and ret then
				return ret
			end
		end
	end
end

local hook_counter = 1

function irc:add_hook(module, hook, f, threaded, pos)
	if not (module and hook and f) then
		return nil, "Insufficient arguments"
	end
	if type(module) ~= "string" then
		print("Invalid module for hook " .. hook)
		return nil, "Invalid module"
	end
	--print(("%20s | %30s | %s"):format(module, hook, tostring(threaded)))

	local id = hook_counter
	hook_counter = hook_counter + 1
	if not self.hook_order[hook] then
		self.hook_order[hook] = {}
	end
	if pos then
		table.insert(self.hook_order[hook], pos, id)
	else
		table.insert(self.hook_order[hook], id)
	end
	if not self.hooks[hook] then
		self.hooks[hook] = {}
	end
	if self.hooks[hook][module] then
		print("Hook already exists")
		return nil, "Hook already exists"
	end
	local t = {id = id, func = f, threaded = threaded, module = module}
	self.hooks[hook][id] = t
	self.hooks[hook][module] = t
	return t
end

function irc:del_hook(hook, module_or_id)
	if not self.hook_order[hook] or not self.hooks[hook] then
		return nil, "Nonexistent hook"
	end
	local key = type(module_or_id) == "string" and "module" or "id"
	for i = 1, #self.hook_order[hook] do
		if self.hooks[hook][self.hook_order[hook][i]][key] == module_or_id then
			table.remove(self.hook_order, i)
			self.hooks[hook][self.hooks[hook][i].module] = nil
			self.hooks[hook][id] = nil
			return true
		end
	end
	return nil, "Wut"
end

function irc:hook_thread(func, ...)
	local irc = self:copy_for_lanes()

	function irc:send(...)
		self.linda:send("send", {...})
	end
	irc.threaded = true

	local thread = lanes.gen("*", func)(irc, ...)
	table.insert(self.threads, thread)
end

function irc:command_thread(state, channel, command)
	local irc = self:copy_for_lanes()
	irc.state = state
	function irc:send(...)
		self.linda:send("send", {...})
	end
	irc.threaded = true
	local thread = lanes.gen("*", function(irc, state, channel, command)
		local result = irc:call_command(state, channel, command)
		if result then
			return irc, state, channel, result
		end
	end)(irc, state, channel, command)
	table.insert(self.threads, thread)
end

function irc:module_set_threaded(module, threaded)
	if not self.module_list[module] then
		self.module_list[module] = {}
	end

	self.module_list[module].threaded = threaded
end

function irc:add_command(module, command, func, threaded, ...)
	command = command:lower()
	module = module:lower()
	--print(("%20s: %s"):format(command, tostring(threaded)))
	if threaded == nil then
		print("thread flag is nil for command " .. command)
	end
	threaded = (threaded == nil) and true or threaded

	--print(("%20s | %30s | %s"):format(module, command, tostring(threaded)))

	if self.commands[command] then
		print("Command " .. command .. " (" .. module .. ") already exists in module " .. self.commands[command].module)
		return nil, "Command " .. command .. " already exists"
	end

	if not self.module_list[module] then
		self.module_list[module] = {threaded=true}
	end

	table.insert(self.module_list[module], command)

	self.commands[command] = {func=func, module=module, threaded=threaded, arguments = {...}}
	return true
end

function irc:del_command(command)
	command = command:lower()
	if not self.commands[command] or not self.commands[command].module then
		return nil, "Nonexistent command " .. command
	end
	local module = self.commands[command].module

	for i, cmd in ipairs(self.module_list[module]) do
		if cmd == command then
			self.module_list[module][i] = nil
			self.commands[command] = nil
			return true
		end
	end
	return nil, "Wut"
end

local function r_copy(t, ret)
	ret = ret or {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			ret[k] = {}
			r_copy(v, ret[k])
			if not next(ret[k]) then
				ret[k] = nil
			end
		else
			local success, err = pcall(lanes.gen("*", (function() return k, v end)))
			if not success then
				ret[k] = success
			end
		end
	end
	return ret
end

function irc:copy_for_lanes()
	local irc = {}
	local blacklist = {
		socket = true, connect = true, new = true, true_main_loop = true,
		hooks = true, commands = true,
		hook_thread = true, command_thread = true, threads = true, manage_queue = true
		, copy_for_lanes = true
	}
	for k, v in pairs(self) do
		if not blacklist[k] then
			irc[k] = v
			local success, err = pcall(lanes.gen("*", (function() return k, v end)))
			if not success then
				print(("%s: %s"):format(k, err))
				if type(v) == "table" then
					utils.tprint(r_copy(v))
				end
			end
		end
	end

	irc.hooks = {}
	for hook, hook_info in pairs(self.hooks) do
		irc.hooks[hook] = hook_info
	end

	irc.commands = {}
	for command, command_info in pairs(self.commands) do
		if self.module_list[command_info.module].threaded then
			irc.commands[command] = command_info
		end
	end

	irc.queue = {}
	return irc
end

function irc:parse_modes(channel, modes, user_change)
	if self:lower(self.nick) == self:lower(channel) then -- it's modyfing us, we don't care
		return
	end

	if not modes[1]:match("^[+-]") then
		return
	end

	local chanmodes = self.isupport_default["CHANMODES"]
	if type(self.isupport["CHANMODES"]) == "table" and #self.isupport["CHANMODES"] >= 4 then
		chanmodes = self.isupport["CHANMODES"]
	end

	local chanmode_keys = {}
	for i = 1, 4 do
		for mode in chanmodes[i]:gmatch(".") do
			chanmode_keys[mode] = i
		end
	end

	local usermode_keys = {}
	for _, mode_prefix in ipairs(self.isupport["PREFIX"]) do
		local mode, prefix = unpack(mode_prefix)
		usermode_keys[mode] = prefix
	end

	local list, param, param_when_set, no_params = 1, 2, 3, 4

	local direction

	local i = 2

	local channel = self:get_channel(channel)

	for c in modes[1]:gmatch(".") do
		if c == "+" or c == "-" then
			direction = ("+-"):find(c, 1, 1)
		end

		local param_type = chanmode_keys[c]
		local prefix = usermode_keys[c]

		if param_type then
			if param_type == list then -- we don't care, bans and the like
				i = i + 1
			elseif param_type == param or param_type == param_when_set then
				channel.modes[c] = (direction == 1) and (tonumber(modes[i]) or modes[i]) or nil
				i = i + 1
			elseif param_type == no_params then
				channel.modes[c] = (direction == 1) and true or nil
			end
		elseif prefix then
			channel.users[self:lower(modes[i])].modes[prefix] = (direction == 1) and true or nil
			i = i + 1
		end
	end
end

local tag_escapes = {[":"] = ";", ["s"] = " ", ["0"] = "\000", ["\\"] = "\\", ["r"] = "\r", ["n"] = "\n"}

function irc:parse_line(s)
	local tags = {}
	local prefix = ""
	local trailing = {}
	if s == "" then
		return
	end
	if s:sub(1, 1) == "@" then
		local tag_list
		tag_list, s = unpack(utils.split(s:sub(2), " ", 1))
		if not (tag_list and s) then
			return
		end
		tag_list = utils.split(tag_list, ";")
		for _, tag in ipairs(tag_list) do
			local tag, value = unpack(utils.split(tag, "=", 1))
			value = value or true
			if tag and value then
				value = value == true or value:gsub("\\(.)", tag_escapes)
				tags[tag] = value
			end
		end
	end
	if s:sub(1, 1) == ":" then
		prefix, s = unpack(utils.split(s:sub(2), " ", 1))
		if not (prefix and s) then
			return
		end
	end
	local args
	if s:find(" :") then
		s, trailing = unpack(utils.split(s, " :", 1))
		args = utils.split(s, " ")
		table.insert(args, trailing)
	else
		args = utils.split(s, " ")
	end
	command = table.remove(args, 1)
	return tags, prefix, command, args
end

local tag_format_escapes = {[";"] = "\\:", [" "] = "\\s", ["\000"] = "\\0", ["\\"] = "\\\\", ["\r"] = "\\r", ["\n"] = "\\n"}
local tag_format_escapes_pattern = "[; %z\\\r\n]"

function irc:format_msg(command, ...)
	local args = {...}
	local message = ""
	if type(args[#args]) == "table" then
		local tags = table.remove(args)
		local tags_formatted = {}
		for tag, value in pairs(tags) do
			table.insert(tags_formatted, tag .. "=" .. value:gsub(tag_format_escapes_pattern, tag_format_escapes))
		end
		message = "@" .. table.concat(tags_formatted, ";") .. " "
	end

	message = message .. command
	local len = #args
	for i, v in ipairs(args) do
		if i == len and (v:find(" ") or v:find(":")) then
			v = ":" .. v
		end
		message = message .. " " .. v
	end
	return message
end

local default_channel = {topic = "", users = {}, modes = {}}
function irc:new_channel(channel_name, options)
	local channel_name = self:lower(channel_name)

	if self.channels[channel_name] then
		return self.channels[channel_name]
	end

	local channel = utils.deepcopy(default_channel)
	channel.channel = channel_name

	for k, v in pairs(options or {}) do
		channel[k] = v
	end

	self.channels[channel_name] = channel

	return channel
end

function irc:get_channel(channel, new_channel)
	channel = self:lower(channel)
	return self.channels[channel] or (new_channel and self:new_channel(channel))
end

function irc:del_channel(channel)
	self.channels[self:lower(channel)] = nil
end

local default_nick = {modes = {}, user = "", host = "", account = nil, realname = nil, away = nil}
function irc:new_user(channel_name, nick, options)
	channel_name = self:lower(channel_name)
	channel = self:get_channel(channel_name, true)

	local user = utils.deepcopy(default_nick)
	user.nick = nick
	for k, v in pairs(options or {}) do
		user[k] = v
	end
	channel.users[self:lower(nick)] = user
end

function irc:update_user(nick, key, value)
	nick = self:lower(nick)
	for _, channel in pairs(self.channels) do
		if channel.users[nick] then
			channel.users[nick][key] = value
		end
	end
end

function irc:user_mode(channel_name, nick, has_mode)
	-- if channel_name is "*" we search in all the channels

	local modes, mode = ""

	for _, mode_prefix in ipairs(self.isupport["PREFIX"]) do
		local mode_available, prefix = unpack(mode_prefix)
		modes = modes .. prefix
		if mode_available == has_mode then
			mode = prefix
		end
	end
	if not mode then
		return nil, "bogus mode"
	end

	local higher_modes = modes:sub(1, modes:find(mode, 1, true))

	nick = self:lower(nick)

	local channels = channel_name == "*" and self.channels or {self:get_channel(channel_name)}

	for _, channel in pairs(channels) do
		if channel.users[nick] then
			for mode in higher_modes:gmatch(".") do
				if channel.users[nick].modes[mode] then
					return true
				end
			end
		end
	end
	return false
end

function irc:admin_user_mode(nick, mode)
	for channel, channel_data in pairs(self.config.channels or {}) do
		if channel_data.admin_channel and self:user_mode(channel, nick, mode) then
			return true
		end
	end
	return false
end

function irc:is_threaded(message)
	-- return true in case of fail, just in case
	local threaded = false
	local split = utils.split_format(message, "|", function(s)
		threaded = threaded or self:is_threaded(s)
		return ""
	end)
	if threaded or not split then
		return true
	end
	for _, e_message in ipairs(split) do
		e_message = utils.lstrip(e_message)
		local command = (utils.split(e_message, " ")[1] or ""):lower()
		if self.commands[command] and self.commands[command].threaded then
			return true
		end
	end
	return false
end

function irc:call_command(state, channel, message)
	local status, result, err = pcall(self.run_command, self, state, channel, message)
	if status and not err then
		return result
	else
		local error_reporting = self:get_config("error_reporting", channel)
		if not error_reporting then
			return
		end
		if err then
			self:error(state.nick, err)
		else
			--if (error_reporting.admin_debug and self:admin_user_mode(state.nick, "v")) or not error_reporting.admin_debug then
			if not (error_reporting.admin_debug and not self:admin_user_mode(state.nick, "v")) then
				self:error(state.nick, result)
				return
			end
			if not error_reporting.public_debug then
				result = result:match(".-:%d+: (.+)")
			end
			self:error(state.nick, result)
		end
	end
end

function irc:run_command(state, channel, message)
	local funcs = {function() return "" end}

	local error
	local split, err = utils.split_format(message, "|", function(s)
		local result, err = self:run_command(state, channel, s)
		if err then
			error = err
			return
		end
		return result or ""
	end)

	if error then
		return nil, error
	elseif not split then
		return nil, err
	end

	for i, e_message in ipairs(split) do
		e_message = utils.lstrip(e_message)
		local command, str = e_message
		if e_message:find(" ") then
			command, str = unpack(utils.split(e_message, " ", 1))
		end
		if not command then
			return nil, "Invalid command"
		end
		str = str or ""

		local func = function(self)
			local last_func_return, err = funcs[i](self)-- or ""
			if err then
				return nil, err
			end
			last_func_return = last_func_return or ""
			local last_char = str:sub(-1)
			if i == 1 and #split >= 2 then
				if last_char == " " then
					str = str:sub(1, -2)
				end
			elseif last_char ~= " " and last_char ~= "" and last_func_return ~= "" then
				str = str .. " "
			end

			str = str .. last_func_return
			command = command:lower()

			if self.commands[command] then
				local arguments, err = utils.parse_arguments(str, unpack(self.commands[command].arguments))
				if not arguments then
					return nil, err
				end
				if self:call_hook("on_user_cmd", command, state, channel, unpack(arguments)) then
					return nil
				end
				return self.commands[command].func(self, state, channel, unpack(arguments))
			else
				if self:call_hook("on_user_cmd", command, state, channel, str) then
					return nil
				end
				return self:call_hook("on_unknown_user_cmd", command, state, channel, str)
			end
		end
		funcs[#funcs + 1] = func
		if i == #split then
			return funcs[#funcs](self)
		end
	end
end

function irc:error(channel, err)
	self:notice(channel, "Error: " .. tostring(err))
end

function irc:lower(s)
	return (utils[(self.isupport.CASEMAPPING or "rfc1459") .. "_lower"])(s)
end

function irc:send(...)
	local formatted = self:format_msg(...)

	if formatted:find("[%z\r\n]") then
		print(("\nFound invalid char in %q\n"):format(formatted))
		return -- most probably some command did something bad
	end

	if self:call_hook("on_send", formatted, ...) then
		return
	end
	if self:call_hook("on_send_" .. (...):lower(), formatted, select(2, ...)) then
		return
	end
	--local max_message_length = 512 - 2 - self.self_prefix_length - 2
	formatted = formatted:sub(1, 512 - 2)
	table.insert(self.queue, formatted)
end

function irc:quit(msg)
	self.running = false
	self:send("QUIT", msg)
end

function irc:privmsg(channel, msg)
	if not msg or msg == "" then
		return
	end

	msg = self:optimize_format(msg)
	if msg:find("%z") then
		local list = utils.unescape_list(msg)
		msg = table.concat(list, ", ")
	end

	if not msg or msg == "" then
		return
	end

	self:send("PRIVMSG", channel, msg)
end

function irc:notice(channel, msg)
	if not msg or msg == "" then
		return
	end

	msg = self:optimize_format(msg)
	if msg:find("%z") then
		local list = utils.unescape_list(msg)
		msg = table.concat(list, ", ")
	end

	if not msg or msg == "" then
		return
	end

	self:send("NOTICE", channel, msg)
end

function irc:ctcp_notice(channel, msg)
	self:notice(channel, "\001" .. msg .. "\001")
end

function irc:ctcp_privmsg(channel, msg)
	self:privmsg(channel, "\001" .. msg .. "\001")
end

function irc:action(msg)
	return "\001ACTION " .. msg .. "\001"
end

function irc:join(channels, keys)
	if type(channels) == "string" then
		channels = utils.split(channels, ",")
	end
	keys = keys or {}
	if type(keys) == "string" then
		keys = utils.split(keys, ",")
	end

	local buckets = {0}
	local send_channels = {{}}
	local send_keys = {{}}

	for i = 1, #channels do
		local channel = utils.strip(channels[i])
		local key = utils.strip(keys[i] or "")

		local _, err = self:is_valid_channel(channel)
		if channel == "0" then
			return nil, "Joining channel 0 is disabled"
		elseif err then
			return nil, err
		elseif self.channels[self:lower(channel)] then
			return nil, "Can't join a channel I'm already in (" .. channel .. ")"
		end

		buckets[#buckets] = buckets[#buckets] + #channel + #key + 2
		if buckets[#buckets] > 300 or #send_channels[#buckets] >= 8 then
			buckets[#buckets + 1] = 0
			send_channels[#buckets + 1] = {}
			send_keys[#buckets + 1] = {}
		end
		table.insert(send_channels[#buckets], channel)
		table.insert(send_keys[#buckets], key)
	end

	for i = 1, #send_channels do
		local channels = send_channels[i]
		local keys = send_keys[i]
		self:send("JOIN", table.concat(channels, ","), table.concat(keys, ","))
	end

	return true
end

function irc:bold(s)
	return "\002" .. s .. "\002"
end
function irc:italics(s)
	return "\029" .. s .. "\029"
end
function irc:underline(s)
	return "\031" .. s .. "\031"
end
function irc:reverse_color(s)
	return "\022" .. s .. "\022"
end

irc.colors = {
	white = 0, black = 1, darkblue = 2, darkgreen = 3, red = 4, darkred = 5,
	darkpurple = 6, orange = 7, yellow = 8, green = 9, teal = 10,
	lightblue = 11, blue = 12, purple = 13, gray = 14, lightgray = 15
}
function irc:color(s, color, background)
	if not (self.colors[color] or self.colors[background]) then
		return
	end
	local color_code = self.colors[color] or ""

	if self.colors[background] then
		color_code = color_code .. "," .. self.colors[background]
	end

	return "\003" .. self:fix_color(color_code, s) .. "\003"
end

function irc:fix_color(color_code, s)
	color_code = tostring(color_code)
	if color_code:find(",") then
		local color = color_code:sub(1, color_code:find(",") - 1)
		local background = color_code:sub(color_code:find(",") + 1)
		return color .. "," .. self:fix_color(background, s)
	elseif not s then
		return ("0"):rep(2 - #color_code) .. color_code
	elseif s:match("^%d") then
		return ("0"):rep(2 - #color_code) .. color_code .. s
	else
		return color_code .. s
	end
end

function irc:optimize_format(s)
	s = tostring(s)
	s = s:gsub("\002(%s*)\002", "%1") -- bold
	s = s:gsub("\029(%s*)\029", "%1") -- italics

	s = s:gsub("\031+", function(u) return ("\031"):rep(#u % 2) end) -- underline
	s = s:gsub("\022+", function(r) return ("\022"):rep(#r % 2) end) -- reverse color

	s = s:gsub("\015+", "\015") -- color reset

	-- \003 optimize colors
	local split = utils.split(s, "\003")

	local last_foreground = "-1"
	local last_background = "-1"

	local out = split[1] or ""
	local using_colors = false
	for i = 2, #split do
		local str = split[i]
		local foreground = str:match("^%d%d?")
		local background = str:match("^,%d%d?", 1 + (foreground and #foreground or 0))
		local str = str:sub(1 + (foreground and #foreground or 0) +
		                        (background and #background or 0))
		if foreground or background then
			using_colors = true

			foreground = foreground or last_foreground
			background = background or last_background

			if foreground ~= last_foreground or background ~= last_background then
				out = out .. "\003"
				if foreground ~= last_foreground and s:find("%S") then
					out = out .. foreground
					last_foreground = foreground
				end
				if background ~= last_background and s ~= "" then
					out = out .. background
					last_background = background
				end
			end
		else
			if using_colors then
				out = out .. "\003"
				using_colors = false
			end
		end
		out = out .. str
	end
	return out
end

function irc:strip_color(s)
	return (s:gsub("\3%d?%d?,%d%d?", ""):gsub("\3%d%d?", ""):gsub("\3", ""))
end

function irc:strip_foreground_color(s)
	return (s:gsub("\3%d?%d?,(%d%d?)", "\3,%1"):gsub("\3%d%d?", ""))
end

function irc:strip_background_color(s)
	return (s:gsub("\3(%d?%d?),%d%d?)", "\3%1"):gsub("\3,", ""))
end

function irc:strip_style(s)
	s = self:strip_color(s)
	s = s:gsub("[\2\15\22\29\31]", "")
	-- bold, color reset, reverse color, italics, underline
	return s
end

return irc
