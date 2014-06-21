return function(irc, state, channel, msg)
	local fml_cache = irc.linda:get("generators.fml.cache") or {}
	if #fml_cache == 0 then
		local http = require("socket.http")
		local html = require("irc.html")
		local response, response_code = http.request("http://www.fmylife.com/random/")
		assert(response_code == 200, "Error requesting page")
		for id, fml in response:gmatch('<div class="post article" id="(%d+)">(.-)</div>') do
			fml = fml:match("<p>(.-)</p>")
			fml = fml:gsub("<.->(.-)<.->", "%1")
			fml = html.unescape(fml)
			fml = fml:sub(1, 350)
			table.insert(fml_cache, fml)
		end
	end

	local text = table.remove(fml_cache)

	irc.linda:set("generators.fml.cache", fml_cache)
	return text
end