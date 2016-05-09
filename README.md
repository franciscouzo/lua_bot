Requirements:

`lanes`

`luasocket`

`luafilesystem` (to collect files for the `dcc` module)

`bit32` (needed for the `dcc`, `generators.ineedaprompt`, `encode` and `code.bit` modules/commands (Should use the pure Lua bit module that's in modules.hash.bit if not available))

`utf8` (needed for the `misc`, `figlet`, `code.string` and `style` modules)

`luasec` (needed for the `misc.cryptocoin_price`, `misc.download` and `url_info` modules/commands, and to connect through TLS)

`xml` (needed for the `feeds` module)

`imlib2` (needed for the `image` module, you should never use this module unless you want people to hate you)

You can install them by using luarocks:

`sudo apt-get install luarocks`

(or whatever package manager your distro uses)

    luarocks install lanes
    luarocks install luasocket
    luarocks install luafilesystem
    luarocks install bit32
    luarocks install utf8
    luarocks install luasec
    luarocks install xml

You might want to install these globally by running luarocks as root, otherwise you can run this command to make local installed packages available to Lua:

    echo "eval \`luarocks path\`" >> ~/.bashrc
