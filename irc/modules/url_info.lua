local json = require("json")
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

local function youtube_info(irc, state, channel, yt_id)
	local success, title = pcall(function()
		local https = require("ssl.https")
		local response, response_code = https.request("https://gdata.youtube.com/feeds/api/videos/" .. yt_id .. "?alt=jsonc&v=2")
		assert(response_code == 200, "Error requesting page")
		local data, pos, err = json.decode(response)
		assert(not err, err)

		data = data.data
		local title = data.title
		local uploader = data.uploader
		local uploaded = data.uploaded:match("^%d+%-%d+%-%d+")
		
		local duration = irc:run_command(state, channel, "format_seconds " .. tonumber(data.duration))
		duration = duration or (math.floor(data.duration) .. " second" .. (data.duration == 1 and "" or "s"))

		local comments = tonumber(data.commentCount)
		local views = tonumber(data.viewCount)
		local likes = tonumber(data.likeCount)
		local dislikes = tonumber(data.ratingCount) - tonumber(data.likeCount)
		
		return ("%s | %s | %s | %s | %i comment%s, %i view%s, %i like%s, %i dislike%s"):format(
			title, uploader, uploaded, duration,
			comments, comments == 1 and "" or "s",
			views,    views    == 1 and "" or "s",
			likes,    likes    == 1 and "" or "s",
			dislikes, dislikes == 1 and "" or "s")
	end)

	if success then
		return title
	end
end

local handlers = {
	-- TODO, add more handlers
	["www.youtube.com"] = {function(irc, state, channel, url)
		local yt_id = url:match("^https?://www.youtube.com/watch%?v=([%w_-]+)")
		if yt_id then
			return youtube_info(irc, state, channel, yt_id)
		end
	end, true},
	["youtu.be"] = {function(irc, state, channel, url)
		local yt_id = url:match("^https?://youtu.be/([%w_-]+)")
		if yt_id then
			return youtube_info(irc, state, channel, yt_id)
		end
	end, true},
	["hastebin.com"] = {function()
		return "" -- empty string evaluates to true, but irc:privmsg ignores empty strings
	end, true}
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

	if (handlers[parsed.host] or {})[2] then
		local url_info = handlers[parsed.host][1](irc, state, channel, url)
		if url_info then
			return url_info
		end
	end

	local t = {}
	local request = ({http=http, https=https})[parsed.scheme].request
	pcall(request, {
		url = url,
		sink = utils.limited_sink(t, 1024 * 1024) -- 1MiB should be enough
	})
	local s = table.concat(t)
	local url_info

	if not (handlers[parsed.host] or {})[2] then
		url_info = handlers[parsed.host][1](irc, state, channel, url, s)
	end
	if not url_info then
		url_info = default_handler(irc, state, channel, url, s)
	end

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
