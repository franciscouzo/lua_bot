local colors = {
	{255, 255, 255},
	{0,   0,   0  },
	{0,   0,   127},
	{42,  140, 42 },
	{255, 0,   0  },
	{127, 0,   0  },
	{156, 0,   156},
	{252, 127, 0  },
	{255, 255, 0  },
	{0,   252, 0  },
	{0,   147, 147},
	{0,   255, 255},
	{0,   0,   252},
	{255, 0,   255},
	{127, 127, 127},
	{210, 210, 210}
}
local function rgb2irc(rgb)
	local nearest   = math.huge
	local nearest_i = -1

	local r, g, b = rgb.red, rgb.green, rgb.blue

	--r = (r * (rgb.alpha / 255)) + (255 - rgb.alpha)
	--g = (g * (rgb.alpha / 255)) + (255 - rgb.alpha)
	--b = (b * (rgb.alpha / 255)) + (255 - rgb.alpha)

	for i, color in ipairs(colors) do
		local distance = math.abs(color[1] - r) * 0.3 +
		                 math.abs(color[2] - g) * 0.6 +
		                 math.abs(color[3] - b) * 0.1
		if distance < nearest then
			nearest = distance
			nearest_i = i - 1
		end
	end
	
	return nearest_i
end

return function(irc)
	local blocks = {" ", "▘", "▝", "▀", "▖", "▌", "▞", "▛", "▗", "▚", "▐", "▜", "▄", "▙", "▟", "█"}
	local max_width  = 100
	local max_height = 60

	irc:add_command("image", "image", function(irc, state, channel, url)
		local success, imlib2 = pcall(require, "imlib2")
		assert(success, "imlib2 is not installed")
		imlib2.set_anti_alias(true)

		local http = require("socket.http")
		http.USERAGENT = "Mozilla/5.0 (Windows NT 6.1; rv:30.0) Gecko/20100101 Firefox/30.0"

		local response, response_code = http.request(url)
		assert(response_code == 200, "Error requesting page")

		local tmpname = os.tmpname()
		local f = io.open(tmpname, "w")
		f:write(response)
		f:close()

		local image = imlib2.image.load(tmpname)

		local width, height = image:get_width(), image:get_height()

		local ratio = width / height

		if width > max_width or height > max_height then
			local new_width, new_height
			if ratio > max_width / max_height then
				-- wider
				new_width  = max_width
				new_height = height / (width / max_width)
			else
				-- taller
				new_width  = width / (height / max_height)
				new_height = max_height
			end
			image:crop_and_scale(0, 0, width - 1, height - 1, new_width, new_height)
			width, height = new_width, new_height
		end

		width  = width  - width  % 2 -- ignore last odd pixel
		height = height - height % 2

		local utils = require("irc.utils")
		for y = 0, height - 1, 2 do
			local line = ""
			for x = 0, width - 1, 2 do
				local pixels = {image:get_pixel(x, y    ), image:get_pixel(x + 1, y    ),
				                image:get_pixel(x, y + 1), image:get_pixel(x + 1, y + 1)}
				local irc_pixels = {rgb2irc(pixels[1]), rgb2irc(pixels[2]), rgb2irc(pixels[3]), rgb2irc(pixels[4])}

				local colors = {}
				for i, pixel in ipairs(irc_pixels) do
					colors[pixel] = (colors[pixel] or 0) + 1
				end
				local order_colors = {}
				for pixel, count in pairs(colors) do
					table.insert(order_colors, {pixel, count})
				end
				table.sort(order_colors, function(a, b) return a[2] < b[2] end)
				if #order_colors == 3 then
					-- second and third have one colors
					-- average those and set them
					local color1, color2 = order_colors[1][1], order_colors[2][1]
					local i1, i2 = -1, -1
					for i, pixel in ipairs(irc_pixels) do
						if pixel == color1 then
							i1 = i
						elseif pixel == color2 then
							i2 = i
						end
					end
					local avg = {red   = (pixels[i1].red   + pixels[i2].red  ) / 2,
					             green = (pixels[i1].green + pixels[i2].green) / 2,
					             blue  = (pixels[i1].blue  + pixels[i2].blue ) / 2}
					local new_color = rgb2irc(avg)
					irc_pixels[i1] = new_color
					irc_pixels[i2] = new_color
				elseif #order_colors == 4 then
					-- everything is one
					-- average 1 with 4 and 2 with 3
					local avg1_4 = {red   = (pixels[1].red   + pixels[4].red  ) / 2,
					                green = (pixels[1].green + pixels[4].green) / 2,
					                blue  = (pixels[1].blue  + pixels[4].blue ) / 2}
					local avg2_3 = {red   = (pixels[2].red   + pixels[3].red  ) / 2,
					                green = (pixels[2].green + pixels[3].green) / 2,
					                blue  = (pixels[2].blue  + pixels[3].blue ) / 2}
					local color1_4 = rgb2irc(avg1_4)
					local color2_3 = rgb2irc(avg2_3)
					irc_pixels = {color1_4, color2_3, color1_4, color2_3}
				end
				local foreground, background = irc_pixels[1], irc_pixels[2] or 0
				local i = 1
				for j = 0, 3 do
					if irc_pixels[j + 1] == foreground then
						i = i + (2 ^ j)
					end
				end
				local block = blocks[i]
				line = line .. ("\003%i,%i"):format(foreground, background) .. block
			end
			irc:privmsg(channel, line)
		end
		
		image:free()
		imlib2.flush_cache()
		os.remove(tmpname)
	end, true)
end
--[=[		else:
			for y in xrange(0, ysize, 2):
				line = ""
				for x in xrange(0, xsize, 2):
					pixels = [rgb2irc(imgdata[x, y]), rgb2irc(imgdata[x + 1, y]), rgb2irc(imgdata[x, y + 1]), rgb2irc(imgdata[x + 1, y + 1])]
					#pixels = [imgdata[x, y], imgdata[x + 1, y], imgdata[x, y + 1], imgdata[x + 1, y + 1]]
					unique = len(set(pixels))

					foreground, background = pixels[0], pixels[0]
					block = self.blocks[15]

					while len(set(pixels)) > 2:
						count = Counter(pixels).most_common()
						pixels[pixels.index(count[-1][0])] = count[0][0]

					if unique != 1:
						foreground = pixels[0]
						unique = tuple(set(pixels))
						background = unique[0] if unique[0] != foreground else unique[1]
						block = self.blocks[sum(1 << i for i, pixel in enumerate(pixels) if pixel == foreground)]
						
					line += "\x03%i,%i%s" % (foreground, background, block)

				irc.privmsg(state["channel"], line)
]=]
