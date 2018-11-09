local skynet = require "skynet"
local socket = require "socket"

skynet.start(function()
    local agent = {}
    for i= 1, 5 do
        agent[i] = skynet.newservice("httpagent_c")
    end

    local balance = 1
    local port = skynet.getenv("RECORD_CLIENT_LISTEN_PORT")
    local id = socket.listen("0.0.0.0", port)
    skynet.error("Listen web port "..port)
    socket.start(id , function(_id, addr)
        skynet.send(agent[balance], "lua", _id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)