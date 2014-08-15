local utils = require("irc.utils")

local operator_funcs = {
	add = function(n1, n2) return n1 + n2 end,
	sub = function(n1, n2) return n1 - n2 end,
	mul = function(n1, n2) return n1 * n2 end,
	div = function(n1, n2) return n1 / n2 end,
	mod = function(n1, n2) return n1 % n2 end,
	pow = function(n1, n2) return n1 ^ n2 end,
	eq  = function(n1, n2) return n1 == n2 end,
	lt  = function(n1, n2) return n1 < n2 end,
	le  = function(n1, n2) return n1 <= n2 end,
	gt  = function(n1, n2) return n1 > n2 end,
	ge  = function(n1, n2) return n1 >= n2 end,
}

local math_func_arguments = {
	"abs","ceil", "floor", "acos", "asin", "atan", "cos", "sin", "tan",
	"cosh", "sinh", "tanh", "deg", "rad", "exp", "log", "log10", "min", "max", "sqrt"
}

local function truthy(bool)
	bool = bool:lower()
	return bool ~= "false" and bool ~= "nil"
end

local logical_operators = {
	["and"] = function(arg1, arg2) return truthy(arg1) and truthy(arg2) end,
	["or"]  = function(arg1, arg2) return truthy(arg1) or  truthy(arg2) end,
	["not"] = function(arg1) return not truthy(arg1) end,
}
local logical_operator_arguments = {["and"] = 2, ["or"] = 2, ["not"] = 1}

return function(irc)
	for operator, f in pairs(operator_funcs) do
		irc:add_command("code", operator, function(irc, state, channel, n1, n2)
			return tostring(f(n1, n2))
		end, false, "float", "float")
	end

	for operator, f in pairs(logical_operators) do
		irc:add_command("code", operator, function(irc, state, channel, msg)
			local args = utils.split(msg, " ")
			assert(#args == logical_operator_arguments[operator], "Invalid number of arguments")
			return tostring(f(unpack(args)))
		end, false)
	end
	
	for func, func in ipairs(math_func_arguments) do
		irc:add_command("code", func, function(irc, state, channel, ...)
			return tostring(math[func](...))
		end, false, "float")
	end
	
	irc:add_command("code", "atan2", function(irc, state, channel, y, x)
		return tostring(math.atan2(y, x))
	end, false, "float", "float")
	irc:add_command("code", "ldexp", function(irc, state, channel, y, x)
		return tostring(math.atan2(y, x))
	end, false, "float", "float")
	
	irc:add_command("code", "random", function(irc, state, channel, n1, n2)
		return tostring(math.random(unpack({n1, n2})))
	end, false, "float...")

	-- general code

	irc:add_command("code", "args", function(irc, state, channel, s, ...)
		local args = {...}
		local s = s:gsub("([%%&])(%d+)", function(type, n)
			n = assert(tonumber(n), "Invalid number")
			assert(args[n], "Insufficient arguments")
			return type == "%" and args[n] or table.concat(args, " ", n)
		end)
		return s
	end, false, "string", "string...")
	irc:add_command("code", "args_run", function(irc, state, channel, s)
		return irc:run_command(state, channel, irc:run_command(state, channel, "args " .. s))
	end, true)
	irc:add_command("code", "set_var", function(irc, state, channel, msg)
		local k, v = msg:match("^(.-) (.+)$")
		assert(k and v, "Insufficient arguments")
		irc.linda:set("code.vars." .. k, v)
	end, false)
	irc:add_command("code", "var", function(irc, state, channel, msg)
		msg = utils.strip(msg)
		local var = irc.linda:get("code.vars." .. msg)
		assert(var, "Undefined variable " .. msg)
		return var
	end, false)
	irc:add_command("code", "del_var", function(irc, state, channel, msg)
		irc.linda:set("code.vars." .. msg, nil)
	end, false)
	irc:add_command("code", "format", function(irc, state, channel, msg)
		local format = assert(utils.format(msg, function(s)
			return assert(irc:run_command(state, channel, s))
		end))

		return format
	end, true)
	irc:add_command("code", "run", function(irc, state, channel, msg)
		return irc:run_command(state, channel, msg)
	end, true)
	irc:add_command("code", "frun", function(irc, state, channel, msg)
		local format = assert(utils.format(msg, function(s)
			return assert(irc:run_command(state, channel, s))
		end))

		return irc:run_command(state, channel, format)
	end, true)
	irc:add_command("code", "for", function(irc, state, channel, msg)
		local var_name, list_command, loop_command = msg:match("%s*($.-)%s+in%s+(.-)%s+do%s+(.+)%s+end%s*$")
		assert(var_name and list_command and loop_command, "Syntax error")

		local result = assert(irc:run_command(state, channel, list_command))

		local list = utils.unescape_list(result)
		var_name = utils.escape_pattern(var_name)

		for _, element in ipairs(list) do
			local command = loop_command:gsub(var_name, element)
			local result = assert(irc:run_command(state, channel, command))
			irc:privmsg(channel, result)
		end
	end, true)
	irc:add_command("code", "if", function(irc, state, channel, msg)
		local condition_command, if_true = msg:match("%s*(.-)%s+then%s+(.+)%s+end%s*$")
		assert(condition_command and if_true, "Syntax error")

		-- only false and nil are falsy
		local result = assert(irc:run_command(state, channel, condition_command))
		local condition = result:lower()
		if condition ~= "false" and condition ~= "nil" then
			return irc:run_command(state, channel, if_true)
		end
	end, true)
	irc:add_command("code", "if_else", function(irc, state, channel, msg)
		local condition_command, if_true, if_false = msg:match("%s*(.-)%s+then%s+(.+)%s+else%s+(.+)%s+end%s*$")
		assert(condition_command and if_true and if_false, "Syntax error")

		-- only false and nil are falsy
		local result = assert(irc:run_command(state, channel, condition_command))
		condition = result:lower()
		local func = (condition ~= "false" and condition ~= "nil") and if_true or if_false
		return irc:run_command(state, channel, func)
	end, true)
	local escape_chars = {['"'] = true, ["\\"] = true, ["|"] = true, ["["] = true, ["]"] = true}
	irc:add_command("code", "escape", function(irc, state, channel, msg)
		local out = ""
		for c in msg:gmatch(".") do
			out = out .. (escape_chars[c] and "\\" or "") .. c
		end
		return '"' .. out .. '"'
	end, false)

	-- misc

	irc:add_command("code", "nothing", function()
		return ""
	end, false)
	irc:add_command("code", "error", function(irc, state, channel, msg)
		error(msg)
	end, false)
	
	require("irc.modules.code.bit")(irc)
	require("irc.modules.code.string")(irc)
	require("irc.modules.code.list")(irc)
	require("irc.modules.code.math_notation")(irc)
	require("irc.modules.code.codepad")(irc)
end