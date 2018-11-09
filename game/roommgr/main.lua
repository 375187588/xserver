local skynet = require "skynet"
require "skynet.manager"
local room_mgr = require "room_mgr"

local GAME_ADDR = skynet.getenv("GAME_ADDR")
local GAME_PORT = skynet.getenv("GAME_PORT")
local LOBBY_HOST = skynet.getenv("LOBBY_HOST")

local CMD = {}

function CMD.start()
    room_mgr:init()
end

function CMD.create_room(info)
    print("CMD.create_room")
    info.room.roomid = math.floor(info.room.roomid)
    local r = room_mgr:create_room(info)
    local msg = {
        roomid = info.room.roomid,
        addr = r:get_addr()
    }
    skynet.send("dog", "lua", "new_room", msg)
    return {
        msg="success",
        ip = GAME_ADDR,
        port = GAME_PORT,
        ticket = r.ticket
    }
end

function CMD.join_room(info)
    print("CMD.join_room")
    local r = room_mgr:join_room(info)
    return {
        msg="success",
        ip = GAME_ADDR,
        port = GAME_PORT,
        ticket = r.ticket
    }
end

function CMD.game_finish(info)
    skynet.call("httpclient", "lua", "post", LOBBY_HOST, "/game_finish",info)
end

function CMD.join_room_result(info)
    skynet.call("httpclient", "lua", "post", LOBBY_HOST, "/join_room_result", info)
end

function CMD.leave_room_result(info)
    skynet.call("httpclient", "lua", "post", LOBBY_HOST, "/leave_room_result",info)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, session, cmd, ...)
        local f = CMD[cmd]
        assert(f, "can't find dispatch handler cmd = "..cmd)

        if session > 0 then
            return skynet.ret(skynet.pack(f(...)))
        else
            f(...)
        end
    end)

    skynet.register("roommgr")
end)
