return function(irc)
	irc:add_command("translation_party", "translation_party", function(irc, state, channel, msg)
		irc.linda:set("translation_party.running", true)
		local from, to = "en", "ja"
		local messages = {}
		for i = 1, 30 do
			msg = irc:run_command(state, channel, ("translate %s %s %s"):format(from, to, msg))
			if messages[msg] then
				irc:privmsg(channel, "Equilibrium found.")
				return
			end
			if not irc.linda:get("translation_party.running") then
				return
			end
			messages[msg] = true
			irc:privmsg(channel, msg)
			from, to = to, from
		end
	end, true)
	irc:add_command("translation_party", "translation_party_no_japanese", function(irc, state, channel, msg)
		irc.linda:set("translation_party.running", true)
		local from, to = "en", "ja"
		local messages = {}
		for i = 1, 60 do
			msg = irc:run_command(state, channel, ("translate %s %s %s"):format(from, to, msg))
			if messages[msg] then
				irc:privmsg(channel, "Equilibrium found.")
				return
			end
			if not irc.linda:get("translation_party.running") then
				return
			end
			messages[msg] = true
			if i % 2 == 0 then
				irc:privmsg(channel, msg)
			end
			from, to = to, from
		end
	end, true)
	irc:add_command("translation_party", "stop_translation_party", function(irc, state, channel, msg)
		irc.linda:set("translation_party.running", nil)
	end, false)
end