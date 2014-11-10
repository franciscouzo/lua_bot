local html = require("irc.html")
local utils = require("irc.utils")

local default_handler = function(irc, state, channel, url, s)
	local title = s:match("<[Tt][Ii][Tt][Ll][Ee]>([^<]*)<")
	if title then
		title = title:gsub("%s+", " ")
		title = utils.strip(title)
		return html.unescape(title)
	end
end

local handlers = {
	-- TODO, add more handlers
	["www.youtube.com"] = function(irc, state, channel, url, s)
		if url:match("^https?://www.youtube.com/watch%?v=.+") then
			local success, title = pcall(function()
				local title = s:match('<meta name="title" content="(.-)">')
				local views_s = s:match('<div class="watch%-view%-count" >(.-)</div>')
				local likes_s, dislikes_s = s:match('<span class="yt%-uix%-button%-content">([,%d%s]-)</span>.+<span class="yt%-uix%-button%-content">([,%d%s]-)</span>')
				local author = s:match('"author": "(.-)"')
				local length = s:match('"length_seconds":%s*"(%d-)"')

				title      = html.unescape(utils.strip(title))
				views_s    = utils.strip(views_s:match("([,%d%s]+)"))
				likes_s    = utils.strip(likes_s)
				dislikes_s = utils.strip(dislikes_s)
				author     = utils.strip(author)
				length     = utils.strip(length)

				views    = tonumber((views_s:gsub(",", "")))
				likes    = tonumber((likes_s:gsub(",", "")))
				dislikes = tonumber((dislikes_s:gsub(",", "")))
				length   = irc:run_command(state, channel, "format_seconds " .. length) or (length .. " seconds")

				return ("%s | %s | %s | %s view%s, %s like%s, %s dislike%s"):format(
					title, author, length,
					views_s,    views    == 1 and "" or "s",
					likes_s,    likes    == 1 and "" or "s",
					dislikes_s, dislikes == 1 and "" or "s")
			end)
			print(title)
			if success then
				return title
			end
		end
	end,
	["hastebin.com"] = function()
		return "" -- empty string evaluates to true, but irc:privmsg ignores empty strings
	end
	--["twitter.com"] = function(url, s)
		--if url:match()
	--end
}

local function url_info(irc, state, channel, url)
	local http = require("socket.http")
	http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
	local https = require("ssl.https")
	local url_parse = require("socket.url").parse

	local parsed = url_parse(url)

	assert(parsed, "Invalid url")
	assert(parsed.scheme, "Invalid url")
	assert(parsed.host, "Invalid url")
	assert(parsed.scheme == "http" or parsed.scheme == "https", "Unsupported scheme")

	url = url:gsub("#.*", "") -- stupid socket.http, it sends the fragment

	local t = {}
	local request = ({http=http, https=https})[parsed.scheme].request
	pcall(request, {
		url = url,
		sink = utils.limited_sink(t, 1024 * 1024) -- 1MiB should be enough
	})
	local s = table.concat(t)
	local handler = handlers[parsed.host] or default_handler
	local url_info = handler(irc, state, channel, url, s) or default_handler(irc, state, channel, url, s)

	return url_info
end

return function(irc)
	irc:add_command("url_info", "url_info", function(irc, state, channel, url)
		local url_info = assert(url_info(irc, state, channel, url), "Title not found")
		return url_info
	end, true)

	irc:add_hook("url_info", "on_non_cmd_privmsg", function(irc, state, channel, msg)
		for url in msg:gmatch("https?://%S+") do
			irc:privmsg(channel, url_info(irc, state, channel, url))
		end
	end, true)
end
