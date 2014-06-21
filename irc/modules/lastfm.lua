local json = require("json")

local utils = require("irc.utils")

return function(irc)
	irc.linda:set("lastfm.users", {})
	local file = io.open("data/lastfm")
	if file then
		irc.linda:set("lastfm.users", utils.unpickle(file:read("*a")))
		file:close()
	end

	irc:add_hook("lastfm", "on_quit", function(irc)
		local file = io.open("data/lastfm", "w")
		if file then
			file:write(utils.pickle(irc.linda:get("lastfm.users")))
			file:close()
		end
	end)

	irc:add_command("lastfm", "set_lastfm_user", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		assert(msg ~= "", "Empty string")

		local users = irc.linda:get("lastfm.users")
		users[irc:lower(state.nick)] = msg
		irc.linda:set("lastfm.users", users)
	end, false)

	irc:add_command("lastfm", "nowplaying", function(irc, state, channel, msg)
		local api_key = irc:get_config("lastfm_api_key", channel)
		assert(api_key, "No api key set up")

		msg = utils.strip(msg)

		local users = irc.linda:get("lastfm.users")
		local nick = irc:lower(msg == "" and state.nick or msg)
		local user = assert(users[nick], msg == "" and "You can set up your username with the set_lastfm_user command" or "Invalid username")

		local http = require("socket.http")
		local url = require("socket.url")
		local response, response_code = http.request(
			"http://ws.audioscrobbler.com/2.0/" .. 
			"?method=user.getRecentTracks" ..
			"&format=json" ..
			"&user=" .. url.escape(user) ..
			"&api_key=" .. url.escape(api_key)
		)
		assert(response_code == 200, "Error requesting page")

		local obj, pos, err = json.decode(response)
		assert(not err, err)
		user = obj.recenttracks["@attr"].user

		local track = obj.recenttracks.track[1]
		assert(track, "No tracks found")

		local artist = track.artist["#text"]
		if track["@attr"] then
			return ("%s is now playing: %s - %s"):format(user, artist, track.name)
		else
			return ("Last song played by %s: %s - %s (%s)"):format(user, artist, track.name, track.date["#text"])
		end
	end, true)
	irc:add_command("lastfm", "topartists", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		local users = irc.linda:get("lastfm.users")
		local nick = irc:lower(msg == "" and state.nick or msg)
		local user = assert(users[nick], msg == "" and "You can set up your username with the set_lastfm_user command" or "Invalid username")
		local api_key = irc:get_config("lastfm_api_key", channel)
		assert(api_key, "No api key set up")

		local http = require("socket.http")
		local url = require("socket.url")
		local response, response_code = http.request(
			"http://ws.audioscrobbler.com/2.0/" .. 
			"?method=user.getTopArtists" ..
			"&format=json" ..
			"&user=" .. url.escape(user) ..
			"&api_key=" .. url.escape(api_key)
		)
		assert(response_code == 200, "Error requesting page")

		local obj, pos, err = json.decode(response)
		assert(not err, err)

		local user = obj.topartists["@attr"].user
		local artists = obj.topartists.artist
		local artists_list = {}
		for i = 1, math.min(10, #artists) do
			local artist = artists[i]
			artists_list[i] = artist.name
		end
		return ("Top artists for %s: %s"):format(user, table.concat(artists_list, ", "))
	end, true)
end