return function(irc)
	irc:add_command("generators", "8ball",    require("irc.modules.generators.8ball"),    false)
	irc:add_command("generators", "jargon",   require("irc.modules.generators.jargon"),   false)
	irc:add_command("generators", "excuse",   require("irc.modules.generators.excuse"),   false)
	irc:add_command("generators", "medium",   require("irc.modules.generators.medium"),   false)
	irc:add_command("generators", "newage",   require("irc.modules.generators.newage"),   false)
	irc:add_command("generators", "headline",   require("irc.modules.generators.headline"), false)
	irc:add_command("generators", "insult",   require("irc.modules.generators.insult"),   false, "+int...")
	irc:add_command("generators", "bullshit", require("irc.modules.generators.bullshit"), false, "+int...")

	irc:add_command("generators", "commit",      require("irc.modules.generators.commit"),       true)
	irc:add_command("generators", "fml",         require("irc.modules.generators.fml"),          true)
	irc:add_command("generators", "hipteripsum", require("irc.modules.generators.hipsteripsum"), true)
end