return function(irc)
	require("irc.modules.games.typo")(irc)
	require("irc.modules.games.honeycomb")(irc)
	require("irc.modules.games.gundraw")(irc)
	require("irc.modules.games.roulette")(irc)
	require("irc.modules.games.mnkpq")(irc)
    require("irc.modules.games.rockpaperscissors")(irc)
end