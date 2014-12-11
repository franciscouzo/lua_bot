--http://androidphonenamegenerator.com/
local utils = require("irc.utils")
local manufacturers = {
	'HTC', 'Motorola', 'Samsung', 'LG', 'Sony Ericsson', 'Acer'
}
local names = {
	'Droid', 'Nexus', 'Galaxy', 'Motivate', 'Fascinate', 'Captivate',
	'Bionic', 'Infuse', 'Sensation', 'Atrix', 'MyTouch', 'Liquid', 'Dream',
	'Desire', 'Aria', 'Hero', 'Legend', 'Magic', 'Evo', 'Wildfire',
	'Thunderbolt', 'Mesmerize', 'Devour', 'Defy', 'Moment', 'Xperia',
	'Charge', 'Amaze', 'Rezound', 'Vigor'
}
local adjectives = {
	'Touch', 'Epic', 'Plus', 'Slide', 'Incredible', 'Black', 'Neo',
	'Vibrant', 'Optimus', 'Vivid'
}
local suffixes = {
	{'4G','4G+'}, {'S'}, {'X','X2','XT'}, {'2','II'}, {'3D'}, {'One'},
	{'Plus'}, {'Prime'}, {'E'}, {'Pro'}, {'G1'}, {'G2'}, {'V'}, {'Z'}, {'Y'}
}
return function()
	local words = {
		utils.random_choice(manufacturers),
		utils.random_choice(names),
		utils.random_choice(adjectives),
	}

	local suffixes = {unpack(suffixes)}

	for i = 1, math.random(0, 3) do
		local suffix_group = table.remove(suffixes, math.random(#suffixes))
		table.insert(words, utils.random_choice(suffix_group))
	end
	return table.concat(words, " ")
end