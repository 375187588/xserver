local skynet = require "skynet"
require "skynet.manager"
local httpc = require "http.httpc"
local dns = require "dns"
local ipay = require "ipay"

local CMD = {}

function CMD.create_ipay(msg)
    return ipay.request(msg)
end

skynet.start(function()
    httpc.dns() -- set dns server
    httpc.timeout = 100 -- set timeout 1 second

    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)

    skynet.register("orderclient")
end)


