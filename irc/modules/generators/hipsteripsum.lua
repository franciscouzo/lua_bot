return function(irc, state, channel, s)
	local http = require("socket.http")
	local json = require("json")

	local type = s == "" and "hipster-latin" or "hipster-centric"
	local url = "http://hipsterjesus.com/api/?html=false&paras=1&type=" .. type

	local ipsum, response_code = http.request(url)
	local obj, pos, err = json.decode(ipsum)

	assert(response_code == 200 and obj.text, "Error requesting page")
	assert(not err, err)

	return (obj.text:gsub("  ", " "))
end