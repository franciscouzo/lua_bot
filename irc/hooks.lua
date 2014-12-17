local utils = require("irc.utils")
local ansi = require("irc.ansi")

return function(irc)
	irc.lag = 1
	irc:add_hook("hooks", "on_init", function(irc)
		local socket = require("socket")
		while true do
			-- sending regular pings makes us more resistant to timeouts
			socket.sleep(60)
			irc:send("PING", tostring(socket.gettime()))
		end
	end, true)
	irc:add_hook("hooks", "on_cmd_pong", function(irc, state, server, lag)
		lag = tonumber(lag)
		if lag then
			local socket = require("socket")
			irc.lag = socket.gettime() - lag
		end
	end)

	irc:add_hook("hooks", "on_connect", function(irc)
		irc.isupport = utils.deepcopy(irc.isupport_default)

		irc.capabilities_in_common = {}
		irc.received_capabilities = {}
		irc.sasl_authentication_mechanisms = {}

		irc:send("CAP", "LS", "302")
		if irc.config.pass then
			irc:send("PASS", irc.config.pass)
		end
		irc:send("NICK", irc.nick)
		irc:send("USER", irc.username, "8", "*", irc.realname)

		-- we are reconnecting, if irc.channels is present we can rejoin
		if irc.channels and irc.config.rejoin_on_reconnect then
			local channels = {}
			for channel in pairs(irc.channels) do
				table.insert(channels, channel)
			end
			irc.channels = {}
			irc:join(channels)
		else
			irc.channels = {}
		end
	end)
	irc:add_hook("hooks", "on_quit", function(irc)
		io.write("\b\b")
		print("quitting")
	end)
	irc:add_hook("hooks", "on_cmd", function(irc, command, state, ...)
		if command == "PING" or command == "PONG" then
			return
		end
		if state.nick and irc:lower(state.nick) == irc:lower(irc.nick) then
			irc.self_prefix = state.prefix -- to know at what length to wrap lines
			-- also useful for the self-message capability
		end

		if state.nick and state.user and state.host then
			irc:update_user(state.nick, "user", state.user)
			irc:update_user(state.nick, "host", state.host)
			if irc.capabilities_in_common["account-tag"] then
				irc:update_user(state.nick, "account", state.tags.account ~= nil and state.tags.account or nil)
			end
		end
		
		local date = os.date("%X", state.time)
		print(("[%s] server: %s"):format(date, ansi.mirc_to_ansi(ansi.strip(state.line))))
	end)
	irc:add_hook("hooks", "on_send", function(irc, line, command)
		if command ~= "PONG" and command ~= "PING" then
			print(("[%s] client: %s"):format(os.date("%X"), ansi.mirc_to_ansi(ansi.strip(line))))
		end
	end)

	irc:add_hook("hooks", "on_cmd_ping", function(irc, state, ping_code)
		irc:send("PONG", ping_code)
	end)

	local function parse_capability(capability)
		local modifiers, capability, value = capability:match("^([-=~]*)([^=]+)=?(.*)$")
		return {
			["-"] = not not modifiers:find("-"),
			["="] = not not modifiers:find("="),
			["~"] = not not modifiers:find("~")
		}, capability, value
	end
	irc:add_hook("hooks", "on_cmd_cap", function(irc, state, _, subcommand, server_capabilities1, server_capabilities2)
		local server_capabilities = server_capabilities1
		local finish_server_capabilities = true
		if server_capabilities2 and server_capabilities1 == "*" then
			server_capabilities = server_capabilities2
			finish_server_capabilities = false
		end
		server_capabilities = utils.strip(server_capabilities) -- unreal is sending an extra space
		if subcommand == "LS" then
			server_capabilities = utils.split(server_capabilities, " ")
			local capabilities_in_common = {}
			for _, capability in ipairs(server_capabilities) do
				local modifiers, capability, value = parse_capability(capability)
				if irc.supported_capabilities[capability] then
					if not (capability == "sasl" and not irc.config.sasl_pass) then
						-- ignore sasl when we have no sasl password
						table.insert(capabilities_in_common, capability)
					end
				end
				irc.received_capabilities[capability] = value
			end
			irc:send("CAP", "REQ", table.concat(capabilities_in_common, " "))
		elseif subcommand == "ACK" or subcommand == "NEW" then
			for _, capability in ipairs(utils.split(server_capabilities, " ")) do
				local modifiers, capability = parse_capability(capability)
				irc.capabilities_in_common[capability] = not modifiers["-"] and true or nil
			end

			if finish_server_capabilities then
				if irc.capabilities_in_common.sasl then
					-- parse ircv3.2 sasl reply
					irc.sasl_authentication_mechanisms = {}
					if irc.received_capabilities.sasl == "" then
						irc.sasl_authentication_mechanisms.PLAIN = true
					else
						for i, mechanism in ipairs(utils.split(irc.received_capabilities.sasl, ",")) do
							irc.sasl_authentication_mechanisms[mechanism] = true
						end
					end

					if irc.sasl_authentication_mechanisms.PLAIN then
						irc:send("AUTHENTICATE", "PLAIN")
					else
						irc:send("CAP", "END")
					end
				else
					irc:send("CAP", "END")
				end
			end
		elseif subcommand == "NAK" then -- the fuck
			irc:send("CAP", "END")
		end
	end)

	for _, sasl_reply in ipairs({"RPL_SASLSUCCESS", "ERR_SASLFAIL", "ERR_SASLTOOLONG", --[["ERR_SASLABORTED",]] "ERR_SASLALREADY"}) do
		irc:add_hook("hooks", "on_" .. sasl_reply:lower(), function(irc, state, ...)
			irc:send("CAP", "END")
		end)
	end
	local function authenticate(irc, mechanism)
		if not irc.config.sasl_pass then
			irc:send("AUTHENTICATE", "*")
			return true
		elseif mechanism == "PLAIN" then
			local mime = require("mime")
			local auth = irc.nick .. "\000" .. irc.nick .. "\000" .. irc.config.sasl_pass
			auth = mime.b64(auth)

			while #auth >= 400 do
				local out = auth:sub(1, 400)
				auth = auth:sub(401)
				irc:send("AUTHENTICATE", out)
			end

			irc:send("AUTHENTICATE", #auth >= 1 and auth or "+")
			return true -- success
		else
			-- unknown mechanism
		end
	end
	
	irc:add_hook("hooks", "on_rpl_saslmechs", function(irc, state, nick, mechanisms)
		irc.sasl_authentication_mechanisms = {}
		for mechanism in ipairs(utils.split(mechanisms, ",")) do
			irc.sasl_authentication_mechanisms[mechanism] = true
		end
		for mechanism in pairs(irc.sasl_authentication_mechanisms) do
			if authenticate(irc, mechanism) then
				return
			end
		end
		irc:send("AUTHENTICATE", "*")
		-- unknown authentication mechanism
	end)

	irc:add_hook("hooks", "on_cmd_authenticate", function(irc, state, mechanism)
		if mechanism == "+" then
			for mechanism in pairs(irc.sasl_authentication_mechanisms) do
				if authenticate(irc, mechanism) then
					return
				end
			end
		end
		irc:send("AUTHENTICATE", "*")
	end)
	
	irc:add_hook("hooks", "on_rpl_welcome", function(irc)
		local socket = require("socket")
		if irc.config.nickserv_pass then
			irc:privmsg("NickServ", irc.config.nickserv_pass)
			socket.sleep(5)
			-- Sometimes when you join too fast you might leak your host
			-- Although an attacker could view your host if he used monitor/watch before it was activated
		end
		irc:send("PING", tostring(socket.gettime()))

		local on_connect = irc.config.on_connect or {}
		for _, message in ipairs(utils.listify(on_connect)) do
			irc:send(message)
		end

		local channels = {}
		local keys = {}
		for channel, channel_data in pairs(irc.config.channels or {}) do
			if channel_data.autojoin == nil or channel_data.autojoin then
				table.insert(channels, channel)
				table.insert(keys, channel_data.key or "")
			end
		end
		irc:join(channels, keys)
	end)

	local function parse_isupport_token(irc, token)
		if token:sub(1, 1) == "-" then
			token = token:sub(2)
			irc.isupport[token] = nil
			return
		end

		local k, v = token, ""
		if token:find("=") then
			k, v = unpack(utils.split(token, "=", 1))
		end

		v = v:gsub("\\x(%x%x)", function(s) return string.char(tonumber(s, 16)) end)
		
		if v == "" then
			if k == "EXCEPT" or k == "INVEX" then
				irc.isupport[k] = irc.isupport_default[k]
			else
				irc.isupport[k] = true
			end
		elseif k == "PREFIX" then
			irc.isupport["PREFIX"] = {}
			local modes, prefixes = v:match("^%((.+)%)(.+)$")
			if modes then
				for i = 1, math.min(#modes, #prefixes) do
					local mode, prefix = modes:sub(i, i), prefixes:sub(i, i)
					table.insert(irc.isupport["PREFIX"], {mode, prefix})
				end
			end
		elseif v:find(":") then
			irc.isupport[k] = {}
			for _, v in ipairs(utils.split(v, ",")) do
				local k2, v2 = unpack(utils.split(v, ":"))
				irc.isupport[k][k2] = tonumber(v2) or v2
			end
		elseif v:find(",") then
			irc.isupport[k] = utils.split(v, ",")
		else
			irc.isupport[k] = tonumber(v) or v
		end
		
		if k == "NAMESX" or k == "UHNAMES" then
			irc:send("PROTOCTL", k)
		end
	end
	irc:add_hook("hooks", "on_rpl_isupport", function(irc, prefix, nick, ...)
		args = {...}
		for i = 1, #args - 1 do -- " :Are supported by this server"
			parse_isupport_token(irc, args[i])
		end
	end)

	irc:add_hook("hooks", "on_rpl_namreply", function(irc, state, nick, channel_mode, channel, nicks)
		local match_nick = "("
		for _, v in ipairs(irc.isupport["PREFIX"]) do
			local mode, prefix = v[1], v[2]
			match_nick = match_nick .. "%" .. prefix .. "?"
		end
		match_nick = match_nick .. ")(.+)"

		for _, nick in ipairs(utils.split(utils.strip(nicks), " ")) do
			local nick_host, user, host = nick:match("(.-)!(.-)@(.+)")
			nick = (nick_host or nick)

			local nick_modes, nick = nick:match(match_nick)
			local modes = {}
			for v in nick_modes:gmatch(".") do
				modes[v] = true
			end

			irc:new_user(channel, nick, {modes = modes, user = user, host = host})
		end
	end)
	irc:add_hook("hooks", "on_rpl_topic", function(irc, state, nick, channel, topic)
		irc:get_channel(channel).topic = topic or ""
	end)
	irc:add_hook("hooks", "on_cmd_topic", function(irc, state, channel, topic)
		irc:get_channel(channel).topic = topic or ""
	end)
	irc:add_hook("hooks", "on_cmd_mode", function(irc, state, channel, ...)
		irc:parse_modes(channel, {...})
	end)
	irc:add_hook("hooks", "on_cmd_account", function(irc, state, account)
		irc:update_user(state.nick, "account", account ~= "*" and account or nil)
	end)
	irc:add_hook("hooks", "on_cmd_away", function(irc, state, seconds_or_away, away)
		-- KineIRCd <nick> <seconds away> :<message> 
		away = away or seconds_or_away
		if not (state.nick and away) then
			return -- server command
		end
		irc:update_user(state.nick, "away", away)
	end)
	irc:add_hook("hooks", "on_cmd_chghost", function(irc, state, user, host)
		if not (user and host) then
			return
		end
		irc:update_user(state.nick, "user", user)
		irc:update_user(state.nick, "host", host)
	end)
	irc:add_hook("hooks", "on_cmd_join", function(irc, state, channel, account, realname)
		account = account ~= "*" and account or nil
		irc:new_user(channel, state.nick, {user = state.user, host = state.host, account = account, realname = realname})
	end)
	irc:add_hook("hooks", "on_cmd_nick", function(irc, state, nick)
		if irc:lower(state.nick) == irc:lower(irc.nick) then
			irc.nick = nick
		end
		for _, channel in pairs(irc.channels) do
			if channel.users[irc:lower(state.nick)] then
				local old_nick = channel.users[irc:lower(state.nick)]
				channel.users[irc:lower(state.nick)] = nil
				channel.users[irc:lower(nick)] = old_nick or {}
				channel.users[irc:lower(nick)].nick = nick
			end
		end
	end)
	irc:add_hook("hooks", "on_cmd_part", function(irc, state, channel)
		if irc:lower(state.nick) == irc:lower(irc.nick) then
			irc.channels[irc:lower(channel)] = nil
		elseif irc.channels[irc:lower(channel)] then
			irc.channels[irc:lower(channel)].users[irc:lower(state.nick)] = nil
		end
	end)
	irc:add_hook("hooks", "on_cmd_quit", function(irc, state, reason)
		for _, channel in pairs(irc.channels) do
			channel.users[irc:lower(state.nick)] = nil
		end
	end)
	irc:add_hook("hooks", "on_cmd_kick", function(irc, state, channel, whom, reason)
		if irc:lower(whom) == irc:lower(irc.nick) then
			irc.channels[irc:lower(channel)] = nil
		elseif irc.channels[irc:lower(channel)] then
			irc.channels[irc:lower(channel)].users[irc:lower(whom)] = nil
		end
	end)

	local function parse_ctcp(irc, state, channel, message)
		if state.tags.intent then
			return state.tags.intent, message
		elseif message:sub(1, 1) == "\001" and message:sub(-1) == "\001" then
			message = message:sub(2, -2)
			local ctcp_command, ctcp_message = unpack(utils.split(message, " ", 1))
			return ctcp_command or "", ctcp_message or ""
		end
	end

	irc:add_hook("hooks", "on_cmd_privmsg", function(irc, state, channel, message)
		if state.prefix == irc.self_prefix then
			-- self-message
			local formatted = irc:format_msg("PRIVMSG", channel, message)
			irc:call_hook("on_send_privmsg", formatted, channel, message)
			return
		end
		local ctcp_command, ctcp_message = parse_ctcp(irc, state, channel, message)
		if ctcp_command then
			if not irc:call_hook("on_privmsg_ctcp", ctcp_command:upper(), state, channel, ctcp_message) then
				irc:call_hook("on_privmsg_ctcp_" .. ctcp_command:lower(), state, channel, ctcp_message)
			end
			return -- we don't want normal commands receiving ctcp messages
		end
		for _, prefix in ipairs(irc:get_config("prefixes", channel)) do
			prefix = prefix:format(irc.nick)
			message = utils.lstrip(message)
			if message:sub(1, #prefix) == prefix then
				message = message:sub(#prefix + 1)
				if irc:is_threaded(message) then
					irc:command_thread(state, channel, message)
				else
					local result = irc:call_command(state, channel, message)
					if result then
						irc:privmsg(channel, result)
					end
				end
				return
			end
		end
		irc:call_hook("on_non_cmd_privmsg", state, channel, message)
	end)
	irc:add_hook("hooks", "on_cmd_notice", function(irc, state, channel, message)
		if state.prefix == irc.self_prefix then
			-- self-message
			local formatted = irc:format_msg("NOTICE", channel, message)
			irc:call_hook("on_send_notice", formatted, channel, message)
			return
		end
		local ctcp_command, ctcp_message = parse_ctcp(irc, state, channel, message)
		if ctcp_command then
			if not irc:call_hook("on_notice_ctcp", ctcp_command:upper(), state, channel, ctcp_message) then
				irc:call_hook("on_notice_ctcp_" .. ctcp_command:lower(), state, channel, ctcp_message)
			end
		end
	end)

	for _, module_name in pairs(irc.config.modules or {}) do
		local module = require("irc.modules." .. module_name)
		if type(module) == "table" then
			irc:module_set_threaded(module_name, module.threaded)
			module = module.func
		end
		if type(module) ~= "function" then
			error("module must return a function (" .. module_name .. ")")
		end
		module(irc)
	end
end
