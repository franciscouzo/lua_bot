local bit32 = require("bit32")
local lanes = require("lanes")

local utils = require("irc.utils")

local function numeric_ip(ip)
	ip = utils.split(ip, ".")
	assert(#ip == 4, "Invalid ip")
	local numeric = 0
	for i, part in ipairs(ip) do
		part = tonumber(part)
		assert(part, "Invalid ip")
		assert(part < 256)
		numeric = numeric + part * (2 ^ (32 - i * 8))
	end
	return numeric
end

local function dotted_ip(numeric)
	assert(numeric >= 0 and numeric <= 2 ^ 32, "Invalid ip")
	local dotted = {}
	for i = 3, 0, -1 do
		dotted[#dotted + 1] = bit32.band(bit32.rshift(numeric, i * 8), 255)
	end
	return table.concat(dotted, ".")
end

local dcc = {}

dcc.dcc_list = function(irc, state, channel, msg)
	local files = {}
	for file in pairs(irc.linda:get("dcc.files")) do
		files[#files + 1] = file
	end
	return utils.escape_list(files)
end

dcc.dcc_download = function(irc, state, channel, filename)
	assert(irc:get_config("dcc", channel)[filename], "Invalid file")
	local port
	if irc.config.dcc.random_port then
		port = 0
	else
		local used_ports = irc.linda:get("dcc.used_ports")

		for used_port, used in pairs(used_ports) do
			if not used then
				port = used_port
				break
			end
		end
		assert(port, "All ports in use")

		used_ports[port] = true
		irc.linda:set("dcc.used_ports", used_ports)
	end
	
	local file = assert(io.open(irc:get_config("dcc", channel).folder .. filename, "r"))
	local current = file:seek()
	local filesize = file:seek("end")
	file:seek("set", current)

	local socket = require("socket")
	local server = assert(socket.bind("*", port))
	local _, port = server:getsockname()

	local ip = numeric_ip(irc:get_config("dcc", channel).ip)
	
	irc:ctcp_privmsg(state.nick, ("DCC SEND %s %s %s %s"):format(filename, ip, port, filesize))

	server:settimeout(irc:get_config("dcc", channel).timeout or 60)
	local conn, err = server:accept()

	server:close()

	if conn then
		while true do
			local block = file:read(4096)
			if not block then
				break
			end
			conn:send(block)
		end
	end

	if not irc:get_config("dcc", channel).random_port then
		used_ports[port] = false
		irc.linda:set("dcc.used_ports", used_ports)
	end

	file:close()
	conn:close()
end

return function(irc)
	if not irc.config.dcc.random_port then
		local used_ports = {}
		for i = irc.config.dcc.port_start, irc.config.dcc.port_end do
			used_ports[i] = false
		end
		irc.linda:set("dcc.used_ports", used_ports)
	end

	--[[irc:add_hook("dcc", "on_privmsg_ctcp_dcc", function(irc, state, channel, message)
		args = utils.split(message, " ")
		local command = table.remove(args, 1)
		if command == "SEND" then
			--someone is sending us a file
			lanes.gen("*", function()
				local filename, ip, port, filesize = unpack(args)
				ip = assert(tonumber(ip), "Invalid number")
				ip = dotted_ip(ip)
				port = assert(tonumber(port), "Invalid port")
				filesize = assert(tonumber(filesize), "Invalid filesize")

				local socket = require("socket")
				local conn = assert(socket.connect(ip, port))

				while true do
					local block = conn:read(4096)
					if not block then
						break
					end
				end
				conn:close()
			end)()
		end
	end)]]
	
	irc:add_command("dcc", "dcc_list", dcc.dcc_list, false)
	irc:add_command("dcc", "dcc_download", dcc.dcc_download, true)
end