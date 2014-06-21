local hashes = {["md5"] = true, ["sha1"] = true, ["sha256"] = true, ["crc32"] = true}

local utils = require("irc.utils")

return function(irc)
	irc:add_command("hash", "hash", function(irc, state, channel, msg)
		local hash_func, msg = msg:match("^(.-) (.+)$")
		assert(hash_func and msg, "Insufficent arguments")
		assert(hashes[hash_func], "Invalid hashing function")

		local hash = require("irc.modules.hash.hash")
		local h = hash[hash_func]()
		h:process(msg)
		return h:finish()
	end, false)
	
	irc:add_command("hash", "hashes", function(irc, state, channel, msg)
		local hash_list = {}
		for hash in pairs(hashes) do
			table.insert(hash_list, hash)
		end
		return utils.escape_list(hash_list)
	end, false)
end