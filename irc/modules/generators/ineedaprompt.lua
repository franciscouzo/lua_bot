-- http://www.ineedaprompt.com

local words = {
	adjective = {
		"acrobatic",
		"aggressive",
		"agile",
		"alert",
		"all-American",
		"ambitious",
		"amusing",
		"annoying",
		"apologetic",
		"attractive",
		"average",
		"awkward",
		"big",
		"bloated",
		"blushing",
		"charming",
		"cheerful",
		"childish",
		"churlish",
		"classy",
		"club-footed",
		"cold",
		"confused",
		"corrupt",
		"cute",
		"deceitful",
		"demonic",
		"depressed",
		"dilapidated",
		"discreet",
		"disgruntled",
		"disgusting",
		"disheveled",
		"dramatic",
		"ecstatic",
		"educated",
		"elderly",
		"elegant",
		"emotional",
		"entertaining",
		"evil",
		"fashionable",
		"fat",
		"fearless",
		"feeble",
		"festive",
		"flatulent",
		"flawed",
		"foolish",
		"forgetful",
		"former",
		"fortunate",
		"friendly",
		"frightening",
		"gorgeous",
		"graceful",
		"happy",
		"hairy",
		"humble",
		"immense",
		"intelligent",
		"lazy",
		"likable",
		"little",
		"lonely",
		"messy",
		"obnoxious",
		"old",
		"outgoing",
		"pale",
		"poised",
		"posh",
		"possessive",
		"pushy",
		"ragged",
		"reliable",
		"remorseful",
		"scared",
		"scrawny",
		"secretive",
		"self-possessed",
		"self-righteous",
		"sensitive",
		"sentient",
		"sick",
		"silly",
		"simpleminded",
		"skeptical",
		"smelly",
		"tattooed",
		"tired",
		"troublesome",
		"ugly",
		"unkempt",
		"well-dressed",
		"wild",
		"winged"
	},
	adverb = {
		"absentmindedly",
		"adventurously",
		"anxiously",
		"arrogantly",
		"artistically",
		"awkwardly",
		"bashfully",
		"bitterly",
		"blindly",
		"bravely",
		"carefully",
		"carelessly",
		"cleverly",
		"daintily",
		"defiantly",
		"enthusiastically",
		"excitedly",
		"ferociously",
		"foolishly",
		"frantically",
		"gracefully",
		"greedily",
		"grumpily",
		"innocently",
		"inquisitively",
		"longingly",
		"loudly",
		"lovingly",
		"merrily",
		"mysteriously",
		"noisily",
		"obediently",
		"optimistically",
		"overconfidently",
		"politely",
		"quickly",
		"quietly",
		"repeatedly",
		"rudely",
		"sedately",
		"selfishly",
		"sheepishly",
		"slowly",
		"somberly",
		"stealthily",
		"successfully",
		"suspiciously",
		"thoughtfully",
		"unethically",
		"vainly",
		"violently",
		"willfully",
		"wisely",
		"worriedly",
		"zestfully",
		"zestily"
	},
	location = {
		"all day long",
		"all night long",
		"amid the Gladiators in the Colosseum",
		"just as the Prophecy foretold",
		"at Disney World",
		"at Snooki's book-signing",
		"at a 5-year-old girl's Taylor Swift-themed birthday party",
		"at a Beatles concert in 1964",
		"at dawn",
		"at home",
		"at night",
		"at sunset",
		"at the bottom of an abandoned salt mine",
		"before a live studio audience",
		"beneath the Eiffel Tower",
		"beneath the desert sky",
		"beneath the twinkling Milky Way",
		"during a flood",
		"during the Black Plague of 1347",
		"every Tuesday",
		"every couple of hours",
		"flying first class",
		"in Carnegie Hall",
		"in Gordon Ramsay's sweltering kitchen",
		"in Jennifer Lawrence's dressing room",
		"in Kim Jong-un's personal bathroom",
		"in Nelson Mandela's jail cell in 1983",
		"in Pizza Hut",
		"in San Francisco",
		"in a burning building",
		"in a dangerous neighborhood",
		"in a dead end alley",
		"in a disgusting public bathroom",
		"in a field of goats",
		"in a field of golden wheat",
		"in a galaxy far, far away",
		"in a glass house",
		"in a high school gymnasium",
		"in a quiet Alpine meadow",
		"in a remote region of Nigeria",
		"in a rotting tree house",
		"in a slimy cave",
		"in a smoke-filled bar",
		"in a swamp near New Orleans",
		"in an abandoned insane asylum",
		"in an all-you-can-eat buffet line",
		"in church on a Sunday morning",
		"in front of 7,000 armed soldiers",
		"in the Great Hall of Hogwarts",
		"in the McDonald's drive-thru",
		"in the Penthouse Suite of a Waldorf Astoria Hotel",
		"in the Eigth Circle of Hell",
		"in the ancient Roman Senate",
		"in the basement",
		"in the lost city of Ghadames",
		"in the middle of the Macy's Thanksgiving Day Parade",
		"in the morning",
		"inside a broken elevator",
		"next door",
		"off the coast of Malta",
		"on a boat",
		"on Air Force One",
		"on the summit of Mount Everest",
		"on a Russian highway with a military escort",
		"on a busy Monday",
		"on a crowded beach",
		"on a deserted island",
		"on an old life boat",
		"on stage in front of 10,000 screaming fans",
		"on the International Space Station",
		"on the Internet",
		"on the castle battlements",
		"on the Moon",
		"on the rolling sands of the Sahara Desert",
		"on the roof of the White House",
		"on the slopes of Mount Doom",
		"on the steps of the Roman Forum",
		"on the streets of Moscow",
		"on the tip of an iceberg",
		"on the treacherous slopes of K2",
		"one day before the wedding",
		"right behind you",
		"under the sea",
		"under the unsleeping Eye of Sauron",
		"under the bleak Martian sun",
		"while singing the alphabet",
		"while stuck in traffic"
	},
	noun = {
		"British Queen",
		"CEO",
		"chicken",
		"Elvis impersonator",
		"Ewok",
		"Greek demigod",
		"Indian chief",
		"Jedi Knight",
		"Loch Ness Monster",
		"Navy SEAL",
		"Presidential candidate",
		"Samurai",
		"Senator",
		"Spaniard",
		"Wookie",
		"aardvark",
		"actor",
		"alien",
		"ancient Egyptian",
		"android",
		"anteater",
		"archangel",
		"army ant",
		"astronaut",
		"baboon",
		"bacterium",
		"badger",
		"bank robber",
		"basketball player",
		"biologist",
		"bishop",
		"blue whale",
		"bus driver",
		"cactus",
		"cantaloupe",
		"carpenter",
		"carrot",
		"chameleon",
		"chef",
		"child",
		"coal miner",
		"cross-dresser",
		"Air Force cadet",
		"cockroach",
		"comedian",
		"computer programmer",
		"desk lamp",
		"dwarf",
		"elf",
		"farmer",
		"fireman",
		"gargoyle",
		"gerbil",
		"ghost",
		"gorilla",
		"grandma",
		"grandpa",
		"haggis",
		"hippie",
		"history professor",
		"hobbit",
		"hooligan",
		"janitor",
		"jellyfish",
		"kidney bean",
		"knight",
		"lemming",
		"lizard-monkey",
		"mailman",
		"master of disguise",
		"millionaire",
		"mime",
		"monk",
		"monster",
		"Mormon",
		"nerd",
		"ninja warrior",
		"nun",
		"octopus",
		"opera singer",
		"package of bacon",
		"penguin",
		"philosopher",
		"piano virtuoso",
		"pickpocket",
		"pigeon",
		"pizza delivery guy",
		"poker dealer",
		"policeman",
		"politician",
		"poltergeist",
		"priest",
		"princess",
		"proctologist",
		"professional football player",
		"rabbit",
		"robot",
		"sailor",
		"severed head",
		"sloth",
		"snowman",
		"sofa",
		"software engineer",
		"soldier",
		"Smurf",
		"spaceship captain",
		"spider",
		"Star Trek enthusiast",
		"storm-trooper",
		"superhero",
		"tabby cat",
		"tap-dancer",
		"teddy bear",
		"teenager",
		"tour guide",
		"trial lawyer",
		"trombone",
		"undercover cop",
		"ventriloquist",
		"virus",
		"waitress",
		"watermelon",
		"werewolf",
		"wizard",
		"wolf"
	},
	verb = {
		"accompanied on the xylophone by",
		"being held hostage by",
		"building an ark with",
		"burying",
		"carrying a large box for",
		"carving a marble bust of",
		"cat-sitting for",
		"chasing after",
		"contemplating the Theory of Relativity with",
		"copying calculus homework from",
		"crying over",
		"discovering a new world with",
		"doing a root canal operation on",
		"doing an impression of",
		"doing the Hokey-Pokey with",
		"drawing a caricature of",
		"drinking a whole bottle of hot sauce as a result of a bet with",
		"driven mad by",
		"driving a bulldozer over",
		"dueling",
		"eating",
		"folding laundry for",
		"frying some eggs for",
		"getting a haircut from",
		"getting tickled by",
		"going to Senior Prom with",
		"having a rap battle with",
		"hawking home-grown tomatoes to",
		"hiding from",
		"in an \"it's complicated\" relationship with",
		"in bed with",
		"investing large amounts of cash for",
		"jogging alongside",
		"lathering up",
		"laying siege to the castle of",
		"lecturing to",
		"losing a hotdog-eating contest to",
		"losing at Monopoly to",
		"making a documentary of",
		"making a sandwich for",
		"making a sculpture of",
		"microwaving",
		"mining Bitcoins with",
		"mud-wrestling",
		"ordering 10 pounds of General Tso's Chicken for",
		"performing an improvised song and dance with",
		"petting the dog of",
		"picking the pocket of",
		"playing \"doctor\" with",
		"playing a pick-up basketball game against",
		"playing chess with",
		"playing ping-pong against",
		"playing the cymbals with",
		"posting an indignant Facebook status update about",
		"practicing medicine on",
		"proposing to",
		"providing career counseling for",
		"reading 'Moby Dick' to",
		"roasting marshmallows over a campfire with",
		"rocking out on an air guitar with",
		"selling a used car to",
		"spending some quality bonding time with",
		"singing a love song to",
		"sneaking past",
		"stealing from",
		"stealing the identity of",
		"steam-rolling",
		"sweet-talking",
		"taking candid pictures of",
		"testifying in court against",
		"wrapping a Chanukah present for",
		"writing a biography of",
		"writing a poem about",
		"being taught to Tango by",
		"roasting chestnuts on an open fire with",
		"fetching coffee for",
		"having a laugh with",
		"telling a joke to",
		"making uncomfortable eye contact with",
		"out to lunch with",
		"being made miserable by",
		"trying to impress"
	}
}

