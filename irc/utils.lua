--local socket = require("socket")
--local url = require("socket.url")
local utils = {}

function utils:strip()
	return (self:match('^()%s*$') and '' or self:match('^%s*(.*%S)'))
end

function utils:lstrip()
	return (self:match("^%s*(.*)"))
end

function utils:rstrip()
	return (self:match("(.-)%s*$"))
end

function utils:escape_pattern()
    return (self:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end))
end

function utils.gisub(s, pat, ...)
	pat = pat:gsub('(%a)', function (v) return '[' .. v:upper() .. v:lower() .. ']' end)
	return s:gsub(pat, ...)
end

function utils.startswith(s, starts)
	return s:sub(1, #starts) == starts
end

function utils:split(separator, max, regex)
	assert(separator ~= '')
	assert(max == nil or max >= 1)

	local out = {}

	if self:len() == 0 then
		return out
	end
	local plain = not regex
	max = max or -1

	local field, start = 1, 1
	local first, last = self:find(separator, start, plain)
	while first and max ~= 0 do
		out[field] = self:sub(start, first - 1)
		field = field + 1
		start = last + 1
		first, last = self:find(separator, start, plain)
		max = max - 1
	end
	out[field] = self:sub(start)
	return out
end

function utils.capitalize(s)
	return (s:lower():gsub("^.", string.upper))
end

function utils.lower(s, min, max)
	local out = ""
	for c in s:gmatch(".") do
		local b = c:byte()
		if b >= min and b <= max then
			out = out .. string.char(b + 32)
		else
			out = out .. c
		end
	end
	return out
end

utils["ascii_lower"]          = function(s) return utils.lower(s, 65, 90) end
utils["rfc1459_lower"]        = function(s) return utils.lower(s, 65, 94) end
utils["strict-rfc1459_lower"] = function(s) return utils.lower(s, 65, 93) end

function utils.escape_list(list)
	return "\0\0" .. (table.concat(list, "\0\0"):gsub(" ", "\0 "))
end

function utils.unescape_list(list)
	if list == "\0\0" then
		return {}
	end
	local list = utils.split(list, "\0\0")
	table.remove(list, 1)
	for i, v in ipairs(list) do
		v = v:match("^ *(.*)") -- lstrip just spaces
		v = v:match("(.-) *$") -- rstrip just spaces
		if v:sub(-1) == "\0" then
			v = v .. " "
		end
		-- add one to ignore nul and another one to ignore the next char
		list[i] = v:gsub("%z ", " ")
	end
	return list
end

function utils.list_arguments(s)
	local arguments, list = unpack(utils.split(s, "\0\0", 1))
	if not (arguments and list) then
		return nil, "Invalid list"
	end
	if arguments:sub(-1) == " " then
		arguments = arguments:sub(1, -2)
	end
	return arguments, utils.unescape_list("\0\0" .. list)
end

local validate_element = function(element, type)
	if type == "string" then
		-- element = element
	elseif type == "int" or type == "+int" or type == "-int" then
		if not element:match("^[+-]?%d+$") then
			return nil, "Invalid int"
		end
		element = tonumber(element)
		if not element then
			return nil, "Wut... this should definitely be a number"
		end
		if math.abs(element) > (2 ^ 32) then -- max number representable with a double is 2^52
			return nil, "Int is too big"
		end
		if type == "+int" and element < 0 then
			return nil, "+int can't be negative"
		elseif type == "-int" and element >= 0 then
			return nil, "-int can't be positive"
		end
	elseif type == "float" or type == "+float" or type == "-float" then
		element = tonumber(element)
		if not element then
			return nil, "Invalid float"
		end
		if type == "+float" and element < 0 then
			return nil, "+float can't be negative"
		elseif type == "-float" and element >= 0 then
			return nil, "-float can't be positive"
		end
	else
		return nil, "Unknown type " .. type
	end
	return element
end

function utils.parse_arguments(s, ...)
	local args = {...}
	if #args == 0 then
		return {s}
	end

	local types = {
		["string"] = true,
		["int"]   = true, ["+int"]   = true, ["-int"]   = true,
		["float"] = true, ["+float"] = true, ["-float"] = true, 
	}

	local three_dots = args[#args]:match("(.+)%.%.%.")
	
	for i, arg in ipairs(args) do
		local three_dots_match = (arg):match("(.+)%.%.%.")
		if not types[arg] and (three_dots_match and not types[three_dots_match]) then
			return nil, "Invalid type"
		end
		if three_dots_match and i ~= #args then
			return nil, "... can only be at the end"
		end
	end

	local list = {}
	local sub = ""
	local len = #s
	local i = 0

	local open = false
	local escaped = false

	while i < len do
		i = i + 1
		local c = s:sub(i, i)
		if c == "\\" then
			i = i + 1
			sub = sub .. s:sub(i, i)
		elseif c == " " then
			if open then
				sub = sub .. " "
			elseif sub ~= "" then
				list[#list + 1] = sub
				sub = ""
			end
		elseif c == '"' then
			open = not open
			if not open then
				list[#list + 1] = sub
				sub = ""
			end
		else
			sub = sub .. c
		end
	end
	if open then
		return nil, "Unclosed quote"
	end
	if sub ~= "" then
		list[#list + 1] = sub
	end

	local out = {}
	-- ignore extra elements?
	--  if not args[#args]:match("(.+)%.%.%.") then
	--  	if #args <= #list then
	--  	if #args ~= #list
	--  		return nil, "Invalid number of arguments"
	--  	end
	--  end

	for i, type in ipairs(args) do
		local three_dots_match = type:match("(.+)%.%.%.")

		if not three_dots_match then
			local element = list[i]
			if not element then
				return nil, "Insufficient arguments"
			end
			local element, err = validate_element(element, type)
			if not element then
				return nil, err
			end
			out[#out + 1] = element
		else
			for j = i, #list do
				local element, err = validate_element(list[j], three_dots_match)
				if not element then
					return nil, err
				end
				out[j] = element
			end
		end
	end

	return out
end

function utils:e_split(delimiter, max, escape_char)
	escape_char = escape_char or "\\"
	assert(delimiter ~= "")
	assert(max == nil or max >= 1)
	assert(#escape_char == 1)
	
	local t = {}
	local sub = ""
	local escaped = false
	
	for c in self:gmatch(".") do
		if escaped then
			if c ~= delimiter and c ~= escape_char then
				sub = sub .. escape_char
			end
			sub = sub .. c
			escaped = false
		elseif c == escape_char then
			escaped = true
		elseif c == delimiter then
			t[#t + 1] = sub
			sub = ""
		else
			sub = sub .. c
		end
	end
	t[#t + 1] = sub
	return t
end

function utils.split_format(s, delimiter, callback, open, close, escape_char)
	open = open or "["
	close = close or "]"
	escape_char = escape_char or "\\"

	assert(type(delimiter) == "string")
	assert(type(open) == "string")
	assert(type(close) == "string")
	assert(type(escape_char) == "string")

	assert(#delimiter == 1)
	assert(#open == 1 and #close == 1)
	assert(#escape_char == 1)

	local t = {""}
	local sub = ""
	local escaped = false

	local depth = 0

	local escape = "[" .. utils.escape_pattern(delimiter .. open .. close .. escape_char) .. "]"

	for c in s:gmatch(".") do
		if escaped then
			local esc = c
			if not c:match(escape) then
				esc = escape_char .. esc
			end
			if depth > 0 then
				sub = sub .. esc
			else
				t[#t] = t[#t] .. esc
			end
			escaped = false
		elseif c == escape_char then
			escaped = true
		else
			if c == close then
				depth = depth - 1
				if depth < 0 then
					return nil, "Unbalanced expression"
				elseif depth == 0 then
					local callback_result = callback(sub)
					if callback_result == nil then
						return nil, "callback returned nil"
					end
					t[#t] = t[#t] .. callback_result
					sub = ""
				end
			end
			if depth > 0 then
				sub = sub .. c
			end
			if c == open then
				depth = depth + 1
			end

			if depth == 0 and c ~= close then
				if c == delimiter then
					t[#t + 1] = ""
				else
					t[#t] = t[#t] .. c
				end
			end
		end
	end
	if depth ~= 0 then
		return nil, "Unbalanced expression"
	end
	if escaped then
		t[#t] = t[#t] .. escape_char
	end
	--t[#t] = t[#t] .. sub
	return t
end

function utils.format(s, callback1, callback2, open, close, escape_char)
	callback2 = callback2 or (function(s) return s end)
	open = open or "{"
	close = close or "}"
	escape_char = escape_char or "\\"

	assert(#open == 1 and #close == 1)
	assert(#escape_char == 1)

	local result, middle, sub = "", "", ""
	local depth = 0
	local escape = false

	for c in s:gmatch(".") do
		if escape then
			if c ~= open and c ~= close and c ~= escape_char then
				middle = middle .. escape_char
			end
			middle = middle .. c
			escape = false
		else
			if c == close then
				depth = depth - 1
				if depth < 0 then
					return
				end
			end
			if depth > 0 then
				sub = sub .. c
			end
			if c == open then
				depth = depth + 1
			end

			if depth == 0 then
				if sub ~= "" then
					local callback1_result = callback1(sub)
					if callback1_result == nil then
						return
					end
					local callback2_result = callback2(middle)
					if callback2_result == nil then
						return
					end
					result, middle, sub =  result .. callback2_result .. callback1_result, "", ""
				else
					if c == close then
						return
					elseif c == escape_char then
						escape = true
					else
						middle = middle .. c
					end
				end
			end
		end
	end

	if sub ~= "" or depth ~= 0 then
		return
	end
	
	if middle ~= "" then
		result = result .. callback2(middle)
	end

	return result
end

function utils.tprint(tbl, indent, max)
	indent = indent or 0
	max = max or 5
	if max == 0 then return end
	for k, v in pairs(tbl) do
		local formatting = (" "):rep(indent * 4) .. tostring(k) .. ": "
		if type(v) == "table" then
			print(formatting)
			utils.tprint(v, indent + 1, max - 1)
		else
			print(formatting .. tostring(v))
		end
	end
end

function utils.deepcopy(orig)
	if type(orig) == "table" then
		local copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[utils.deepcopy(orig_key)] = utils.deepcopy(orig_value)
		end
		setmetatable(copy, utils.deepcopy(getmetatable(orig)))
		return copy
	else
		return orig
	end
end

function utils.listify(string_or_table)
	if type(string_or_table) ~= "table" then
		return {tostring(string_or_table)}
	end
	return string_or_table
end

function utils.shuffled(t)
	local n, order, result = #t, {}, {}
	
	for i = 1, n do
		order[i] = {math.random(), i}
	end
	table.sort(order, function(a,b)
		return a[1] < b[1]
	end)
	for i = 1, n do
		result[i] = t[order[i][2]]
	end
	return result
end

function utils.blocks(t, n)
	assert(n >= 1)
	local result = {}
	for i, v in ipairs(t) do
		if (i - 1) % n == 0 then
			result[#result + 1] = {}
		end
		table.insert(result[#result], v)
	end
	return result
end



local Pickle = {
	clone = function (t) local nt = {}; for i, v in pairs(t) do nt[i] = v end return nt end 
}

function Pickle:pickle_(root)
	if type(root) ~= "table" then 
		error("can only pickle tables, not " .. type(root) .. "s")
	end
	self._tableToRef = {}
	self._refToTable = {}
	local savecount = 0
	self:ref_(root)
	local s = ""

	while table.getn(self._refToTable) > savecount do
		savecount = savecount + 1
		local t = self._refToTable[savecount]
		s = s .. "{\n"
		for i, v in pairs(t) do
			s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
		end
		s = s.."},\n"
	end

	return string.format("{%s}", s)
end

function Pickle:value_(v)
	local vtype = type(v)
	if     vtype == "string" then return string.format("%q", v)
	elseif vtype == "number" then return v
	elseif vtype == "boolean" then return tostring(v) -- why the fuck didn't this library already support booleans
	elseif vtype == "table" then return "{" .. self:ref_(v) .. "}"
	else --error("pickle a "..type(v).." is not supported")
	end  
end

function Pickle:ref_(t)
	local ref = self._tableToRef[t]
	if not ref then 
		if t == self then error("can't pickle the pickle class") end
		table.insert(self._refToTable, t)
		ref = table.getn(self._refToTable)
		self._tableToRef[t] = ref
	end
	return ref
end

function utils.pickle(t)
	return Pickle:clone():pickle_(t)
end

function utils.unpickle(s)
	if type(s) ~= "string" then
		error("can't unpickle a " .. type(s) .. ", only strings")
	end
	local gentables = loadstring("return " .. s)
	local tables = gentables()
	
	for _, t in ipairs(tables) do
		local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
		for i, v in pairs(tcopy) do
			local ni, nv
			if type(i) == "table" then ni = tables[i[1]] else ni = i end
			if type(v) == "table" then nv = tables[v[1]] else nv = v end
			t[i] = nil
			t[ni] = nv
		end
	end
	return tables[1]
end


function utils.random_choice(list)
	return list[math.random(#list)]
end
function utils.random_choice_dict(t)
	local i = 0
	for k, v in pairs(t) do
		i = i + 1
	end

	if i == 0 then
		return
	end

	local r = math.random(i)
	local i = 0

	for k, v in pairs(t) do
		i = i + 1
		if i == r then
			return k
		end
	end
end

function utils.weighted_choice(t)
	local total = 0
	for k, v in pairs(t) do
		total = total + v
	end
	local r = math.random() * total
	local upto = 0
	for k, v in pairs(t) do
		if upto + v > r then
			return k
		end
		upto = upto + v
	end
end

function utils.limited_sink(t, limit)
	local l = 0
	return function(s)
		if not s then
			return
		end
		l = l + #s
		if l <= limit then
			table.insert(t, s)
			return 1
		else
			return nil, "limit reached"
		end
	end
end

return utils
