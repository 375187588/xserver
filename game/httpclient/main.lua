local skynet = require "skynet"
require "skynet.manager"
local httpc = require "http.httpc"
local cjson = require "cjson"

local function request(host, url, msg)
    local content = cjson.encode(msg)
    local header = {}
    local respheader = {}
    local status, body = httpc.request("post",
        host, url, respheader, header,content)
    if status ~= 200 then
        skynet.call("xlog", "lua", "log", "http请求失败")
        return {}
    end
    return cjson.decode(body)
end

local server_info = {
    game_id = tonumber(skynet.getenv("GAME_ID")),
    id = tonumber(skynet.getenv("SERVER_ID")),
    host = skynet.getenv("SERVER_HOST"),
    ip = skynet.getenv("GAME_ADDR"),
    port = skynet.getenv("GAME_PORT"),
    status = "start"
}

local LOBBY_HOST = skynet.getenv("LOBBY_HOST")
local function heartbeat()
    skynet.timeout(5*100, heartbeat)
    local ret = request(LOBBY_HOST, "/server_heartbeat", server_info)
    if server_info.status == "start" and ret.result then
        server_info.status = "normal"
    end

    -- 请求发送当前服务器上所有的房间
    if ret.result == "room_list" then
        skynet.send("room_mgr", "lua", "room_list")
    end
end

local CMD = {}

function CMD.post(host, url, msg)
    print(host, url, msg)
    return request(host, url, msg)
end

function CMD.close_service()
    server_info.status = "stop_newroom"
    request(LOBBY_HOST, "/server_stop_newroom", {id=server_info.id})
end

function CMD.notify_close()
    server_info.status = "close"
    request(LOBBY_HOST, "/server_close", {id=server_info.id})
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

    skynet.timeout(5*100, heartbeat)
    skynet.register("httpclient")
end)
