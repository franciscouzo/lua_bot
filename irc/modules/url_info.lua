local html = require("irc.html")
local utils = require("irc.utils")

local default_handler = function(url, s)
	local title = s:match("<[Tt][Ii][Tt][Ll][Ee]>([^<]*)<")
	if title then
		title = title:gsub("%s+", " ")
		title = utils.strip(title)
		return "Title: " .. html.unescape(title)
	end
end

local handlers = {
	-- TODO, add more handlers
	["www.youtube.com"] = function(url, s)
		if url:match("^https?://www.youtube.com/watch%?v=.+") then
			local success, title = pcall(function()
				local title = s:match('<meta name="title" content="(.-)">')
				local views = s:match('<div class="watch%-view%-count" >(.-)</div>')
				local likes, dislikes = s:match('<span class="yt%-uix%-button%-content">([,%d%s]-)</span>.+<span class="yt%-uix%-button%-content">([,%d%s]-)</span>')

				title = html.unescape(title)

				views    = tonumber((views:match("([,%d%s]+)"):gsub(",", "")))
				likes    = tonumber((likes:gsub(",", "")))
				dislikes = tonumber((dislikes:gsub(",", "")))

				return ("%s | %i view%s, %i like%s, %i dislike%s"):format(
					title,
					views,    views    == 1 and "" or "s"
					likes,    likes    == 1 and "" or "s"
					dislikes, dislikes == 1 and "" or "s")
			end)
			if success then
				return title
			end
		end
	end
	--["twitter.com"] = function(url, s)
		--if url:match()
	--end
}

return function(irc)
	irc:add_hook("url_info", "on_non_cmd_privmsg", function(irc, state, channel, msg)
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"
		local https = require("ssl.https")
		local url = require("socket.url")
		for uri in msg:gmatch("https?://%S+") do
			local parsed = url.parse(uri)
			if parsed and parsed.scheme then -- idk if it can return nil
				local t = {}
				local request = ({http=http, https=https})[parsed.scheme].request
				local success, _, response_code = pcall(request, {
					url = uri,
					sink = utils.limited_sink(t, 1024 * 1024) -- 1MiB should be enough
				})
				local s = table.concat(t)
				local handler = handlers[parsed.host] or default_handler
				local url_info = handler(uri, s) or default_handler(url, s)
				if url_info then
					irc:privmsg(channel, url_info)
				end
			end
		end
	end)
end
