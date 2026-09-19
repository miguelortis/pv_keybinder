fx_version 'cerulean'
game 'gta5'

author 'PV Development'
description 'Persistent, framework-agnostic key bindings for FiveM'
version '1.0.1'

lua54 'yes'

-- Config must be loaded before client/main.lua.
shared_script 'config.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'
