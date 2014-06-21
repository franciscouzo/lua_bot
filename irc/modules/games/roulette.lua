return function(irc)
	local bullets = 6
	irc:add_command("roulette", "roulette", function(irc, state, channel, msg)
		channel = irc:lower(channel)
		local game = irc.linda:get("games.roulette." .. channel)
		if not game then
			game = {
				bullets = math.random(bullets)
			}
		end
		game.bullets = game.bullets - 1
		if game.bullets >= 1 then
			return "*tick*"
		else
			irc.linda:set("games.roulette." .. channel, nil)
			irc:send("KICK", channel, state.nick, "*BOOM*")
		end
	end, false)
end