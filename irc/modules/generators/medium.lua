local medium_words = {{'Why', 'How'}, {'Cooking Hotdogs', 'Learning by Doing', 'Making Tacos', 'Bootstrapping My Blog', 'Quitting the Internet', 'Watching Breaking Bad', 'Re-watching The Wire', 'Worrying About CSS Selector Performance', 'Going Freelance', 'Writing a Blog', 'Passwording my WiFi', 'Filing my Taxes', 'Wearing No Socks'}, {'Influenced', 'Revolutionised', 'Enhanced', 'Messed Up', 'Changed', 'Suffocated'}, {'My Life', 'My Weekly Shop', 'the Toilet Paper I Used', 'the Housing Market', 'the Global Economy', 'BitCoin', 'My Cat', 'Node.js Package Manager', 'My Opinion of Starbucks', 'My Shares of Apple', 'My Dribbble Portfolio'}}

return function()
	local words = {}
	for i, choices in ipairs(medium_words) do
		words[i] = choices[math.random(#choices)]
	end
	return table.concat(words, " ")
end