local utils = require("irc.utils")

local controls = {"adjective", "adjective", "noun", "adverb", "verb", "adjective", "adjective", "noun", "location"}

return function(irc, state, channel, msg)
	local bit32 = require("bit32")

	local structure_array = {}
	local amount = {noun=0, adjective=0, verb=0, adverb=0, location=0}
	
	local sentence = ""
	local sentence_array = {}

	if tonumber(msg) then
		local n = tonumber(msg)
		assert(n >= 1 and n < 2^#controls, "numbet out of range")
		for i, control in ipairs(controls) do
			if bit32.band(n, 2^i) then
				table.insert(structure_array, control)
			end
		end
	elseif msg == "" then
		structure_array = {"noun", "verb", "adjective", "noun"}
	else
		for _, type in ipairs(utils.split(msg, ",")) do
			type = utils.strip(type)
			assert(words[type], "Unknown type: " .. type)
			table.insert(structure_array, type)
		end
	end
	for _, type in ipairs(structure_array) do
		local function inside(array, value)
			for _, v in ipairs(array) do
				if v == value then
					return true
				end
			end
			return false
		end
		local random_word
		repeat
			random_word = utils.random_choice(words[type])
		until not inside(sentence_array, random_word)
		
		table.insert(sentence_array, {type, random_word})
		amount[type] = amount[type] + 1
	end

	for i, type in ipairs(structure_array) do
		local word = sentence_array[i][2]
		if type == "adverb" and amount.verb == 0 then
			word = word:gsub("ly", "")
			if word:sub(-1) == "i" then
				word = word:sub(1, -2) .. "y"
			elseif word:sub(-2) == "al" then
				word = word:sub(1, -3)
			end
			word = utils.strip(word)
			sentence_array[i] = {"adjective", word}
		end
	end

	--[[table.sort(sentence_array, function(a, b)
		a, b = a[1], b[1]
		if amount.noun == 0 or (amount.verb == 0 and amount.noun == 1) then
			return (b == "adjective" or b == "adverb") and a ~= "adjective"
		elseif amount.verb > 0 and amount.noun == 1 then
			return (b == "adjective" and a ~= "adjective") or ((a == "verb" and a == "adverb") and b == "noun")
		end
		return false
	end)]]

	for i = 1, #sentence_array do
		local type, word = unpack(sentence_array[i])

		local prev_type     = (sentence_array[i - 1] or {})[1]
		local prev_two_type = (sentence_array[i - 2] or {})[1]
		local next_type     = (sentence_array[i + 1] or {})[1]
		
		if (type == "adjective" or type == "noun") and prev_type ~= "adjective" and amount.noun >= 1 then
			word = (word:lower():match("^[aeiou]") and " an " or " a ") .. word
		end
		if type == "adjective" and prev_type == "adjective" then
			if next_type ~= "adjective" and next_type ~= "adverb" and next_type ~= "verb" and prev_two_type == "adjective" then
				word = "and " .. word
			end
			word = ", " .. word
		end
		if type == "adverb" then
			if prev_type == "adjective" then
				word = (prev_two_type == "adjective" and "," or "") .. " and"
			end
			word = " " .. word
		end
		if type == "noun" then
			if next_type == "noun" or next_type == "adjective" then
				word = word .. " and"
			end
			if prev_type == "adjective" then
				word = " " .. word
			end
		end
		if type == "verb" then
			if amount.noun <= 1 then
				--asd
				local word_list = {"aboard", "about", "above", "across", "after", "against", "along", "alongside", "amid", "among", "anti", "around", "as", "at", "before", "behind", "below", "beneath", "beside", "besides", "between", "beyond", "but", "by", "concerning", "considering", "despite", "down", "during", "except", "excepting", "excluding", "following", "for", "from", "in", "inside", "into", "like", "minus", "near", "of", "off", "on", "onto", "opposite", "outside", "over", "past", "per", "plus", "regarding", "round", "save", "since", "than", "through", "to", "toward", "towards", "under", "underneath", "unlike", "until", "up", "upon", "versus", "via", "with", "within", "without"}
				local function replace_end(word, word_list, with)
					-- case insensitive
					word_l = word:lower()
					for _, match in ipairs(word_list) do
						if word_l:match(match .. "$") then
							return word:sub(1, -(#match + 1))
						end
					end
					return word
				end
				word = replace_end(word, word_list, "")
			end
			if amount.noun == 0 and prev_type == "adjective" then
				word = ", and " .. word
			else
				word = " " .. word
			end
		end
		if type == "location" then
			word = " " .. word
		end
		sentence = sentence .. word
	end

	sentence = utils.strip(sentence)
	sentence = sentence:gsub("^.", string.upper) .. "."
	return sentence
end