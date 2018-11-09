local skynet = require "skynet"

skynet.start(function()
    skynet.newservice("xlog")
    skynet.call("xlog", "lua", "start")

    skynet.newservice("chttplistener", skynet.getenv("C_WEB_PORT"))
    skynet.newservice("shttplistener", skynet.getenv("S_WEB_PORT"))

    skynet.newservice("server_list")
    skynet.call("server_list", "lua", "start")

    skynet.exit()
end)
