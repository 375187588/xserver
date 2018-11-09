local skynet = require "skynet"

local function main()
--    skynet.newservice("debug_console", 1800)

    -- 客户端http服务
    skynet.newservice("httpclient")

    -- 服务器http服务
    skynet.newservice("httpserver")

    -- 回放服务
    local recorder = skynet.newservice("recorder")
    skynet.call(recorder, "lua", "start", {
        port = 13,
        maxclient = 1000,
        nodelay = true,
    })

    skynet.exit()
end

skynet.start(main)
