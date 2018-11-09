local skynet = require "skynet"
local socket = require "socket"
local string = string

local port = ...

skynet.start(function()
    local agent = {}
    for i= 1, 5 do
        agent[i] = skynet.newservice("shttpagent")
    end
    local balance = 1
    skynet.send("xlog", "lua", "log", "Listen web port "..port)
    local id = socket.listen("0.0.0.0", port)
    socket.start(id, function(_id, addr)
        skynet.send("xlog", "lua", "log", 
            string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", _id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)

    skynet.timeout(60*100, function() lognum() end)
end)
