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

GAME_ID = 2
SERVER_ID = 2
LOBBY_HOST = "121.46.2.131:7702"
SERVER_HOST = "121.46.2.131:7721"

DEBUG_CONSOLE_PORT = 7720
GAME_WEB_PORT = 7721
GAME_ADDR = "121.46.2.131"
GAME_PORT = 7722

RECORD_HOST = "121.46.2.131:9100"
