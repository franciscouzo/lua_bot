local utils = require("irc.utils")

return function(irc)
	irc:add_hook("ctcp", "on_notice_ctcp_version", function(irc, state, channel, message)
		local versions = irc.linda:get("ctcp.versions")
		if not versions then
			return
		end
		local version = utils.split(message, " ")[1]
		if not version then
			return
		end
		versions[state.host] = version
		-- if versions ends between linda:get and linda:set, it would end up as garbage
		irc.linda:set("ctcp.versions", versions)
	end)
	irc:add_command("ctcp", "versions", function(irc, state, channel, wait)
		local socket = require("socket")
		--if irc.linda:get("ctcp.versions") then
			--return nil, "Version taking place"
		--end
		irc.linda:set("ctcp.versions", {})
		irc:ctcp_privmsg(channel, "VERSION")

		socket.sleep(wait or 5)

		local versions = irc.linda:get("ctcp.versions")
		local version_count = {}
		
		for mask, version in pairs(versions) do
			version_count[version] = (version_count[version] or 0) + 1
		end
		
		local sorted_count = {}
		for version, count in pairs(version_count) do
			table.insert(sorted_count, {version, count})
		end
		table.sort(sorted_count, function(a, b) return a[2] > b[2] end)
		
		local out = {}
		for i, version_count in ipairs(sorted_count) do
			local version, count = unpack(version_count)
			out[i] = ("%s: %s"):format(version, count)
		end

		irc.linda:set("ctcp.versions", nil)

		return table.concat(out, " | ")
	end, true, "+float...")
	irc:add_hook("ctcp", "on_notice_ctcp_ping", function(irc, state, channel, random_string)
		local nick = irc:lower(state.nick)
		if irc.linda:get("ctcp.ping.nick." .. nick) then
			irc.linda:set("ctcp.ping.received-" .. nick, true)
			irc.linda:set("ctcp.ping.nick." .. nick, nil)
		end
		local pings = irc.linda:get("ctcp.pings")
		if not pings or random_string ~= pings.random_string then
			return
		end

		pings.pings[state.host] = socket.gettime() - pings.time

		irc.linda:set("ctcp.pings", pings)
	end)
	irc:add_command("ctcp", "pings", function(irc, state, channel, wait)
		wait = wait or 3
		assert(wait >= 1,  "Wait time is too small")
		assert(wait <= 10, "Wait time is too big")
		assert(not irc.linda:get("ctcp.pings"), "Ping taking place")

		local socket = require("socket")

		local random_string = utils.random_string(16)
		local time = ("%.12f"):format(socket.gettime())
		irc.linda:set("ctcp.pings", {random_string=random_string, time=time, pings={}})
		irc:ctcp_privmsg(channel, "PING " .. random_string)

		socket.sleep(wait)

		local pings = irc.linda:get("ctcp.pings")
		local funcs, ping_count = {}, {}
		for i, n in ipairs({50, 100, 150, 200, 250, 500, 750, 1000}) do
			funcs[i] = {"<" .. n .. "ms", function(x) return x < (n / 1000) end}
			ping_count[i] = 0
		end
		table.insert(funcs, {">=1000ms", function(x) return x >= 1 end})
		table.insert(ping_count, 0)

		for mask, ping in pairs(pings.pings) do
			for i, func in ipairs(funcs) do
				if func[2](ping) then
					ping_count[i] = ping_count[i] + 1
					break
				end
			end
		end

		local out = {}
		for i, count in ipairs(ping_count) do
			out[i] = ("%s: %i"):format(funcs[i][1], count)
		end

		return table.concat(out, " | ")
	end, true, "+float...")

	irc:add_command("ctcp", "ping", function(irc, state, channel, nick)
		local socket = require("socket")
		nick = irc:lower(utils.strip(nick))
		local random_string = utils.random_string(16)

		local start = socket.gettime()
		irc:ctcp_privmsg(nick, "PING " .. random_string)
		irc.linda:set("ctcp.ping.nick." .. nick, true)
		local ping = irc.linda:receive(5, "ctcp.ping.received-" .. nick)
		irc.linda:set("ctcp.ping.nick." .. nick, nil)
		irc.linda:set("ctcp.ping.received-" .. nick, nil)
		assert(ping, "timeout")

		local n = socket.gettime() - start

		return ("%.8f"):format(n)
	end, true)

	irc:add_hook("ctcp", "on_privmsg_ctcp_version", function(irc, state, channel, message)
		irc:ctcp_notice(state.nick, "VERSION lua_bot 0.1")
	end)
	irc:add_hook("ctcp", "on_privmsg_ctcp_source", function(irc, state, channel, message)
		irc:ctcp_notice(state.nick, "SOURCE https://github.com/franciscouzo/lua_bot/")
	end)
	irc:add_hook("ctcp", "on_privmsg_ctcp_ping", function(irc, state, channel, message)
		irc:ctcp_notice(state.nick, "PING " .. message)
	end)
	irc:add_hook("ctcp", "on_privmsg_ctcp_time", function(irc, state, channel, message)
		irc:ctcp_notice(state.nick, "TIME " .. os.date())
	end)
	irc:add_hook("ctcp", "on_privmsg_ctcp_clientinfo", function(irc, state, channel, message)
		irc:ctcp_notice(state.nick, "CLIENTINFO ACTION CLIENTINFO DCC PING SOURCE TIME VERSION")
	end)
end
