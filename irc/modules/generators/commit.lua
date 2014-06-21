return function()
	local http = require("socket.http")
	local response, response_code = http.request("http://whatthecommit.com/index.txt")
	assert(response_code == 200, "Error requesting page")
	return response:sub(1, 300)
end