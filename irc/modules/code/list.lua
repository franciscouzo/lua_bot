local utils = require("irc.utils")

return function(irc)
	irc:add_command("list", "list", function(irc, state, channel, ...)
		return utils.escape_list({...})
	end, false, "string...")
	local max_numbers = 50
	irc:add_command("list", "list.range", function(irc, state, channel, n1, n2, n3)
		if not n2 then
			n1, n2, n3 = (n1 < 0 and -1 or 1), n1, (n1 < 0 and -1 or 1)
		elseif not n3 then
			n3 = n2 >= n1 and 1 or -1
		end

		local expected_numbers = (n2 - n1) / n3
		assert(expected_numbers <= max_numbers + 10, "Max numbers for range is " .. max_numbers)

		local numbers = {}
		local n = n1
		local i = 0
		while not ((n2 >= n1 and n > n2) or
				(n1 >= n2 and n < n2)) or n2 == n do
			i = i + 1
			assert(i <= max_numbers, "Max numbers for range is " .. max_numbers)
			table.insert(numbers, n)
			n = n + n3
		end
		return utils.escape_list(numbers)
	end, false, "float", "float...")
	irc:add_command("list", "list.add", function(irc, state, channel, msg)
		local value, list = assert(utils.list_arguments(msg))
		table.insert(list, value)
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.insert", function(irc, state, channel, msg)
		local n_value, list = assert(utils.list_arguments(msg))
		local n, value = unpack(utils.split(n_value, " ", 1))
		assert(n and value, "Insufficient arguments")
		n = assert(tonumber(n), "Invalid number")
		table.insert(list, n, value)
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.length", function(irc, state, channel, msg)
		return tostring(#utils.unescape_list(msg))
	end, false)
	irc:add_command("list", "list.empty", function(irc, state, channel, msg)
		return tostring(#utils.unescape_list(msg) == 0)
	end, false)
	irc:add_command("list", "list.key", function(irc, state, channel, msg)
		local key, list = assert(utils.list_arguments(msg))
		key = assert(tonumber(key), "Invalid number")
		return list[key]
	end, false)
	irc:add_command("list", "list.find", function(irc, state, channel, msg)
		local find, list = assert(utils.list_arguments(msg))
		for k, v in ipairs(list) do
			if v == find then
				return tostring(k)
			end
		end
	end, false)
	irc:add_command("list", "list.remove", function(irc, state, channel, msg)
		--local key, list = utils.list_arguments(msg)
		local key, list = assert(utils.list_arguments(msg))
		key = assert(tonumber(key), "Invalid number")
		table.remove(list, key)
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.drop", function(irc, state, channel, msg)
		local n, list = assert(utils.list_arguments(msg))
		n = assert(tonumber(n), "Invalid number")
		list = {select(n + 1, unpack(list))}

		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.take", function(irc, state, channel, msg)
		local n, list = assert(utils.list_arguments(msg))
		n = assert(tonumber(n), "Invalid number")

		local out = {}
		for i = 1, math.min(n, #list) do
			out[i] = list[i]
		end

		return utils.escape_list(out)
	end, false)
	irc:add_command("list", "list.head", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		return list[1]
	end, false)
	irc:add_command("list", "list.last", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		return list[#list]
	end, false)
	irc:add_command("list", "list.tail", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		table.remove(list, 1)
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.init", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		table.remove(list)
		return utils.escape_list(list)
	end, false)

	irc:add_command("list", "list.map", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		for i, v in ipairs(list) do
			local result = assert(irc:run_command(state, channel, f .. " " .. v))
			list[i] = result
		end
		return utils.escape_list(list)
	end, true)
	irc:add_command("list", "list.filter", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		local out = {}
		for i, v in ipairs(list) do
			local result = assert(irc:run_command(state, channel, f .. " " .. v))
			local condition = result:lower()
			if condition ~= "false" and condition ~= "nil" then
				table.insert(out, v)
			end
		end

		return utils.escape_list(out)
	end, true)
	irc:add_command("list", "list.any", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		for i, v in ipairs(list) do
			local result = assert(irc:run_command(state, channel, f .. " " .. v))
			local condition = result:lower()
			if condition ~= "false" and condition ~= "nil" then
				return "true"
			end
		end
		return "false"
	end, true)
	irc:add_command("list", "list.all", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		for i, v in ipairs(list) do
			local result = assert(irc:run_command(state, channel, f .. " " .. v))
			local condition = result:lower()
			if condition == "false" or condition == "nil" then
				return "false"
			end
		end
		return "true"
	end, true)
--[[
	irc:add_command("list", "list.scanl1", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		assert(#list >= 2, "Insufficient arguments")

		local z = list[1]
		local out = {z}
		local i, l = 2, #list
		repeat
			z = assert(irc:run_command(state, channel, f .. " " .. z .. " " .. list[i]))
			out[#out + 1] = z
			i = i + 1
		until i > l

		return utils.escape_list(out)
	end, true)
	irc:add_command("list", "list.scanl", function(irc, state, channel, msg)
		local f_z, list = assert(utils.list_arguments(msg))
		local f, z = f_z:match("(.+) (.+)")
		assert(f and z, "Insufficient arguments")

		table.insert(list, 1, z)
		return irc:run_command(state, channel, "list.scanl1 " .. f .. " " .. utils.escape_list(list))
	end, true)
	irc:add_command("list", "list.scanr1", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		local l = #list
		for i = 1, math.floor(l / 2) do
			list[i], list[l - i + 1] = list[l - i + 1], list[i]
		end
		return irc:run_command(state, channel, "list.scanl1 " .. f .. " " .. utils.escape_list(list))
	end, true)
	irc:add_command("list", "list.scanr", function(irc, state, channel, msg)
		local f_z, list = assert(utils.list_arguments(msg))
		local f, z = f_z:match("(.+) (.+)")
		assert(f and z, "Insufficient arguments")
		table.insert(list, z)
		return irc:run_command(state, channel, "list.scanr1 " .. f .. " " .. utils.escape_list(list))
	end, true)
	irc:add_command("list", "list.foldl1", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		assert(#list >= 2, "Insufficient arguments")

		local z = list[1]
		local i, l = 2, #list
		repeat
			z = irc:run_command(state, channel, f .. " " .. z .. " " .. list[i])
			i = i + 1
		until i > l

		return z
	end, true)
	irc:add_command("list", "list.foldl", function(irc, state, channel, msg)
		local f_z, list = assert(utils.list_arguments(msg))
		local f, z = f_z:match("(.+) (.+)")
		assert(f and z, "Insufficient arguments")
		table.insert(list, 1, z)
		return irc:run_command(state, channel, "list.foldl1 " .. f .. " " .. utils.escape_list(list))
	end, true)
	irc:add_command("list", "list.foldr1", function(irc, state, channel, msg)
		local f, list = assert(utils.list_arguments(msg))
		local l = #list
		for i = 1, math.floor(l / 2) do
			list[i], list[l - i + 1] = list[l - i + 1], list[i]
		end
		return irc:run_command(state, channel, "list.foldl1 " .. f .. " " .. utils.escape_list(list))
	end, true)
	irc:add_command("list", "list.foldr", function(irc, state, channel, msg)
		local f_z, list = assert(utils.list_arguments(msg))
		local f, z = f_z:match("(.+) (.+)")
		assert(f and z, "Insufficient arguments")
		table.insert(list, 1, z)
		return irc:run_command(state, channel, "list.foldr1 " .. f .. " " .. utils.escape_list(list))
	end
]]
	-- order

	irc:add_command("list", "list.sort", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local numeric = true
		local numbers = {}
		for i, v in ipairs(list) do
			local n = tonumber(v)
			if n then
				numbers[i] = n
			else
				numeric = false
				break
			end
		end
		table.sort(numeric and numbers or list)
		return utils.escape_list(numeric and numbers or list)
	end, false)
	irc:add_command("list", "list.ordered", function(irc, state, channel, msg)
		return tostring(msg == irc:run_command(state, channel, "list.sort " .. msg))
	end, false)
	irc:add_command("list", "list.shuffle", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local n = #list
		for i = 1, n do
			j = math.random(n)
			list[i], list[j] = list[j], list[i]
		end
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.random_choice", function(irc, state, channel, msg)
		return utils.random_choice(utils.unescape_list(msg))
	end, false)
	irc:add_command("list", "list.weighted_choice", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		assert(#list % 2 == 0, "List length must be even")
		local t = {}
		for i = 1, #list, 2 do
			local n = assert(tonumber(list[i + 1]), "even elements must be numbers")
			t[list[i]] = (t[list[i]] or 0) + n
		end
		return utils.weighted_choice(t)
	end, false)
	irc:add_command("list", "list.unique", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local out, elements = {}, {}
		for _, v in ipairs(list) do
			if not elements[v] then
				out[#out + 1] = v
				elements[v] = true
			end
		end
		return utils.escape_list(out)
	end, false)
	irc:add_command("list", "list.reverse", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local l = #list
		for i = 1, math.floor(l / 2) do
			list[i], list[l - i + 1] = list[l - i + 1], list[i]
		end
		--[[local out = {}
		for i = #list, 1, -1 do
			table.insert(out, list[i])
		end]]
		return utils.escape_list(list)
	end, false)

	-- formatting

	irc:add_command("list", "list.format", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		for i, v in ipairs(list) do
			list[i] = tonumber(v) and v or ("%q"):format(v)
		end
		return utils.escape_list(list)
	end, false)
	irc:add_command("list", "list.join", function(irc, state, channel, msg)
		local concat, list = utils.list_arguments(msg)
		return table.concat(list, concat)
	end, false)
	irc:add_command("list", "list.intersperse", function(irc, state, channel, msg)
		local element, list = assert(utils.list_arguments(msg))

		local out = {}
		for i = 1, #list - 1 do
			table.insert(out, list[i])
			table.insert(out, element)
		end
		table.insert(out, list[#list])

		return utils.escape_list(out)
	end, false)

	-- math

	irc:add_command("list", "list.sum", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local n = 0
		for _, number in ipairs(list) do
			number = assert(tonumber(number), "Invalid number")
			n = n + number
		end
		return tostring(n)
	end, false)
	irc:add_command("list", "list.product", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		local n = 1
		for _, number in ipairs(list) do
			number = assert(tonumber(number), "Invalid number")
			n = n * number
		end
		return tostring(n)
	end, false)
	irc:add_command("list", "list.max", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		assert(#list >= 1, "Insufficient arguments")
		local max = -math.huge
		for _, number in ipairs(list) do
			number = assert(tonumber(number), "Invalid number")
			max = math.max(max, number)
		end
		return tostring(max)
	end, false)
	irc:add_command("list", "list.min", function(irc, state, channel, msg)
		local list = utils.unescape_list(msg)
		assert(#list >= 1, "Insufficient arguments")
		local min = math.huge
		for _, number in ipairs(list) do
			number = assert(tonumber(number), "Invalid number")
			min = math.min(min, number)
		end
		return tostring(min)
	end, false)
end