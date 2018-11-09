local skynet = require "skynet"

local function main()
  --skynet.newservice("debug_console", 8000)
    skynet.newservice("xlog")
    skynet.call("xlog", "lua", "start")

    -- mongo
    local mongo = skynet.newservice("mongo")
    skynet.call(mongo, "lua", "start", {
        host="127.0.0.1",
        port=27017,
        db="xserver",
        --username="yun",
        --password="yun",
        --authmod="mongodb_cr"
    })

    -- redis
    local r = skynet.newservice("redis")
    skynet.call(r, "lua", "start", {
        host = "127.0.0.1",
        port = 6379,
        db = 0,
        auth = nil
    })

    -- mysql
--[[    skynet.newservice("mysql")
    skynet.call("mysql", "lua", "start",
       {
            host = "127.0.0.1",
            port = 3306,
            database = "gmop37",
            user = "gmop",
            password = "a123456"
       })
]]--
    -- player_mgr
    skynet.uniqueservice("player_mgr")

    -- room_mgr
    skynet.uniqueservice("room_mgr")

    skynet.newservice("httpclient")
    skynet.newservice("httpserver")
    skynet.newservice("base_web_server")

    skynet.newservice("order")

    skynet.newservice("orderclient")

    skynet.exit()
end

skynet.start(main)
