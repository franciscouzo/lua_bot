local function factorial(n)
	local x = 1
	for i = 2, n do
		x = x * i
		if x == math.huge then
			return math.huge
		end
	end
	return x
end

local operators = {
	{"pi", function() return math.pi end, 0},
	{"e",  function() return math.exp(1) end, 0},

	{"sin",   math.sin,   1}, {"asin",  math.asin,  1},
	{"sinh",  math.sinh,  1}, {"asinh", math.asinh, 1},
	{"cos",   math.cos,   1}, {"acos",  math.acos,  1},
	{"cosh",  math.cosh,  1}, {"acosh", math.asinh, 1},
	{"tan",   math.tan,   1}, {"atan",  math.atan,  1},
	{"tanh",  math.tanh,  1}, {"atanh", math.atanh, 1},
	
	{"ln",    math.log,   1}, {"log10", math.log10, 1},
	{"exp",   math.exp,   1},
	{"frexp", math.frexp, 1}, {"ldexp", math.ldexp, 1},
	{"fmod",  math.fmod,  1},
	{"floor", math.floor, 1}, {"ceil",  math.ceil,  1},
	{"abs",   math.abs,   1},
	{"sqrt",  math.sqrt,  1},

	{"deg",   math.deg,   1}, {"rad",   math.rad,   1},

	{"!",     factorial,  1},

	{"+",     function(n, m) return n + m end, 2},
	{"-",     function(n, m) return n - m end, 2},
	{"*",     function(n, m) return n * m end, 2},
	{"/",     function(n, m) return n / m end, 2},
	{"%",     function(n, m) return n % m end, 2},
	{"^",     function(n, m) return n ^ m end, 2},
	
	{"hypot", function(n, m) return math.sqrt(n^2 + m^2) end, 2},
	{"log",   function(n, m) return math.log(n) / math.log(m) end, 2}, -- lua5.1 compat
	{"min",   math.min,   2}, {"max", math.max, 2},
	{"atan2", math.atan2, 2}
}

for i, v in ipairs(operators) do
	operators[v[1]] = {v[2], v[3]}
end

local function parse_prefix(tokens)
	local token = table.remove(tokens, 1)
	if operators[token] then
		local func, needed_tokens = operators[token][1], operators[token][2]
		local args = {}
		for i = 1, needed_tokens do
			args[i] = parse_prefix(tokens)
		end
		return func(unpack(args))
	else
		return assert(tonumber(token), "Unknown operator: " .. token)
	end
end

local function parse_postfix(tokens)
	local stack = {}
	for i, token in ipairs(tokens) do
		if operators[token] then
			local func, needed_tokens = operators[token][1], operators[token][2]
			local args = {}
			for j = 1, needed_tokens do
				table.insert(args, table.remove(stack))
			end
			table.insert(stack, func(unpack(args)))
		else
			table.insert(stack, (assert(tonumber(token), "Unknown operator: " .. token)))
		end
	end
	return assert(stack[1], "No result")
end

local infix_operators = {
	{
		associativeness = true, -- right associativeness
		{"^", function(n, m) return n ^ m end}
	}, {
		{"*", function(n, m) return n * m end},
		{"/", function(n, m) return n / m end},
		{"%", function(n, m) return n % m end}
	}, {
		{"+", function(n, m) return n + m end},
		{"-", function(n, m) return n - m end}
	}
}

for _, precedence in ipairs(infix_operators) do
	for _, operator in ipairs(precedence) do
		infix_operators[operator[1]] = true
	end
end

local function parse_infix(s)
	s = s:gsub("%b()", function(inside_parens)
		return " " .. parse_infix(inside_parens:sub(2, -2)) .. " " end
	)
	local tokens = {}

	local numbers = 0
	local operators = 0

	local j = 1
	for token in s:gmatch("%S+") do
		local i = 1
		while i <= #token do
			if j % 2 == 1 then
				local number = token:match("^%-?%d+%.?%d*", i) or token:match("^%-?%.%d+", i)
				assert(number, "Unexpected operator: " .. token)
				i = i + #number
				table.insert(tokens, tonumber(number))
			else
				local operator = token:match("^[^%.%d]+", i)
				assert(infix_operators[operator], "Invalid operator: " .. token)
				i = i + #operator
				table.insert(tokens, operator)
			end
			j = j + 1
		end
	end
	if #tokens == 1 and type(tokens[1] == "number") then
		return tokens[1]
	end
	assert(#tokens % 2 == 1, "Last token can't be operator")

	for precedence, operators in ipairs(infix_operators) do
		if operators.associativeness then -- right associativeness
			local i, finish = #tokens - 1, 2
			while i >= finish do
				for _, operator in ipairs(operators) do
					if tokens[i] == operator[1] then -- we already checked it's valid
						local token1 = tokens[i - 1]
						local token2 = tokens[i + 1]
						table.remove(tokens, i + 1)
						table.remove(tokens, i    )
						tokens[i - 1] = operator[2](token1, token2)
					end
				end
				i = i - 2
			end
		else
			local i, finish = 2, #tokens - 1
			while i <= finish do
				for _, operator in ipairs(operators) do
					if tokens[i] == operator[1] then -- we already checked it's valid
						local token1 = tokens[i - 1]
						local token2 = tokens[i + 1]
						table.remove(tokens, i + 1)
						table.remove(tokens, i    )
						tokens[i - 1] = operator[2](token1, token2)
						i = i - 2
					end
				end
				i = i + 2
			end
		end
	end

	return tokens[1]
end

return function(irc)
	irc:add_command("code", "prefix", function(irc, state, channel, ...)
		return tostring(parse_prefix({...}))
	end, false, "string...")
	irc:add_command("code", "infix", function(irc, state, channel, s)
		return tostring(parse_infix(s))
	end, false)
	irc:add_command("code", "postfix", function(irc, state, channel, ...)
		return tostring(parse_postfix({...}))
	end, false, "string...")
end