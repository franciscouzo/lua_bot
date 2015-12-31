return function(irc)
	irc:add_command("generators", "8ball",                  require("irc.modules.generators.8ball"),                  false)
	irc:add_command("generators", "jargon",                 require("irc.modules.generators.jargon"),                 false)
	irc:add_command("generators", "excuse",                 require("irc.modules.generators.excuse"),                 false)
	irc:add_command("generators", "medium",                 require("irc.modules.generators.medium"),                 false)
	irc:add_command("generators", "newage",                 require("irc.modules.generators.newage"),                 false)
	irc:add_command("generators", "headline",               require("irc.modules.generators.headline"),               false)
	irc:add_command("generators", "clickbait",              require("irc.modules.generators.clickbait"),              false)
	irc:add_command("generators", "buzzfeed",               require("irc.modules.generators.buzzfeed"),               false)
	irc:add_command("generators", "ineedaprompt",           require("irc.modules.generators.ineedaprompt"),           false)
	irc:add_command("generators", "android_name_generator", require("irc.modules.generators.android_name_generator"), false)
    irc:add_command("generators", "trivialproof",           require("irc.modules.generators.trivialproof"),           false)
	irc:add_command("generators", "shakespeare",            require("irc.modules.generators.shakespeare"),            false)
	irc:add_command("generators", "insult",                 require("irc.modules.generators.insult"),                 false, "+int...")
	irc:add_command("generators", "bullshit",               require("irc.modules.generators.bullshit"),               false, "+int...")

	irc:add_command("generators", "commit",                 require("irc.modules.generators.commit"),                 true)
	irc:add_command("generators", "fml",                    require("irc.modules.generators.fml"),                    true)
	irc:add_command("generators", "hipteripsum",            require("irc.modules.generators.hipsteripsum"),           true)
end