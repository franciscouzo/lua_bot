package.path = "./?/init.lua;".. package.path

local irc = require("irc")

local config_file = arg[1]
if config_file:sub(-4) == ".lua" then
	config_file = config_file:sub(1, -5)
end
local config = require(config_file)

irc:new(config):main_loop()
