local utils = require("irc.utils")
local json = require("json")

return function(irc)
	irc:add_command("shorten", "shorten", function(irc, state, channel, msg)
		assert(utils.strip(msg) ~= "", "Invalid url")

		local http = require("socket.http")
		local url = require("socket.url")

		local data = {
			format   = 'json',
			url      = msg,
			logstats = log_stat and "1" or "0",
			shorturl = custom_url
		}

		local http_data = {}
		for k, v in pairs(data) do
			table.insert(http_data, url.escape(k) .. "=" .. url.escape(v))
		end
		http_data = table.concat(http_data, "&")

		local response, response_code = http.request("http://is.gd/create.php", http_data)
		local response, pos, err = json.decode(response)

		assert(not err, err)
		assert(response.shorturl, response.errormessage or "Error requesting page")

		return response.shorturl
	end, true)
end