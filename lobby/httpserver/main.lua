local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

skynet.start(function()
    local agent = {}
    for i= 1, 5 do
        agent[i] = skynet.newservice("httpagent")
    end
    local balance = 1
    local port = skynet.getenv("LOBBY_WEB_PORT")
    skynet.send("xlog", "lua", "log", "Listen web port "..port)
    local id = socket.listen("0.0.0.0", port)
    socket.start(id , function(id, addr)
        skynet.send("xlog", "lua", "log",
            string.format(
                "%s connected, pass it to agent :%08x",
                addr,
                agent[balance]))
        skynet.send(agent[balance], "lua", id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)
