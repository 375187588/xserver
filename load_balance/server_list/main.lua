local skynet = require "skynet"
require "skynet.manager"
local tcp_list = require "tcp_list"
local web_list = require "web_list"

local CMD = {}

function CMD.start()
    tcp_list:init()
    web_list:init()
end

function CMD.get()
    return list:get()
end

function CMD.web_proxy_heartbeat(msg)
    web_list:heartbeat(msg)
end

function CMD.get_web_proxy()
    return web_list:get()
end

function CMD.tcp_proxy_heartbeat(msg)
    return tcp_list:heartbeat(msg)
end

function CMD.get_tcp_proxy()
    return tcp_list:get()
end

local function dispatch(_, session, cmd, ...)
    local f = CMD[cmd]
    if not f then
        return
    end

    if session > 0 then
        return skynet.ret(skynet.pack(f(...)))
    else
        f(...)
    end
end

local function main()
    skynet.dispatch("lua", dispatch)

    skynet.register("server_list")
end

skynet.start(main)
