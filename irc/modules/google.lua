local utils = require("irc.utils")
local html = require("irc.html")

return function(irc)
	irc:add_command("google", "google", function(irc, state, channel, msg)
		local result_n, msg = msg:match("^(%d*) ?(.+)")

		result_n = tonumber(result_n) or 1
		result_n = math.max(1, result_n)
		result_n = math.min(8, result_n)

		local search_url = "https://ajax.googleapis.com/ajax/services/search/web"
		local http = require("socket.http")
		local url  = require("socket.url")

		local response, response_code = http.request(search_url .. "?q=" .. url.escape(msg) .. "&v=1.0")
		assert(response_code == 200, "Error requesting page")

		local json = require("json")
		local obj, pos, err = json.decode(response)
		assert(not err, err)

		local first_result = assert(obj.responseData.results[result_n], "No results")
		local result_url = first_result.unescapedUrl
		local content = first_result.content:gsub("</?b>", "\002"):gsub("\n", " ")
		content = html.unescape(content)

		return ("%s - %s"):format(result_url, content)
	end, true)
	irc:add_command("google", "youtube", function(irc, state, channel, msg)
		local search_url = "https://gdata.youtube.com/feeds/api/videos"
		local http = require("socket.http")
		local url  = require("socket.url")

		local response, response_code = http.request(search_url .. "?q=" .. url.escape(msg) .. "&v=2&alt=jsonc")
		assert(response_code == 200, "Error requesting page")

		local json = require("json")
		local obj, pos, err = json.decode(response)
		assert(not err, err)

		local item = obj.data.items[1]
		local title = html.unescape(item.title)
		return ("https://youtu.be/%s - [%i:%02i] %s"):format(item.id, item.duration / 60, item.duration % 60, title)
	end, true)
	irc:add_command("google", "youtube_random", function(irc, state, channel, msg)
		local http = require("socket.http")
		local youtube_id, response_code = http.request("http://www.youtuberandomvideo.com/get_video.php")
		assert(response_code == 200, "Error requesting page")
		return "https://youtu.be/" .. youtube_id
	end, true)
	irc:add_command("google", "search_image", function(irc, state, channel, msg)
		local result_n, msg = msg:match("^(%d*) ?(.+)")

		result_n = tonumber(result_n) or 1
		result_n = math.max(1, result_n)
		result_n = math.min(8, result_n)

		local search_url = "https://ajax.googleapis.com/ajax/services/search/images"

		local http = require("socket.http")
		local url  = require("socket.url")

		local response, response_code = http.request(search_url .. "?v=1.0&start=0&q=" .. url.escape(msg))
		assert(response_code == 200, "Error requesting page")

		local json = require("json")
		local obj, pos, err = json.decode(response)
		assert(not err, err)

		local item = assert(obj.responseData.results[result_n], "No results")
		return item.url
	end, true)
	irc:add_command("google", "calc", function(irc, state, channel, msg)
		assert(utils.strip(msg) ~= "", "Empty request")
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		local url  = require("socket.url")

		local uri = "https://www.google.com/search?gbv=1&q=" .. url.escape(msg)
		local response, response_code = http.request(uri)
		assert(response_code == 200, "Error requesting page")

		local answer = response:match('<h2 class="r"[^>]*>(.*)</h2>')
		if not answer then
			answer = response:match('<div id="aoba"[^>]*>(.*)</div>')
			assert(answer, "Couldn't find answer")
		end

		answer = answer:gsub("<sup>", "^(")
		answer = answer:gsub("</sup>", "(")
		answer = utils.strip(answer)

		return answer
	end, true)
	irc:add_command("google", "c", function(irc, state, channel, msg)
		local result = irc:run_command(state, channel, "calc " .. msg)
		result = result:match("^.-=(.+)")
		assert(result, "wut")
		return utils.strip(result)
	end, true)

	-- idk why it doesn't works
	-- I think it has something to do with https

	irc:add_command("google", "translate", function(irc, state, channel, msg)
		local from, to, msg = msg:match("^(.-) (.-) (.+)")
		assert(from and to and msg, "Insufficient arguments")

		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		local url = require("socket.url")

		local uri = "http://translate.google.com/translate_a/t?" ..
			"client=t" ..
			"&sl=" .. url.escape(from) ..
			"&tl=" .. url.escape(to) ..
			"&q=" .. url.escape(msg)

		local response, response_code = http.request(uri)
		assert(response_code == 200, "Error requesting page")

		while response:find(",,") do
			response = response:gsub(",,", ",null,")
			response = response:gsub("%[,", "%[null,")
		end

		local json = require("json")
		local obj, pos, err = json.decode(response)
		assert(not err, err)
		local sentences = {}
		for i, sentence in ipairs(obj[1]) do
			sentences[i] = sentence[1]:gsub(" (%p)", "%1")
		end
		return table.concat(sentences)
	end, true)
	irc:add_command("google", "slutcheck", function(irc, state, channel, msg)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		local url = require("socket.url")

		local safe, safe_code = http.request("http://www.google.com/search?safe=active&q=" .. url.escape(msg))

		if safe:match('The word <b>".+"</b> has been filtered from the search') then
			return ("Hmm, google is filtering '%s'.. 100%% slutty!"):format(msg)
		end

		local unsafe, unsafe_code = http.request("http://www.google.com/search?safe=off&q=" .. url.escape(msg))

		unsafe = tonumber((unsafe:match("About ([%d,]+) results") or "0"):gsub(",", ""), 10)
		safe   = tonumber((  safe:match("About ([%d,]+) results") or "0"):gsub(",", ""), 10)

		local value = unsafe ~= 0 and math.max(0, (unsafe - safe) / unsafe) or 0

		return ("%s is %.2f%% slutty."):format(msg, value * 100)
	end, true)
end
