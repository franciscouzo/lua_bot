local utils = require("irc.utils")

local CleverbotSession = {
	url = "http://www.cleverbot.com/webservicemin",
	vars_order = {
		sessionid=2, logurl=3, vText8=4, vText7=5, vText6=6, vText5=7,
		vText4=8, vText3=9, vText2=10, prevref=11, emotionalhistory=13,
		ttsLocMP3=14, ttsLocTXT=15, ttsLocTXT3=16, ttsText=17, lineRef=18,
		lineURL=19, linePOST=20, lineChoices=21, lineChoicesAbbrev=22,
		typingData=23, divert=24
	}
}

function CleverbotSession:new()
	local http = require("socket.http") -- fucking
	http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

	local o = setmetatable({}, self)
	self.__index = self

	o.vars = {
		start="y", icognoid="wsf", fno="0", sub="Say",
		islearning="1", cleanstate="false"
	}

	local _, _, headers = http.request('http://www.cleverbot.com')

	o.cookie = headers['set-cookie']:match("[^;]+")
	return o
end

function CleverbotSession:ask(message)
	local http = require("socket.http") -- fucking
	http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
	local url = require("socket.url")   -- la
	local ltn12 = require("ltn12")      -- nes
	local success, md5 = pcall(require, "md5")
	local md5_hex
	if not success then
		local success, hash = pcall(require, "irc.modules.hash.hash")
		assert(success, "No md5 module found")
		md5_hex = function(s)
			local hash_md5 = hash.md5()
			hash_md5:process(s)
			return hash_md5:finish()
		end
	else
		md5_hex = md5.sumhexa
	end

	self.vars.stimulus = url.escape(message)
	local data = {}
	for k, v in pairs(self.vars) do
		data[#data + 1] = url.escape(k) .. "=" .. url.escape(v)
	end
	local data = table.concat(data, "&")
	data = data .. "&icognocheck=" .. md5_hex(data:sub(10, 35))

	local response = {}

	local _, response_code, response_headers, response_status = http.request {
		method = "POST",
		url = self.url,
		source = ltn12.source.string(data),
		headers = {
			["Cookie"] = self.cookie,
			["content-type"] = "text/plain",
			["content-length"] = tostring(#data)
		},
		sink = ltn12.sink.table(response)
	}

	response = table.concat(response)
	assert(response_code == 200, "Error requesting page")

	response = utils.split(response, "\r")
	--local vars = {}
	--for var in (response .. "\r"):gmatch("([^\r]*)\r") do
	--	vars[#vars + 1] = var
	--end
	for k, v in pairs(self.vars_order) do
		self.vars[k] = response[v] or ""
		--self.vars[k] = vars[v] or ""
	end

	local html = require("irc.html")
	return html.unescape(self.vars.ttsText)
end

return function(irc)
	irc.linda:set("cleverbot.session", CleverbotSession:new())
	irc:add_command("cleverbot", "cleverbot", function(irc, state, channel, msg)
		local session = irc.linda:get("cleverbot.session")
		local response, err = session:ask(msg)
		irc.linda:set("cleverbot.session", session)
		return response, err
	end, true)
end