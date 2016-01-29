local html = require("irc.html")

return function(irc)
	local languages = {
		["c"] = "c", ["c++"] = "C++", ["d"] = "D", ["haskell"] = "Haskell",
		["lua"] = "Lua", ["ocaml"] = "OCaml", ["php"] = "PHP",
		["perl"] = "Perl", ["python"] = "Python", ["ruby"] = "Ruby",
		["scheme"] = "Scheme", ["tcl"] = "Tcl"
	}

	irc:add_command("codepad", "codepad", function(irc, state, channel, msg)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
		local url = require("socket.url")

		local language, code = msg:match("^(.-) (.+)$")
		assert(language and code, "Insufficient arguments")
		language = language:lower()
		assert(languages[language], "Invalid language")
		local _, _, headers = http.request("http://codepad.org", "run=True&submit=Submit&lang=" .. languages[language] .. "&code=" .. url.escape(code))
		assert(headers.location, "Unknown error")

		local response, response_code = http.request(headers.location)

		if response_code ~= 200 then
			irc:privmsg(channel, headers.location)
			return
		end

		local output = response:match("<pre>\n(.-)\n*</pre>")
		local lines = select(2, output:gsub("\n", "")) + 1

		if lines >= 2 or #output > 300 then
			irc:privmsg(channel, headers.location)
		else
			irc:notice(state.nick, headers.location)
			return html.unescape(output)
		end
	end, true)
end