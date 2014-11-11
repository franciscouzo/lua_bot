local qrcode = require("irc.modules.qrcode.qrencode").qrcode

return function(irc)
    irc:add_command("qrcode", "qrcode_image", function(irc, state, channel, msg)
		local matrix = select(2, assert(qrcode(msg)))
		local padding = 2

		for y = 1, #matrix + padding * 2, 2 do
			local line = {}
			for x = 1, #matrix + padding * 2 do
				local foreground = ((matrix[x - padding] or {})[y - padding + 1] or -1) >= 0 and 1 or 0
				local background = ((matrix[x - padding] or {})[y - padding]     or -1) >= 0 and 1 or 0

				table.insert(line, ("\003%i,%i▄"):format(foreground, background))
			end
			irc:privmsg(channel, table.concat(line))
		end
    end, false)
end