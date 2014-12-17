local lanes = require("lanes")
local utils = require("irc.utils")

local function update_feeds(irc)
	lanes.gen("*", function()
		local socket = require("socket")
		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		local xml = require("xml")

		while true do
			local feeds = irc.linda:get("feeds.feeds")
			for url, feed in pairs(feeds) do
				pcall(function()
					local response, response_code = http.request(url)
					assert(response_code == 200, "Page returned non-200 error code")
					local data = xml.load(response)

					local send = false
					local last_link
					for i = #data[1], 1, -1 do
						local entry = data[1][i]
						if entry.xml == "item" or entry.xml == "item" then
							local title = xml.find(entry, "title")
							title = title and title[1]

							local link = xml.find(entry, "link")
							link = link and link[1]

							if link then
								if send then
									local msg = (title and (title .. ": ") or "") .. link
									for channel in pairs(feed.channels) do
										irc:privmsg(channel, msg)
									end
								elseif link == feed.last_link then
									send = true
								end

								last_link = link
							end
						end
					end
					feed.last_link = last_link
					irc.linda:set("feeds.feeds", feeds)
				end)
			end
			socket.sleep(1800)
		end
	end)()
end

return function(irc)
	irc.linda:set("feeds.feeds", {})
	local file = io.open("data/feeds")
	if file then
		irc.linda:set("feeds.feeds", utils.unpickle(file:read("*a")))
		file:close()
	end

	-- copied from irc:hook_thread
	local _irc = irc:copy_for_lanes(irc)
	function _irc:send(...)
		self.linda:send("send", {...})
	end
	_irc.threaded = true
	update_feeds(_irc)

	local function save_feeds()
		os.rename("data/feeds", "data/feeds.backup")
		local file = assert(io.open("data/feeds", "w"))
		file:write(utils.pickle(irc.linda:get("feeds.feeds")))
		file:close()
	end

	irc:add_command("feeds", "add_feed", function(irc, state, channel, url)
		url = utils.strip(url)
		channel = irc:lower(channel)

		local feeds = irc.linda:get("feeds.feeds")
		feeds[url] = feeds[url] or {channels={}}

		feeds[url].channels[channel] = true

		irc.linda:set("feeds.feeds", feeds)
		save_feeds()
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)

	irc:add_command("feeds", "del_feed", function(irc, state, channel, url)
		url = utils.strip(url)
		channel = irc:lower(channel)

		local feeds = irc.linda:get("feeds.feeds")
		assert(feeds[url], "Unknown feed")
		assert(feeds[url].channels[channel], "Channel is not subscribed to this feed")

		feeds[url].channels[channel] = nil
		
		if not next(feeds[url].channels) then
			feeds[url] = nil
		end

		irc.linda:set("feeds.feeds", feeds)
		save_feeds()
		irc:notice(state.nick, "ok " .. state.nick)
	end, false)
	
	irc:add_command("feeds", "feeds_list", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local urls = {}
		for url, feed in pairs(irc.linda:get("feeds.feeds") or {}) do
			if feed.channels[channel] then
				table.insert(urls, url)
			end
		end
		return utils.escape_list(urls)
	end, false)
end