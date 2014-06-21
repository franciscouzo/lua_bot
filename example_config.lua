local lfs = require("lfs")

local modules = {
	'logs', 'active', 'autorejoin', 'autoignore', 'module_management',
	'permissions', 'output_command', 'sed_replace', 'url_info',

	'cleverbot', 'code', 'color', 'commands', 'ctcp', 'dcc', 'encode',
	'fake_message', 'games', 'generators', 'google', 'hash', 'highlight',
	'image', 'karma', 'lastfm', 'misc', 'multiuser', 'seen', 'shorten',
	'shutup', 'tell', 'timer', 'translation_party', 'utils', 'vote', 'welcome'
}

local dcc_folder = "dcc_files/"

local dcc_files = {}
for file in lfs.dir(dcc_folder) do
	if file ~= "." and file ~= ".." then
		dcc_files[file] = true
	end
end

return {
	servers = {
		"127.0.0.1"
	},
	--ssl = true,
	--pass = ...,
	--sasl_pass = ...,
	--nickserv_pass = ...,
	nick = "lua_bot",
	prefixes = {".", "%s, ", "%s: "},
	error_reporting = {
		public_debug = true,
		admin_debug = true
	},
	
	timeout = 300,
	on_connect = {
		
	},
	channels = {
		["channel"] = {
			admin_channel = true,
			autojoin = true,
			--key = "key",
			--blacklist = {},
			--whitelist = {}
		}
	},
	rejoin_on_reconnect = true,

	modules = modules,
	-- add ordered list when logging is done
	-- because logging must be ran before ignore

	flood_control = {
		length = 5, -- 5 message every 12 seconds
		time = 12
	},
	log = true,

	--output_command = "rainbow",
	
	module_permissions = {
		["active"]    = "v",
		["ctcp"]      = {true, "v"}, -- {admin}
		["highlight"] = "v",
		["image"]     = {true, "o"},
		["multiuser"] = {true, "v"},
		["shutup"]    = "v",
		["translation_party"] = {true, "o"},
		["typo"]      = "v",
		["utils"]     = {true, "o"},
		["vote"]      = "v",
		["welcome"]   = {true, "o"} -- it can use arbitrary commands on join
	},
	
	command_permissions = {
		["add_cmd"] = {true, "o"},
		["del_cmd"] = {true, "o"},
	},
	
	--[[dcc = {
		ip = "your ip",
		folder = dcc_folder,
		timeout = 60,
		random_port = true,
		--port_start = 4990,
		--port_end = 5000,
		files = dcc_files
	},]]
	autorejoin_time = 60,
	remove_unactive_after = 3600, -- seconds
	autoignore = {
		messages = 5,
		wait_time = 15,
		ignore_time = 60
	},
	shutup_time = 180,
	--page2images_key = "api key",
	--lastfm_api_key = "api key"
}