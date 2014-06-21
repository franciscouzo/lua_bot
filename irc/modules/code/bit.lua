return function(irc)
	require("bit32")
	for func_name, func in pairs(bit32) do
		local command = (func_name:sub(1, 1) == "b") and func_name:sub(2, -1) or func_name
		irc:add_command("bit", "bit." .. command, function(irc, state, channel, ...)
			local bit32 = require("bit32")
			return tostring(bit32[func_name](...))
		end, false, "+int...")
	end
end