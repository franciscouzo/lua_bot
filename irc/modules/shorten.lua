local utils = require("irc.utils")
local json = require("json")

return function(irc)
	irc:add_command("shorten", "shorten", function(irc, state, channel, url)
		assert(utils.strip(url) ~= "", "Invalid url")

		local https = require("ssl.https")
		local ltn12 = require("ltn12")

		local http_data = json.encode({longUrl=url})
		local url = "https://www.googleapis.com/urlshortener/v1/url" ..
		            "?key=" .. irc.config.google_api_key

		local response = {}
		local _, response_code = https.request({
			url = url,
			method = "POST",
			headers = {
				["Content-Length"] = http_data:len(),
				["Content-Type"] = "application/json"
			},
			source = ltn12.source.string(http_data),
			sink = ltn12.sink.table(response)
		})

		assert(response_code == 200, "Error requesting page")

		response = table.concat(response)

		local data, pos, err = json.decode(response)
		assert(not err, err)

		return data.id
	end, true)
end
