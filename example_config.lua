local lfs = require("lfs")

local modules = {
	'logs', 'active', 'autorejoin', 'autoignore', 'ignore',
	'module_management', 'permissions', 'output_command', 'sed_replace',
	--[['url_info',]] 'unknown_command',

	'cleverbot', 'code', 'commands', 'ctcp', 'dcc', 'encode', 'factoids',
	'fake_message', 'feeds', 'figlet', 'games', 'generators', 'google', 'hash',
	'highlight', 'image', 'json', 'karma', 'lastfm', 'maze', 'misc',
	'multiuser', 'qrcode', 'seen', 'shorten', 'shutup', 'style', 'tell',
	'timer', --[['toribash',]] 'translation_party', 'utils', 'vote', 'welcome'
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
	--[[ssl = {
		protocol = "tlsv1_2",
		capath = "/etc/ssl/certs",
		verify = {"peer", "fail_if_no_peer_cert"},
		exit_on_error = false -- will jump to next server
	},]]
	--pass = ...,
	--sasl_pass = ...,
	--nickserv_pass = ...,
	--nickserv_pass_type = 1,
	nick = "lua_bot",
	prefixes = {".", "%s, ", "%s: "},
	error_reporting = {
		public_debug = true,
		admin_debug = true,
		unknown_command = false
	},
	
	timeout = 300,
	on_connect = {
		
	},
	channels = {
		["#channel"] = {
			admin_channel = true,
			autojoin = true,
			--key = "key",
			--blacklist = {},
			--whitelist = {}
		}
	},
	rejoin_on_reconnect = true,

	modules = modules,

	flood_control = {
		length = 5, -- 5 message every 12 seconds
		time = 12
	},
	log = true,

	--output_command = "rainbow",
	
	module_permissions = {
		active            = "v",
		ctcp              = {true, "v"}, -- {admin}
		figlet            = {true, "v"},
		highlight         = "v",
		ignore            = {true, "o"},
		image             = {true, "o"},
		maze              = {true, "v"},
		multiuser         = {true, "v"},
		qrcode            = {true, "v"},
		shutup            = "v",
		translation_party = {true, "o"},
		typo              = "v",
		utils             = {true, "o"},
		welcome           = {true, "o"} -- it can use arbitrary commands on join
	},
	
	command_permissions = {
		add_cmd = {true, "o"},
		del_cmd = {true, "o"},
		vote_start = "v",
		vote_end   = "v",
		["for"] = {true, "o"}
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
		pattern = "*!*@{host}",
		messages = 5,
		wait_time = 15,
		ignore_time = 60
	},
	shutup_time = 180,
	--page2images_key = "api key",
	--lastfm_api_key = "api key"
}
