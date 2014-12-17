local utils = require("irc.utils")
local sqlite3 = require("lsqlite3")

return {
	threaded = false,
	func = function(irc)
		local db = assert(sqlite3.open("data/tell.sqlite"))
		db:exec[[CREATE TABLE IF NOT EXISTS tell(
			nick TEXT PRIMARY KEY,
			by TEXT,
			date INTEGER,
			message TEXT
		) WITHOUT ROWID;]]

		local function tell_message(irc, state, channel)
			local socket = require("socket")

			local nick = irc:lower(state.nick)
			local stmt = db:prepare("SELECT * FROM tell WHERE nick = ?")
			stmt:bind_values(nick)

			for row in stmt:nrows() do
				local ago = math.floor(socket.gettime() - row.date) -- truncate milliseconds
				local format_ago = irc:run_command(state, channel, "format_seconds " .. ago)
				ago = format_ago or (math.floor(ago) .. " second" .. (ago == 1 and "" or "s"))
				irc:notice(nick, ("%s said: \"%s\" %s ago"):format(row.by, row.message, ago))
			end

			if stmt:columns() ~= 0 then
				local stmt = db:prepare("DELETE FROM tell WHERE nick = ?")
				stmt:bind_values(nick)
				stmt:step()
			end
		end

		irc:add_hook("tell", "on_cmd_join", tell_message)
		irc:add_hook("tell", "on_cmd_privmsg", tell_message)

		irc:add_command("tell", "tell", function(irc, state, channel, msg)
			local nick, msg = msg:match("^(.-) (.+)$")
			assert(nick and msg, "Insufficient arguments")

			local socket = require("socket")

			nick = irc:lower(nick)

			local stmt = db:prepare("INSERT INTO tell (nick, by, date, message) VALUES(?, ?, ?, ?)")
			stmt:bind_values(nick, state.nick, socket.gettime(), msg)
			stmt:step()

			irc:notice(state.nick, "ok " .. state.nick)
		end, false)
	end
}
