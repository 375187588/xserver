root = "./skynet/"
thread = 8
harbor = 0
logger = nil
logpath = "."
start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap
luaservice = root.."service/?.lua;"..root.."test/?.lua;"..root.."examples/?.lua"
lualoader = root .. "lualib/loader.lua"
lua_path = "./mjlib/?.lua;"..root.."lualib/?.lua;"..root.."lualib/?/init.lua"
lua_cpath = "./luaclib/?.so;".. root .. "luaclib/?.so"
-- preload = "./examples/preload.lua"	-- run preload.lua before every lua service run
snax = root.."examples/?.lua;"..root.."test/?.lua"
-- snax_interface_g = "snax_g"
cpath = root.."cservice/?.so"
-- daemon = "./skynet.pid"

--our path
luaservice = "./game/?.lua;./game/?/main.lua;"..luaservice
lua_path = "./lualib/?.lua;"..lua_path
lua_cpath = "./luaclib/?.so;"..lua_cpath

GAME_ID = 1
SERVER_ID = 1
LOBBY_HOST = "192.168.1.211:7702"
SERVER_HOST = "192.168.1.211:7711"

DEBUG_CONSOLE_PORT = 7710
GAME_WEB_PORT = 7711
GAME_ADDR = "192.168.1.211"
GAME_PORT = 7712

RECORD_HOST = "119.29.116.166:9100"
