local insult_adjectives = {'shitty', 'bitchy', 'freaky', 'creepy', 'racist', 'ignorant', 'stupid', 'dumb', 'meaningless', 'unholy', 'ridiculous', 'fat', 'stinky', 'smelly', 'shit-stained', 'cum-guzzling', 'shit-eating', 'piss-drinking', 'cum-stained', 'jizz-guzzling', 'jizz-stained', 'hare-brained', 'disgusting', 'repulsive', 'putrid', 'crappy', 'unlikeable', 'villainous', 'uncultured', 'redneck', 'scruffy', 'dirty', 'annoying', 'unbearable', 'obese', 'slimy', 'greasy', 'childlike', 'nerdy', 'friendless', 'awkward', 'gangly', 'hated', 'filthy', 'hopeless', 'donkey-fucking', 'dog-fucking', 'mother-fucking', 'inbred', 'pimply', 'shit-fucking', 'worthless', 'fucking', 'bastardly', 'unloved', 'pathetic', 'talentless', 'crazy', 'dick-licking', 'ass-kissing', 'ass-eating', 'cranky', 'old', 'miserable', 'decrepit', 'little', 'conceited', 'uppity', 'arrogant', 'insane', 'sad', 'dog-faced', 'ugly', 'hideous'}
local insult_nouns = {'shithead', 'piece of shit', 'shit-eater', 'shit-fucker', 'pile of shit', 'heap of shit', 'piss-drinker', 'fucknut', 'fuckface', 'mother-fucker', 'fuck', 'dog-fucker', 'cat-fucker', 'rapist', 'racist', 'nazi', 'bastard', 'bitch', 'dick', 'dickhead', 'nutsack', 'dick-licker', 'shit-licker', 'lunatic', 'baby', 'cocksucker', 'imbecile', 'ignoramus', 'dumbass', 'asshole', 'ass-face', 'ass-kisser', 'ass-licker', 'asshole-licker', 'failure', 'bag of shit', 'sack of shit', 'jizz-rag', 'slut', 'pansy', 'wimp', 'pussy', 'wuss', 'trash', 'piece of garbage', 'scumbag', 'cum-bucket', 'trash-heap', 'coward', 'monster'}

-- http://kristianwindsor.com/insult/
local insult2_list = {
	{'mouse humping', 'lazy', 'stupid', 'mother', 'insecure', 'spastic', 'idiotic', 'disgusting', 'slimy', 'slutty', 'smelly', 'communist', 'dicknose', 'racist', 'drug loving', 'ugly', 'creepy', 'shitty', 'snot licking', 'kinky', 'brother fucking'},
	{'douche', 'ass', 'turd', 'shart', 'rectum', 'butt', 'cock', 'shit', 'crotch', 'bitch', 'prick', 'slut', 'fuck', 'fucking', 'dick'},
	{'pilot', 'canoe', 'captain', 'pirate', 'hammer', 'knob', 'box', 'jockey', 'nazi', 'jew', 'hillbilly', 'nigger', 'nigger', 'lawyer', 'waffle', 'potato', 'flower', 'goblin', 'dinosaur', 'infection', 'blossum', 'biscuit', 'clown', 'socket', 'monster', 'hound', 'dragon', 'bull', 'balloon', 'niglet', 'nigaboo', 'mcfaggot', 'cumjockey'}
}

return function(irc, state, channel, n)
	local words = {}
	if n then
		n = math.max(n, 1)
		n = math.min(n, 20)
		local adjectives = {unpack(insult_adjectives)} -- cheap man's copy
		for i = 1, n do
			words[#words + 1] = table.remove(adjectives, math.random(#adjectives))
		end
		words[#words + 1] = insult_nouns[math.random(#insult_nouns)]
	else
		for _, insults in ipairs(insult2_list) do
			words[#words + 1] = insults[math.random(#insults)]
		end
	end
	return table.concat(words, " ")
end