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

local function get_image(url)
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

	os.remove(tmpname)

	return image
end

local function thumbnail(image, max_width, max_height)
	local width, height = image:get_width(), image:get_height()
	if width > max_width or height > max_height then
		local ratio = width / height
		if ratio > max_width / max_height then
			image:crop_and_scale(0, 0, width - 1, height - 1, max_width, height / (width / max_width))
		else
			image:crop_and_scale(0, 0, width - 1, height - 1, width / (height / max_height), max_height)
		end
	end
end

return function(irc)
	irc:add_command("image", "image", function(irc, state, channel, url)
		local blocks = {" ", "▘", "▝", "▀", "▖", "▌", "▞", "▛", "▗", "▚", "▐", "▜", "▄", "▙", "▟", "█"}

		local image = get_image(url)
		thumbnail(image, 100, 60)

		width  = image:get_width()  - image:get_width()  % 2 -- ignore last odd pixel
		height = image:get_height() - image:get_height() % 2

		local utils = require("irc.utils")
		for y = 0, height - 1, 2 do
			local line = {}
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
				local i = (irc_pixels[1] == foreground and 1 or 0) +
				          (irc_pixels[2] == foreground and 2 or 0) +
				          (irc_pixels[3] == foreground and 4 or 0) +
				          (irc_pixels[4] == foreground and 4 or 0)
				local block = blocks[i + 1]
				table.insert(line, ("\003%i,%i"):format(foreground, background) .. block)
			end
			irc:privmsg(channel, table.concat(line))
		end
		
		image:free()
		--imlib2.flush_cache()
	end, true)

	irc:add_command("image", "image2", function(irc, state, channel, url)
		local image = get_image(url)
		thumbnail(image, 50, 60)

		width  = image:get_width() -- no horizontal subpixels, since characters are half as wide than as tall
		height = image:get_height() - image:get_height() % 2 -- ignore last odd pixel

		for y = 0, height - 1, 2 do
			local line = {}
			for x = 0, width - 1, 2 do
				local foreground = rgb2irc(image:get_pixel(x, y))
				local background = rgb2irc(image:get_pixel(x, y + 1))

				if foreground == background then
					table.insert(line, ("\003%i"):format(foreground) .. "█")
				else
					table.insert(line, ("\003%i,%i"):format(foreground, background) .. "▀")
				end
			end
			irc:privmsg(channel, table.concat(line))
		end
		
		image:free()
		--imlib2.flush_cache()
	end, true)
end
